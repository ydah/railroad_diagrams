# frozen_string_literal: true

module RailroadDiagrams
  class OneOrMore < DiagramItem
    def initialize(item, repeat = nil)
      super('g')
      @item = wrap_string(item)
      repeat ||= Skip.new
      @rep = wrap_string(repeat)
      @width = [@item.width, @rep.width].max + (AR * 2)
      @height = @item.height
      @up = @item.up
      @down = [AR * 2, @item.down + VS + @rep.up + @rep.height + @rep.down].max
      @needs_space = true
    end

    def to_s
      "OneOrMore(#{@item}, repeat=#{@rep})"
    end

    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)

      # Hook up the two sides if self is narrower than its stated width.
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
      x += left_gap

      # Draw item
      Path.new(x, y).right(AR).add(self)
      @item.format(x + AR, y, @width - (AR * 2)).add(self)
      Path.new(x + @width - AR, y + @height).right(AR).add(self)

      # Draw repeat arc
      distance_from_y = [AR * 2, @item.height + @item.down + VS + @rep.up].max
      Path.new(x + AR, y).arc('nw').down(distance_from_y - (AR * 2)).arc('ws').add(self)
      @rep.format(x + AR, y + distance_from_y, @width - (AR * 2)).add(self)
      Path.new(x + @width - AR, y + distance_from_y + @rep.height)
          .arc('se')
          .up(distance_from_y - (AR * 2) + @rep.height - @item.height)
          .arc('en')
          .add(self)

      self
    end

    def text_diagram
      parts = TextDiagram.get_parts(
        %w[
          line repeat_top_left repeat_left repeat_bot_left repeat_top_right repeat_right repeat_bot_right
        ]
      )
      line, repeat_top_left, repeat_left, repeat_bot_left, repeat_top_right, repeat_right, repeat_bot_right = parts

      # Format the item and then format the repeat append it to the bottom, after a spacer.
      item_td = @item.text_diagram
      repeat_td = @rep.text_diagram
      fir_width = TextDiagram.max_width(item_td, repeat_td)
      repeat_td = repeat_td.expand(0, fir_width - repeat_td.width, 0, 0)
      item_td = item_td.expand(0, fir_width - item_td.width, 0, 0)
      item_and_repeat_td = item_td.append_below(repeat_td, [])

      # Build the left side of the repeat line and append the combined item and repeat to its right.
      left_lines = []
      left_lines << (repeat_top_left + line)
      left_lines += ["#{repeat_left} "] * ((item_td.height - item_td.entry) + repeat_td.entry - 1)
      left_lines << (repeat_bot_left + line)
      left_td = TextDiagram.new(0, 0, left_lines)
      left_td = left_td.append_right(item_and_repeat_td, '')

      # Build the right side of the repeat line and append it to the combined left side, item, and repeat's right.
      right_lines = []
      right_lines << (line + repeat_top_right)
      right_lines += [" #{repeat_right}"] * ((item_td.height - item_td.exit) + repeat_td.exit - 1)
      right_lines << (line + repeat_bot_right)
      right_td = TextDiagram.new(0, 0, right_lines)
      left_td.append_right(right_td, '')
    end

    def walk(callback)
      callback.call(self)
      @item.walk(callback)
      @rep.walk(callback)
    end
  end
end
