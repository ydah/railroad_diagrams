# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Skip < DiagramItem
    # @rbs return: void
    def initialize
      super('g')
      @width = 0
      @up = 0
      @down = 0
    end

    # @rbs return: String
    def to_s
      'Skip()'
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Skip
    def format(x, y, width)
      Path.new(x, y).right(width).add(self)
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      line, = TextDiagram.get_parts(['line'])
      TextDiagram.new(0, 0, [line])
    end
  end
end
