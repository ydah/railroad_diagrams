# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # The start marker of a diagram.
  # @example
  #   Start.new('simple')
  class Start < DiagramItem
    # @rbs type: String
    # @rbs label: String?
    # @rbs return: void
    def initialize(type = 'simple', label: nil, id: nil, cls: nil, attrs: {})
      super('g', id: id, cls: cls, data_attrs: attrs)
      label = label.to_s if label
      @width =
        if label
          [20, (Unicode::DisplayWidth.of(label) * CHAR_WIDTH) + 10].max
        else
          20
        end
      @up = 10
      @down = 10
      @type = type
      @label = label
    end

    # @rbs return: String
    def to_s
      "Start(#{@type}, label=#{@label})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs _width: Numeric
    # @rbs return: Start
    def format(x, y, _width)
      path = Path.new(x, y - 10)
      if @type == 'complex'
        path.down(20).m(0, -10).right(@width).add(self)
      else
        path.down(20).m(10, -20).down(20).m(-10, -10).right(@width).add(self)
      end
      if @label
        DiagramItem.new(
          'text',
          attrs: {
            'x' => x,
            'y' => y - 15,
            'style' => 'text-anchor:start'
          },
          text: @label
        ).add(self)
      end
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      cross, line, tee_right = TextDiagram.get_parts(%w[cross line tee_right])
      start =
        if @type == 'simple'
          tee_right + cross + line
        else
          tee_right + line
        end

      label_td = TextDiagram.new(0, 0, [])
      if @label
        label_td = TextDiagram.new(0, 0, [@label])
        start = TextDiagram.pad_r(start, [label_td.width, Unicode::DisplayWidth.of(start)].max, line)
      end
      start_td = TextDiagram.new(0, 0, [start])
      label_td.append_below(start_td, [], move_entry: true, move_exit: true)
    end

    def measure(context)
      width = @label ? [20, context.text_width(@label, :label) + 10].max : 20
      Metrics.new(width: width, up: 10, height: 0, down: 10, needs_space: false)
    end

    def render_svg(context, x, y, _width)
      width = context.metrics(self).width
      path = Svg::PathData.new(x, y - 10, arc_radius: context.options.arc_radius).v(20)
      if @type == 'complex'
        path.m(0, -10).h(width)
      else
        path.m(10, -20).v(20).m(-10, -10).h(width)
      end
      group = Svg::Element.new('g', @attrs.dup)
      group << Svg::Element.new('path', { 'd' => path }, self_closing: true)
      if @label
        text = Svg::Element.new('text', { 'x' => x, 'y' => y - 15, 'style' => 'text-anchor:start' })
        group << (text << Svg::TextNode.new(@label))
      end
      group
    end

    def render_text(context)
      cross, line, tee_right = context.parts.values_at('cross', 'line', 'tee_right')
      start = @type == 'simple' ? tee_right + cross + line : tee_right + line
      label = TextDiagram.new(0, 0, @label ? [@label] : [])
      start = TextDiagram.pad_r(start, [label.width, Unicode::DisplayWidth.of(start)].max, line) if @label
      label.append_below(TextDiagram.new(0, 0, [start]), [], move_entry: true, move_exit: true)
    end

    def child_nodes
      []
    end
  end
end
