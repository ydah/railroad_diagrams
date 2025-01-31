# frozen_string_literal: true

module RailroadDiagrams
  class Choice < DiagramMultiContainer
    def initialize(default, *items)
      super('g', items)
      raise ArgumentError, 'default index out of range' if default >= items.size

      @default = default
      @width = (AR * 4) + @items.map(&:width).max

      # The calcs are non-trivial and need to be done both here
      # and in .format(), so no reason to do it twice.
      @separators = Array.new(items.size - 1, VS)

      # If the entry or exit lines would be too close together
      # to accommodate the arcs,
      # bump up the vertical separation to compensate.
      @up = 0
      (default - 1).downto(0) do |i|
        arcs =
          if i == default - 1
            AR * 2
          else
            AR
          end

        item = @items[i]
        lower_item = @items[i + 1]

        entry_delta = lower_item.up + VS + item.down + item.height
        exit_delta = lower_item.height + lower_item.up + VS + item.down

        separator = VS
        separator += [arcs - entry_delta, arcs - exit_delta].max if entry_delta < arcs || exit_delta < arcs
        @separators[i] = separator

        @up += lower_item.up + separator + item.down + item.height
      end
      @up += @items[0].up

      @height = @items[default].height
      @down = 0

      (default + 1...@items.size).each do |i|
        arcs =
          if i == default + 1
            AR * 2
          else
            AR
          end

        item = @items[i]
        upper_item = @items[i - 1]

        entry_delta = upper_item.height + upper_item.down + VS + item.up
        exit_delta = upper_item.down + VS + item.up + item.height

        separator = VS
        separator += [arcs - entry_delta, arcs - exit_delta].max if entry_delta < arcs || exit_delta < arcs
        @separators[i - 1] = separator

        @down += upper_item.down + separator + item.up + item.height
      end
      @down += @items[-1].down
      @needs_space = false
    end

    def to_s
      items_str = @items.map(&:inspect).join(', ')
      "Choice(#{@default}, #{items_str})"
    end

    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)

      # Hook up the two sides if self is narrower than its stated width.
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
      x += left_gap

      inner_width = @width - (AR * 4)
      default = @items[@default]

      # Do the elements that curve above
      distance_from_y = 0
      (@default - 1).downto(0) do |i|
        item = @items[i]
        lower_item = @items[i + 1]
        distance_from_y += lower_item.up + @separators[i] + item.down + item.height
        Path.new(x, y)
            .arc('se')
            .up(distance_from_y - (AR * 2))
            .arc('wn')
            .add(self)
        item.format(x + (AR * 2), y - distance_from_y, inner_width).add(self)
        Path.new(x + (AR * 2) + inner_width, y - distance_from_y + item.height)
            .arc('ne')
            .down(distance_from_y - item.height + default.height - (AR * 2))
            .arc('ws')
            .add(self)
      end

      # Do the straight-line path.
      Path.new(x, y).right(AR * 2).add(self)
      @items[@default].format(x + (AR * 2), y, inner_width).add(self)
      Path.new(x + (AR * 2) + inner_width, y + @height).right(AR * 2).add(self)

      # Do the elements that curve below
      distance_from_y = 0
      (@default + 1...@items.size).each do |i|
        item = @items[i]
        upper_item = @items[i - 1]
        distance_from_y += upper_item.height + upper_item.down + @separators[i - 1] + item.up
        Path.new(x, y)
            .arc('ne')
            .down(distance_from_y - (AR * 2))
            .arc('ws')
            .add(self)
        item.format(x + (AR * 2), y + distance_from_y, inner_width).add(self)
        Path.new(x + (AR * 2) + inner_width, y + distance_from_y + item.height)
            .arc('se')
            .up(distance_from_y - (AR * 2) + item.height - default.height)
            .arc('wn')
            .add(self)
      end

      self
    end

    def text_diagram
      cross, line, line_vertical, roundcorner_bot_left, roundcorner_bot_right, roundcorner_top_left, roundcorner_top_right =
        TextDiagram.get_parts(
          %w[
            cross line line_vertical roundcorner_bot_left roundcorner_bot_right roundcorner_top_left roundcorner_top_right
          ]
        )

      # Format all the child items, so we can know the maximum width.
      item_tds = @items.map { |item| item.text_diagram.expand(1, 1, 0, 0) }
      max_item_width = item_tds.map(&:width).max
      diagram_td = TextDiagram.new(0, 0, [])
      # Format the choice collection.
      item_tds.each_with_index do |item_td, i|
        left_pad, right_pad = TextDiagram.gaps(max_item_width, item_td.width)
        item_td = item_td.expand(left_pad, right_pad, 0, 0)
        has_separator = true
        left_lines = [line_vertical] * item_td.height
        right_lines = [line_vertical] * item_td.height
        move_entry = false
        move_exit = false
        if i <= @default
          # First item and above the line: also remove ascenders above the item's entry and exit, suppress the separator above it.
          has_separator = false
          [0..item_td.entry].each { |j| left_lines[j] = ' ' }
          [0..item_td.exit].each { |j| right_lines[j] = ' ' }
        end
        if i >= @default
          # Item below the line: round off the entry/exit lines downwards.
          left_lines[item_td.entry] = roundcorner_bot_left
          right_lines[item_td.entry] = roundcorner_bot_right
          if i == 0
            # First item and below the line: also suppress the separator above it.
            has_separator = false
          end
          if i == @items.size - 1
            # Last item and below the line: also remove descenders below the item's entry and exit
            [item_td.entry + 1..item_td.height].each { |j| left_lines[j] = ' ' }
            [item_td.exit + 1..item_td.height].each { |j| right_lines[j] = ' ' }
          end
        end
        if i == @default
          # Item on the line: entry/exit are horizontal, and sets the outer entry/exit.
          left_lines[item_td.entry] = cross
          right_lines[item_td.entry] = cross
          move_entry = true
          move_exit = true
          if i == 0 && i == @items.size - 1
            # Only item and on the line: set entry/exit for straight through.
            left_lines[item_td.entry] = line
            right_lines[item_td.entry] = line
          elsif i == 0
            # First item and on the line: set entry/exit for no ascenders.
            left_lines[item_td.entry] = roundcorner_top_left
            left_lines[item_td.exit] = roundcorner_bot_left
          elsif i == @items.size - 1
            # Last item and on the line: set entry/exit for no descenders.
            left_lines[item_td.entry] = roundcorner_bot_left
            right_lines[item_td.entry] = roundcorner_bot_right
          end
        end
        left_join_td = TextDiagram.new(item_td.entry, item_td.entry, left_lines)
        right_join_td = TextDiagram.new(item_td.exit, item_td.exit, right_lines)
        item_td = left_join_td.append_right(item_td, '').append_right(right_join_td, '')
        separator = if has_separator
                      [
                        line_vertical +
                          (' ' * (TextDiagram.max_width(diagram_td, item_td) - 2)) +
                          line_vertical
                      ]
                    else
                      []
                    end
        diagram_td = diagram_td.append_below(item_td, separator, move_entry:, move_exit:)
      end
      diagram_td
    end
  end
end
