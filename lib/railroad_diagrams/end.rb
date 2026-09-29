# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class End < DiagramItem
    # @rbs type: String
    # @rbs label: String?
    # @rbs return: void
    def initialize(type = 'simple', label: nil)
      label = label.to_s if label
      super(label ? 'g' : 'path')
      @width = label ? [20, (Unicode::DisplayWidth.of(label) * CHAR_WIDTH) + 10].max : 20
      @up = 10
      @down = 10
      @type = type
      @label = label
    end

    # @rbs return: String
    def to_s
      return "End(type=#{@type})" unless @label

      "End(type=#{@type}, label=#{@label})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs _width: Numeric
    # @rbs return: End
    def format(x, y, _width)
      path = legacy_path(x, y, @width)
      if @label
        DiagramItem.new('path', attrs: { 'd' => path }).add(self)
        DiagramItem.new('text', attrs: { 'x' => x + @width, 'y' => y - 15, 'style' => 'text-anchor:end' },
                                text: @label).add(self)
      else
        @attrs['d'] = path
      end
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      cross, line, tee_left = TextDiagram.get_parts(%w[cross line tee_left])
      text_with_label(cross, line, tee_left)
    end

    def measure(context)
      width = @label ? [20, context.text_width(@label, :label) + 10].max : 20
      Metrics.new(width: width, up: 10, height: 0, down: 10, needs_space: false)
    end

    def render_svg(context, x, y, _width)
      width = context.metrics(self).width
      data = if context.options.precision || context.options.optimize_paths
               path = Svg::PathData.new(x, y).h(width)
               @type == 'simple' ? path.m(-10, -10).v(20).m(10, -20).v(20) : path.m(0, -10).v(20)
             else
               legacy_path(x, y, width)
             end
      path = Svg::Element.new('path', { 'd' => data })
      return path unless @label

      text = Svg::Element.new('text', { 'x' => x + width, 'y' => y - 15, 'style' => 'text-anchor:end' })
      Svg::Element.new('g', @attrs.dup) << path << (text << Svg::TextNode.new(@label))
    end

    def render_text(context)
      cross, line, tee_left = context.parts.values_at('cross', 'line', 'tee_left')
      text_with_label(cross, line, tee_left)
    end

    def child_nodes
      []
    end

    private

    def legacy_path(x, y, width)
      @type == 'simple' ? "M #{x} #{y} h #{width} m -10 -10 v 20 m 10 -20 v 20" : "M #{x} #{y} h #{width} m 0 -10 v 20"
    end

    def text_with_label(cross, line, tee_left)
      end_node = @type == 'simple' ? line + cross + tee_left : line + tee_left
      return TextDiagram.new(0, 0, [end_node]) unless @label

      width = TextDiagram.max_width(@label, end_node)
      label = TextDiagram.pad_l(@label, width, ' ')
      TextDiagram.new(1, 1, [label, TextDiagram.pad_l(end_node, width, line)])
    end
  end
end
