# frozen_string_literal: true

require 'json'

if ARGV.first == '--compare'
  baseline = JSON.parse(File.read(ARGV.fetch(1))).fetch('seconds')
  current = JSON.parse(File.read(ARGV.fetch(2))).fetch('seconds')

  baseline.each do |size, formats|
    formats.each do |name, seconds|
      measured = current.fetch(size).fetch(name)
      if measured.nil?
        puts "n=#{size} #{name}: measurement exceeded 10s"
        puts "::warning file=benchmark/render.rb::#{name} n=#{size} render time exceeded 10s"
        next
      end

      ratio = measured / seconds
      puts format('n=%4s %-4s baseline=%.3fs current=%.3fs (%.2fx)', size, name, seconds, measured, ratio)
      next unless ratio > 1.5

      puts "::warning file=benchmark/render.rb::#{name} n=#{size} render time is #{ratio.round(2)}x the baseline"
    end
  end
  exit
end

require 'railroad_diagrams'
require 'timeout'

def build_diagram(size)
  rd = RailroadDiagrams
  items = Array.new(size) do |index|
    rd::Choice.new(0, "t#{index}", rd::NonTerminal.new("n#{index}"), rd::Optional.new('o'))
  end
  rd::Diagram.new(rd::Stack.new(*items))
end

def measure(size, output)
  samples = 3.times.map do
    GC.start
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Timeout.timeout(10) { build_diagram(size).public_send(output) }
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  rescue Timeout::Error
    break
  end
  samples && samples.sort.fetch(1).round(6)
end

build_diagram(1).to_svg
build_diagram(1).to_text

seconds = [100, 200, 400, 800].each_with_object({}) do |size, results|
  results[size.to_s] = { 'svg' => measure(size, :to_svg), 'text' => measure(size, :to_text) }
end

if ARGV.first == '--json'
  puts JSON.pretty_generate('ruby' => RUBY_VERSION, 'platform' => RUBY_PLATFORM,
                            'samples' => 3, 'timeout_seconds' => 10, 'seconds' => seconds)
else
  seconds.each do |size, formats|
    svg = formats.fetch('svg')
    text = formats.fetch('text')
    puts format('n=%4s svg=%s text=%s', size, svg ? format('%.3fs', svg) : '>10s',
                text ? format('%.3fs', text) : '>10s')
  end
end
