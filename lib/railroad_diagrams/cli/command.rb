# frozen_string_literal: true

require_relative 'demo'
require_relative 'render'
require_relative 'themes'

module RailroadDiagrams
  module CLI
    class UsageError < StandardError; end

    class Command
      HELP = <<~HELP
        Usage: railroad_diagrams <command> [options]
          render INPUT...  Render .rb, .yml, .yaml, .json, or .ebnf input
          demo [NAME...]   Show bundled examples
          themes           List available themes
          version          Print version

        .rb input executes arbitrary Ruby code. Only render trusted files.
      HELP

      def run(argv)
        command = argv.shift
        case command
        when 'render' then Render.new.run(argv)
        when 'demo' then Demo.new.run(argv)
        when 'themes' then Themes.run
        when 'version', '-v', '--version'
          puts "railroad_diagrams #{RailroadDiagrams::VERSION}"
          0
        when '-h', '--help', nil
          puts HELP
          0
        else
          return legacy_demo(command, argv) if command.start_with?('-')

          raise UsageError, "unknown command: #{command}"
        end
      rescue UsageError, OptionParser::ParseError => e
        warn "railroad_diagrams: #{e.message}"
        2
      rescue ParseError, Errno::ENOENT, SyntaxError => e
        warn "railroad_diagrams: #{e.message}"
        1
      rescue RenderError => e
        warn "railroad_diagrams: #{e.message}"
        3
      end

      private

      def legacy_demo(command, argv)
        warn 'railroad_diagrams: subcommand-less demo syntax is deprecated; use `demo`'
        Demo.new.run([command, *argv])
      end
    end
  end
end
