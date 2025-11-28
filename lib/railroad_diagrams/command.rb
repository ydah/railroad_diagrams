# rbs_inline: enabled
# frozen_string_literal: true

require 'optparse'

module RailroadDiagrams
  class Command
    # @rbs return: void
    def initialize
      @format = 'svg'
    end

    # @rbs argv: Array[String]
    # @rbs return: void
    def run(argv)
      OptionParser.new do |opts|
        opts.banner = <<~BANNER
          This is a test runner for railroad_diagrams:
          Usage: railroad_diagrams [options] [files]
        BANNER

        opts.on('-f', '--format FORMAT', 'Output format (svg, ascii, unicode, standalone)') do |format|
          @format = format
        end
        opts.on('-h', '--help', 'Print this help') do
          puts opts
          exit
        end
        opts.on('-v', '--version', 'Print version') do
          puts "railroad_diagrams #{RailroadDiagrams::VERSION}"
          exit 0
        end
        opts.parse!(argv)
      end

      @test_list = argv

      puts <<~HTML
        <!doctype html>
        <html>
        <head>
          <title>Test</title>
      HTML

      case @format
      when 'ascii'
        TextDiagram.set_formatting(TextDiagram::PARTS_ASCII)
      when 'unicode'
        TextDiagram.set_formatting(TextDiagram::PARTS_UNICODE)
      when 'svg', 'standalone'
        TextDiagram.set_formatting(TextDiagram::PARTS_UNICODE)
        puts <<~CSS
          <style>
            #{Style.default_style}
            .blue text { fill: blue; }
          </style>
        CSS
      end

      puts '</head><body>'

      File.open('test.rb', 'r:utf-8') do |fh|
        eval(fh.read, binding, 'test.rb')
      end

      puts '</body></html>'
    end

    # @rbs name: String
    # @rbs diagram: Diagram
    # @rbs return: void
    def add(name, diagram)
      return unless @test_list.empty? || @test_list.include?(name)

      puts "\n<h1>#{RailroadDiagrams.escape_html(name)}</h1>"

      case @format
      when 'svg'
        diagram.write_svg($stdout.method(:write))
      when 'standalone'
        diagram.write_standalone($stdout.method(:write))
      when 'ascii', 'unicode'
        puts "\n<pre>"
        diagram.write_text($stdout.method(:write))
        puts "\n</pre>"
      end

      puts "\n"
    end
  end
end
