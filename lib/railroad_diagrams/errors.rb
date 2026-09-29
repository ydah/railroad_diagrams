# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Error; end

  class InvalidArgument < ArgumentError
    include Error
  end

  class ParseError < StandardError
    include Error
    attr_reader :line, :column, :source_line

    def initialize(message, line: nil, column: nil, source_line: nil)
      super(message)
      @line, @column, @source_line = line, column, source_line
    end
  end

  class RenderError < StandardError
    include Error
  end
end
