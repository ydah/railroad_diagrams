# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Skip < DiagramItem
    # @rbs return: void
    def initialize(id: nil, cls: nil, attrs: {})
      super('g', id: id, cls: cls, data_attrs: attrs)
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

    def measure(_context)
      Metrics.new(width: 0, up: 0, height: 0, down: 0, needs_space: false)
    end

    def render_svg(context, x, y, width)
      data = Svg::PathData.new(x, y, arc_radius: context.options.arc_radius).h([0, width].max)
      Svg::Element.new('g') << Svg::Element.new('path', { 'd' => data }, self_closing: true)
    end

    def render_text(context)
      TextDiagram.new(0, 0, [context.parts.fetch('line')])
    end

    def child_nodes
      []
    end
  end
end
