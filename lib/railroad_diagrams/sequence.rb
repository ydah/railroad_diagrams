# frozen_string_literal: true

module RailroadDiagrams
  class Sequence < DiagramMultiContainer
    def initialize(*items)
      super('g', items)
      @needs_space = false
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
      @width -= 10 if @items[0].needs_space
      @width -= 10 if @items[-1].needs_space
    end

    def to_s
      items = @items.map(&:to_s).join(', ')
      "Sequence(#{items})"
    end

    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
      x += left_gap
      @items.each_with_index do |item, i|
        if item.needs_space && i.positive?
          Path.new(x, y).h(10).add(self)
          x += 10
        end
        item.format(x, y, item.width).add(self)
        x += item.width
        y += item.height
        if item.needs_space && i < @items.length - 1
          Path.new(x, y).h(10).add(self)
          x += 10
        end
      end
      self
    end

    def text_diagram
      separator, = TextDiagram.get_parts(['separator'])
      diagram_td = TextDiagram.new(0, 0, [''])
      @items.each do |item|
        item_td = item.text_diagram
        item_td = item_td.expand(1, 1, 0, 0) if item.needs_space
        diagram_td = diagram_td.append_right(item_td, separator)
      end
      diagram_td
    end
  end
end
