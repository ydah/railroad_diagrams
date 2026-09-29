# frozen_string_literal: true

require 'json'
require 'open3'
require 'rexml/document'
require 'yaml'
require_relative 'export'

upstream_dir = ARGV.fetch(0) { abort 'usage: ruby script/parity/compare.rb PATH_TO_UPSTREAM' }
expected_ref = File.read(File.join(__dir__, 'UPSTREAM_REF')).strip
actual_ref, status = Open3.capture2('git', '-C', upstream_dir, 'rev-parse', 'HEAD')
abort "upstream ref mismatch: #{actual_ref.strip} != #{expected_ref}" unless status.success? && actual_ref.strip == expected_ref

stdout, stderr, status = Open3.capture3(
  'python3', File.join(__dir__, 'render_upstream.py'), upstream_dir,
  stdin_data: JSON.generate(ParityExport.examples)
)
abort stderr unless status.success?
upstream = JSON.parse(stdout)

def normalize_svg(svg)
  normalize = lambda do |element|
    attrs = element.attributes.map do |name, value|
      [name, value.gsub(/-?\d+(?:\.\d+)?/) { |number| format('%.2f', number.to_f) }]
    end.sort
    children = element.elements.map { |child| normalize.call(child) }
    text = element.texts.map(&:value).join
    text = nil if text.strip.empty?
    [element.name, attrs, text, children]
  end
  normalize.call(REXML::Document.new(svg).root)
end

allowlist_path = File.expand_path('../../spec/parity/allowlist.yml', __dir__)
allowed = YAML.safe_load(File.read(allowlist_path)).to_h { |row| [row.fetch('example'), row.fetch('reason')] }
failures = []
used = []
ParityExport.diagrams.each do |name, diagram|
  expected = upstream.fetch(name)
  upstream_error = expected['error']
  metrics = [diagram.width, diagram.up, diagram.height, diagram.down]
  metric_difference = !upstream_error && metrics.zip(expected.fetch('metrics')).any? { |a, b| (a - b).abs > 0.01 }
  ruby_svg = normalize_svg(diagram.to_svg) unless upstream_error
  python_svg = normalize_svg(expected.fetch('svg')) unless upstream_error
  mismatch = upstream_error || metric_difference || ruby_svg != python_svg
  next unless mismatch

  if allowed.key?(name)
    used << name
  else
    detail = if upstream_error
               upstream_error
             elsif metric_difference
               "metrics #{metrics.inspect} vs #{expected.fetch('metrics').inspect}"
             else
               ruby_svg.flatten.zip(python_svg.flatten).find { |a, b| a != b }.inspect
             end
    failures << "#{name}: #{detail}"
  end
end

stale = allowed.keys - used
abort "Unexpected parity differences:\n#{failures.join("\n")}" unless failures.empty?
abort "Stale parity allowances: #{stale.join(', ')}" unless stale.empty?
puts "Compared #{upstream.size} examples with upstream #{expected_ref}; #{used.size} explained differences."
