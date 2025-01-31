# frozen_string_literal: true

module RailroadDiagrams
  class Skip < DiagramItem
    def initialize
      super('g')
      @width = 0
      @up = 0
      @down = 0
    end

    def to_s
      'Skip()'
    end

    def format(x, y, width)
      Path.new(x, y).right(width).add(self)
      self
    end

    def text_diagram
      line, = TextDiagram.get_parts(['line'])
      TextDiagram.new(0, 0, [line])
    end
  end
end
