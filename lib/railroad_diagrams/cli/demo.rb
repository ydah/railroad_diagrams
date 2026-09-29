# frozen_string_literal: true

require 'optparse'

module RailroadDiagrams
  module CLI
    class Demo
      FORMATS = %w[svg ascii unicode standalone].freeze
      DEMO_FILE = File.expand_path('../../../examples/demo.rb', __dir__)

      def initialize
        @format = 'svg'
      end

      def run(argv)
        parser = OptionParser.new do |opts|
          opts.banner = <<~BANNER
            This is a test runner for railroad_diagrams:
            Usage: railroad_diagrams [options] [files]
          BANNER

          opts.on('-f', '--format FORMAT', FORMATS, "Output format (#{FORMATS.join(', ')})") { |format| @format = format }
          opts.on('--max-width WIDTH', Integer, 'Wrap SVG diagrams to this width') do |width|
            raise OptionParser::InvalidArgument, 'max-width must be positive' unless width.positive?

            @max_width = width
          end
          opts.on('-h', '--help', 'Print this help') do
            puts opts
            return 0
          end
          opts.on('-v', '--version', 'Print version') do
            puts "railroad_diagrams #{RailroadDiagrams::VERSION}"
            return 0
          end
        end
        parser.parse!(argv)
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
        File.open(DEMO_FILE, 'r:utf-8') do |fh|
          eval(fh.read, binding, DEMO_FILE) # rubocop:disable Security/Eval
        end
        puts '</body></html>'
        0
      end

      def add(name, diagram)
        return unless @test_list.empty? || @test_list.include?(name)

        puts "\n<h1>#{RailroadDiagrams.escape_html(name)}</h1>"

        case @format
        when 'svg'
          @max_width ? $stdout.write(diagram.to_svg(max_width: @max_width)) : diagram.write_svg($stdout.method(:write))
        when 'standalone'
          @max_width ? $stdout.write(diagram.to_standalone_svg(max_width: @max_width)) : diagram.write_standalone($stdout.method(:write))
        when 'ascii', 'unicode'
          puts "\n<pre>"
          diagram.write_text($stdout.method(:write))
          puts "\n</pre>"
        end

        puts "\n"
      end
    end
  end
end
