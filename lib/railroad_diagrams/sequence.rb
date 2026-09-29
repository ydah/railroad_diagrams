# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Sequence < DiagramMultiContainer
    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(*items)
      super('g', items)
      @needs_space = true
      calculate_dimensions
    end

    # @rbs return: String
    def to_s
      items = @items.map(&:to_s).join(', ')
      "Sequence(#{items})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Sequence
    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      add_edge_paths(x, y, left_gap, right_gap)
      format_items(x + left_gap, y)
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      separator, = TextDiagram.get_parts(['separator'])
      @items.reduce(TextDiagram.new(0, 0, [''])) do |diagram_td, item|
        item_td = item.text_diagram
        item_td = item_td.expand(1, 1, 0, 0) if item.needs_space
        diagram_td.append_right(item_td, separator)
      end
    end

    # @rbs context: Context
    # @rbs return: Metrics
    def measure(context)
      up = 0
      down = 0
      height = 0
      width = 0
      metrics = @items.map { |item| context.metrics(item) }

      metrics.each do |child|
        width += child.width + (child.needs_space ? 20 : 0)
        up = [up, child.up - height].max
        height += child.height
        down = [down - child.height, child.down].max
      end

      width -= 10 if metrics.first&.needs_space
      width -= 10 if metrics.last&.needs_space
      Metrics.new(width: width, up: up, height: height, down: down, needs_space: true)
    end

    # @rbs context: Context
    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Svg::Element
    def render_svg(context, x, y, width)
      metrics = context.metrics(self)
      left_gap, right_gap = context.gaps(width, metrics.width)
      group = Svg::Element.new('g', @attrs.dup)
      group << svg_path(x, y, left_gap)
      group << svg_path(x + left_gap + metrics.width, y + metrics.height, right_gap)
      x += left_gap

      @items.each_with_index do |item, index|
        child = context.metrics(item)
        if child.needs_space && index.positive?
          group << svg_path(x, y, 10)
          x += 10
        end
        group << item.render_svg(context, x, y, child.width)
        x += child.width
        y += child.height
        if child.needs_space && index < @items.length - 1
          group << svg_path(x, y, 10)
          x += 10
        end
      end
      group
    end

    # @rbs context: Context
    # @rbs return: TextDiagram
    def render_text(context)
      line = context.parts.fetch('line')
      diagrams = @items.map do |item|
        diagram = item.render_text(context)
        next diagram unless context.metrics(item).needs_space

        spaced_lines = diagram.lines.each_with_index.map do |text, index|
          "#{index == diagram.entry ? line : ' '}#{text}#{index == diagram.exit ? line : ' '}"
        end
        TextDiagram.new(diagram.entry, diagram.exit, spaced_lines)
      end
      Text::Builder.row([TextDiagram.new(0, 0, ['']), *diagrams], context.parts.fetch('separator'))
    end

    # @rbs return: Array[DiagramItem]
    def child_nodes
      @items.dup
    end

    private

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs length: Numeric
    # @rbs return: Svg::Element
    def svg_path(x, y, length)
      Svg::Element.new('path', { 'd' => Svg::PathData.new(x, y).h(length) }, self_closing: true)
    end

    # @rbs return: void
    def calculate_dimensions
      @up = 0
      @down = 0
      @height = 0
      @width = 0

      @items.each do |item|
        @width += item.width + (item.needs_space ? 20 : 0)
        @up = [@up, item.up - @height].max
        @height += item.height
        @down = [@down - item.height, item.down].max
      end

      @width -= 10 if @items.first&.needs_space
      @width -= 10 if @items.last&.needs_space
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs left_gap: Numeric
    # @rbs right_gap: Numeric
    # @rbs return: void
    def add_edge_paths(x, y, left_gap, right_gap)
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs return: void
    def format_items(x, y)
      @items.each_with_index do |item, i|
        x, y = format_single_item(item, i, x, y)
      end
    end

    # @rbs item: DiagramItem
    # @rbs index: Integer
    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs return: [Numeric, Numeric]
    def format_single_item(item, index, x, y)
      x = add_leading_space(x, y, item, index)
      item.format(x, y, item.width).add(self)
      x += item.width
      y += item.height
      x = add_trailing_space(x, y, item, index)
      [x, y]
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs item: DiagramItem
    # @rbs index: Integer
    # @rbs return: Numeric
    def add_leading_space(x, y, item, index)
      return x unless item.needs_space && index.positive?

      Path.new(x, y).h(10).add(self)
      x + 10
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs item: DiagramItem
    # @rbs index: Integer
    # @rbs return: Numeric
    def add_trailing_space(x, y, item, index)
      return x unless item.needs_space && index < @items.length - 1

      Path.new(x, y).h(10).add(self)
      x + 10
    end
  end
end
