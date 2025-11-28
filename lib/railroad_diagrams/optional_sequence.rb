# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class OptionalSequence < DiagramMultiContainer
    # @rbs *items: (DiagramItem | String)
    # @rbs return: (OptionalSequence | Sequence)
    def self.new(*items)
      return Sequence.new(*items) if items.size <= 1

      super
    end

    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(*items)
      super('g', items)
      @needs_space = false
      @width = 0
      @up = 0
      @height = @items.sum(&:height)
      @down = @items.first.down

      height_so_far = 0.0

      @items.each_with_index do |item, i|
        @up = [@up, [AR * 2, item.up + VS].max - height_so_far].max
        height_so_far += item.height

        if i.positive?
          @down = [
            @height + @down,
            height_so_far + [AR * 2, item.down + VS].max
          ].max - @height
        end

        item_width = item.width + (item.needs_space ? 10 : 0)
        @width += if i.zero?
                    AR + [item_width, AR].max
                  else
                    (AR * 2) + [item_width, AR].max + AR
                  end
      end
    end

    # @rbs return: String
    def to_s
      items = @items.map(&:to_s).join(', ')
      "OptionalSequence(#{items})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: OptionalSequence
    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      Path.new(x, y).right(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).right(right_gap).add(self)
      x += left_gap
      upper_line_y = y - @up
      last = @items.size - 1

      @items.each_with_index do |item, i|
        item_space = item.needs_space ? 10 : 0
        item_width = item.width + item_space

        if i.zero?
          # Upper skip
          Path.new(x, y)
              .arc('se')
              .up(y - upper_line_y - (AR * 2))
              .arc('wn')
              .right(item_width - AR)
              .arc('ne')
              .down(y + item.height - upper_line_y - (AR * 2))
              .arc('ws')
              .add(self)

          # Straight line
          Path.new(x, y).right(item_space + AR).add(self)
          item.format(x + item_space + AR, y, item.width).add(self)
          x += item_width + AR
          y += item.height
        elsif i < last
          # Upper skip
          Path.new(x, upper_line_y)
              .right((AR * 2) + [item_width, AR].max + AR)
              .arc('ne')
              .down(y - upper_line_y + item.height - (AR * 2))
              .arc('ws')
              .add(self)

          # Straight line
          Path.new(x, y).right(AR * 2).add(self)
          item.format(x + (AR * 2), y, item.width).add(self)
          Path.new(x + item.width + (AR * 2), y + item.height)
              .right(item_space + AR)
              .add(self)

          # Lower skip
          Path.new(x, y)
              .arc('ne')
              .down(item.height + [item.down + VS, AR * 2].max - (AR * 2))
              .arc('ws')
              .right(item_width - AR)
              .arc('se')
              .up(item.down + VS - (AR * 2))
              .arc('wn')
              .add(self)

          x += (AR * 2) + [item_width, AR].max + AR
          y += item.height
        else
          # Straight line
          Path.new(x, y).right(AR * 2).add(self)
          item.format(x + (AR * 2), y, item.width).add(self)
          Path.new(x + (AR * 2) + item.width, y + item.height)
              .right(item_space + AR)
              .add(self)

          # Lower skip
          Path.new(x, y)
              .arc('ne')
              .down(item.height + [item.down + VS, AR * 2].max - (AR * 2))
              .arc('ws')
              .right(item_width - AR)
              .arc('se')
              .up(item.down + VS - (AR * 2))
              .arc('wn')
              .add(self)
        end
      end
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      line, line_vertical, roundcorner_bot_left, roundcorner_bot_right,
      roundcorner_top_left, roundcorner_top_right = TextDiagram.get_parts(
        %w[line line_vertical roundcorner_bot_left roundcorner_bot_right roundcorner_top_left roundcorner_top_right]
      )

      # Format all the child items, so we can know the maximum entry.
      item_tds = @items.map(&:text_diagram)

      # diagramEntry: distance from top to lowest entry, aka distance from top to diagram entry, aka final diagram entry and exit.
      diagram_entry = item_tds.map(&:entry).max
      # SOILHeight: distance from top to lowest entry before rightmost item, aka distance from skip-over-items line to rightmost entry, aka SOIL height.
      soil_height = item_tds.map(&:entry).max
      # topToSOIL: distance from top to skip-over-items line.
      top_to_soil = diagram_entry - soil_height

      # The diagram starts with a line from its entry up to the skip-over-items line:
      lines = ['  '] * top_to_soil
      lines += [roundcorner_top_left + line]
      lines += ["#{line_vertical} "] * soil_height
      lines += [roundcorner_bot_right + line]
      diagram_td = TextDiagram.new(lines.size - 1, lines.size - 1, lines)

      item_tds.each_with_index do |item_td, i|
        if i.positive?
          # All items except the leftmost start with a line from their entry down to their skip-under-item line,
          # with a joining-line across at the skip-over-items line:
          lines = (['  '] * top_to_soil) + [line * 2] +
                  (['  '] * (diagram_td.exit - top_to_soil - 1)) +
                  [line + roundcorner_top_right] +
                  ([" #{line_vertical}"] * (item_td.height - item_td.entry - 1)) +
                  [" #{roundcorner_bot_left}"]

          skip_down_td = TextDiagram.new(diagram_td.exit, diagram_td.exit, lines)
          diagram_td = diagram_td.append_right(skip_down_td, '')

          # All items except the leftmost next have a line from skip-over-items line down to their entry,
          # with joining-lines at their entry and at their skip-under-item line:
          lines = (['  '] * top_to_soil) +
                  [line + roundcorner_top_right +
                   # All such items except the rightmost also have a continuation of the skip-over-items line:
                   (i < item_tds.size - 1 ? line : ' ')] +
                  ([" #{line_vertical} "] * (diagram_td.exit - top_to_soil - 1)) +
                  [line + roundcorner_bot_left + line] +
                  ([' ' * 3] * (item_td.height - item_td.entry - 1)) +
                  [line * 3]

          entry_td = TextDiagram.new(diagram_td.exit, diagram_td.exit, lines)
          diagram_td = diagram_td.append_right(entry_td, '')
        end

        part_td = TextDiagram.new(0, 0, [])
        if i < item_tds.size - 1
          # All items except the rightmost have a segment of the skip-over-items line at the top,
          # followed by enough blank lines to push their entry down to the previous item's exit:
          lines = [line * item_td.width] + ([' ' * item_td.width] * (soil_height - item_td.entry))
          soil_segment = TextDiagram.new(0, 0, lines)
          part_td = part_td.append_below(soil_segment, [])
        end

        part_td = part_td.append_below(item_td, [], move_entry: true, move_exit: true)

        if i.positive?
          # All items except the leftmost have their skip-under-item line at the bottom.
          soil_segment = TextDiagram.new(0, 0, [line * item_td.width])
          part_td = part_td.append_below(soil_segment, [])
        end

        diagram_td = diagram_td.append_right(part_td, '')

        next unless i.positive?

        # All items except the leftmost have a line from their skip-under-item line to their exit:
        lines = (['  '] * top_to_soil) +
                # All such items except the rightmost also have a joining-line across at the skip-over-items line:
                [(i < item_tds.size - 1 ? line * 2 : '  ')] +
                (['  '] * (diagram_td.exit - top_to_soil - 1)) +
                [line + roundcorner_top_left] +
                ([" #{line_vertical}"] * (part_td.height - part_td.exit - 2)) +
                [line + roundcorner_bot_right]

        skip_up_td = TextDiagram.new(diagram_td.exit, diagram_td.exit, lines)
        diagram_td = diagram_td.append_right(skip_up_td, '')
      end

      diagram_td
    end
  end
end
