# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Choice < DiagramMultiContainer
    # @rbs default: Integer
    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
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

    # @rbs return: String
    def to_s
      items_str = @items.map(&:to_s).join(', ')
      "Choice(#{@default}, #{items_str})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Choice
    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
      x += left_gap

      inner_width = @width - (AR * 4)
      default = @items[@default]

      format_items_above_default(x, y, inner_width, default)
      format_default_item(x, y, inner_width)
      format_items_below_default(x, y, inner_width, default)

      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      cross, line, line_vertical, roundcorner_bot_left, roundcorner_bot_right, roundcorner_top_left, roundcorner_top_right =
        TextDiagram.get_parts(
          %w[
            cross line line_vertical roundcorner_bot_left roundcorner_bot_right roundcorner_top_left roundcorner_top_right
          ]
        )

      item_tds = @items.map { |item| item.text_diagram.expand(1, 1, 0, 0) }
      max_item_width = item_tds.map(&:width).max
      diagram_td = TextDiagram.new(0, 0, [])
      item_tds.each_with_index do |item_td, i|
        left_pad, right_pad = TextDiagram.gaps(max_item_width, item_td.width)
        item_td = item_td.expand(left_pad, right_pad, 0, 0)
        has_separator = true
        left_lines = [line_vertical] * item_td.height
        right_lines = [line_vertical] * item_td.height
        move_entry = false
        move_exit = false
        if i <= @default
          left_lines[item_td.entry] = roundcorner_top_left
          right_lines[item_td.exit] = roundcorner_top_right
          if i.zero?
            has_separator = false
            (0...item_td.entry).each { |j| left_lines[j] = ' ' }
            (0...item_td.exit).each { |j| right_lines[j] = ' ' }
          end
        end
        if i >= @default
          left_lines[item_td.entry] = roundcorner_bot_left
          right_lines[item_td.exit] = roundcorner_bot_right
          if i.zero?
            has_separator = false
          end
          if i == @items.size - 1
            (item_td.entry + 1...item_td.height).each { |j| left_lines[j] = ' ' }
            (item_td.exit + 1...item_td.height).each { |j| right_lines[j] = ' ' }
          end
        end
        if i == @default
          left_lines[item_td.entry] = cross
          right_lines[item_td.exit] = cross
          move_entry = true
          move_exit = true
          if i.zero? && i == @items.size - 1
            left_lines[item_td.entry] = line
            right_lines[item_td.exit] = line
          elsif i.zero?
            left_lines[item_td.entry] = roundcorner_top_right
            right_lines[item_td.exit] = roundcorner_top_left
          elsif i == @items.size - 1
            left_lines[item_td.entry] = roundcorner_bot_right
            right_lines[item_td.exit] = roundcorner_bot_left
          end
        end
        left_join_td = TextDiagram.new(item_td.entry, item_td.entry, left_lines)
        right_join_td = TextDiagram.new(item_td.exit, item_td.exit, right_lines)
        item_td = left_join_td.append_right(item_td, '').append_right(right_join_td, '')
        separator =
          if has_separator
            [
              line_vertical +
                (' ' * (TextDiagram.max_width(diagram_td, item_td) - 2)) + line_vertical
            ]
          else
            []
          end
        diagram_td = diagram_td.append_below(item_td, separator, move_entry: move_entry, move_exit: move_exit)
      end
      diagram_td
    end

    private

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs inner_width: Numeric
    # @rbs default: DiagramItem
    # @rbs return: void
    def format_items_above_default(x, y, inner_width, default)
      distance_from_y = 0
      (@default - 1).downto(0) do |i|
        item = @items[i]
        lower_item = @items[i + 1]
        distance_from_y += lower_item.up + @separators[i] + item.down + item.height

        add_upward_path(x, y, distance_from_y)
        item.format(x + (AR * 2), y - distance_from_y, inner_width).add(self)
        add_downward_return_path(x + (AR * 2) + inner_width, y, distance_from_y, item, default)
      end
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs inner_width: Numeric
    # @rbs return: void
    def format_default_item(x, y, inner_width)
      Path.new(x, y).right(AR * 2).add(self)
      @items[@default].format(x + (AR * 2), y, inner_width).add(self)
      Path.new(x + (AR * 2) + inner_width, y + @height).right(AR * 2).add(self)
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs inner_width: Numeric
    # @rbs default: DiagramItem
    # @rbs return: void
    def format_items_below_default(x, y, inner_width, default)
      distance_from_y = 0
      (@default + 1...@items.size).each do |i|
        item = @items[i]
        upper_item = @items[i - 1]
        distance_from_y += upper_item.height + upper_item.down + @separators[i - 1] + item.up

        add_downward_path(x, y, distance_from_y)
        item.format(x + (AR * 2), y + distance_from_y, inner_width).add(self)
        add_upward_return_path(x + (AR * 2) + inner_width, y, distance_from_y, item, default)
      end
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs distance: Numeric
    # @rbs return: void
    def add_upward_path(x, y, distance)
      Path.new(x, y)
          .arc('se')
          .up(distance - (AR * 2))
          .arc('wn')
          .add(self)
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs distance: Numeric
    # @rbs item: DiagramItem
    # @rbs default: DiagramItem
    # @rbs return: void
    def add_downward_return_path(x, y, distance, item, default)
      Path.new(x, y - distance + item.height)
          .arc('ne')
          .down(distance - item.height + default.height - (AR * 2))
          .arc('ws')
          .add(self)
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs distance: Numeric
    # @rbs return: void
    def add_downward_path(x, y, distance)
      Path.new(x, y)
          .arc('ne')
          .down(distance - (AR * 2))
          .arc('ws')
          .add(self)
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs distance: Numeric
    # @rbs item: DiagramItem
    # @rbs default: DiagramItem
    # @rbs return: void
    def add_upward_return_path(x, y, distance, item, default)
      Path.new(x, y + distance + item.height)
          .arc('se')
          .up(distance - (AR * 2) + item.height - default.height)
          .arc('wn')
          .add(self)
    end
  end
end
