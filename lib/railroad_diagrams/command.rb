# rbs_inline: enabled
# frozen_string_literal: true

require_relative 'cli/demo'

module RailroadDiagrams
  # Legacy entry point for the bundled demo.
  # @example
  #   RailroadDiagrams::Command.new.run(['--format=svg'])
  class Command
    def run(argv)
      CLI::Demo.new.run(argv)
    rescue OptionParser::ParseError => e
      warn "railroad_diagrams: #{e.message}"
      warn 'Usage: railroad_diagrams [options] [files]'
      2
    end
  end
end
