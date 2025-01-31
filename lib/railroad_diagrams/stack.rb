# frozen_string_literal: true

module RailroadDiagrams
  class Stack < DiagramMultiContainer
    def initialize(*items)
      super('g', items)
      @need_space = false
      @width = @items.map { |item| item.width + (item.needs_space ? 20 : 0) }.max

      # pretty sure that space calc is totes wrong
      @width += AR * 2 if @items.size > 1

      @up = @items.first.up
      @down = @items.last.down
      @height = 0
      last = @items.size - 1

      @items.each_with_index do |item, i|
        @height += item.height
        @height += [AR * 2, item.up + VS].max if i.positive?
        @height += [AR * 2, item.down + VS].max if i < last
      end
    end

    def to_s
      items = @items.map(&:to_s).join(', ')
      "Stack(#{items})"
    end

    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      Path.new(x, y).h(left_gap).add(self)
      x += left_gap
      x_initial = x
      if @items.size > 1
        Path.new(x, y).h(AR).add(self)
        x += AR
        inner_width = @width - (AR * 2)
      else
        inner_width = @width
      end

      @items.each_with_index do |item, i|
        item.format(x, y, inner_width).add(self)
        x += inner_width
        y += item.height
        next unless i != @items.size - 1

        Path.new(x, y)
            .arc('ne')
            .down([0, item.down + VS - (AR * 2)].max)
            .arc('es')
            .left(inner_width)
            .arc('nw')
            .down([0, @items[i + 1].up + VS - (AR * 2)].max)
            .arc('ws')
            .add(self)
        y += [item.down + VS, AR * 2].max + [@items[i + 1].up + VS, AR * 2].max
        x = x_initial + AR
      end
      if @items.size > 1
        Path.new(x, y).h(AR).add(self)
        x += AR
      end
      Path.new(x, y).h(right_gap).add(self)
      self
    end

    def text_diagram
      corner_bot_left, corner_bot_right, corner_top_left, corner_top_right, line, line_vertical = TextDiagram.get_parts(
        %w[corner_bot_left corner_bot_right corner_top_left corner_top_right line line_vertical]
      )

      # Format all the child items, so we can know the maximum width.
      item_tds = @items.map(&:text_diagram)
      max_width = item_tds.map(&:width).max
      left_lines = []
      right_lines = []
      separator_td = TextDiagram.new(0, 0, [line * max_width])
      diagram_td = nil # Top item will replace it.
      item_tds.each_with_index do |item_td, item_num|
        if item_num.zero?
          # The top item enters directly from its left.
          left_lines += [line * 2]
          left_lines += [' ' * 2] * (item_td.height - item_td.entry - 1)
        else
          # All items below the top enter from a snake-line from the previous item's exit.
          # Here, we resume that line, already having descended from above on the right.
          diagram_td = diagram_td.append_below(separator_td, [])
          left_lines += [corner_top_left + line]
          left_lines += ["#{line_vertical} "] * item_td.entry
          left_lines += [corner_bot_left + line]
          left_lines += [' ' * 2] * (item_td.height - item_td.entry - 1)
          right_lines += [' ' * 2] * item_td.exit
        end
        if item_num < item_tds.size - 1
          # All items above the bottom exit via a snake-line to the next item's entry.
          # Here, we start that line on the right.
          right_lines += [line + corner_top_right]
          right_lines += [" #{line_vertical}"] * (item_td.height - item_td.exit - 1)
          right_lines += [line + corner_bot_right]
        else
          # The bottom item exits directly to its right.
          right_lines += [line * 2]
        end
        left_pad, right_pad = TextDiagram._gaps(max_width, item_td.width)
        item_td = item_td.expand(left_pad, right_pad, 0, 0)
        diagram_td = if item_num.zero?
                       item_td
                     else
                       diagram_td.append_below(item_td, [])
                     end
      end
      left_td = TextDiagram.new(0, 0, left_lines)
      diagram_td = left_td.append_right(diagram_td, '')
      right_td = TextDiagram.new(0, right_lines.size - 1, right_lines)
      diagram_td.append_right(right_td, '')
    end
  end
end
