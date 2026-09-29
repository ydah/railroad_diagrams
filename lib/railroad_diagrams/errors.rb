# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # Shared marker for errors raised by the library.
  module Error; end

  # Raised for invalid options or node constructor arguments.
  # @example
  #   raise InvalidArgument, 'choice needs at least one item'
  class InvalidArgument < ArgumentError
    include Error
  end

  # Raised for invalid grammar or serialized input.
  # @example
  #   raise ParseError.new('bad input', line: 1, column: 2)
  class ParseError < StandardError
    include Error
    attr_reader :line, :column, :source_line

    def initialize(message, line: nil, column: nil, source_line: nil)
      super(message)
      @line, @column, @source_line = line, column, source_line
    end
  end

  # Raised when a diagram cannot be rendered.
  # @example
  #   raise RenderError, 'unsupported format'
  class RenderError < StandardError
    include Error
  end
end
