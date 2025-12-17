# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Sequence < DiagramMultiContainer
    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(*items)
      super('g', items)
      @needs_space = false
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

    private

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
