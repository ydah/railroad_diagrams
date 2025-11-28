# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class HorizontalChoice < DiagramMultiContainer
    # @rbs *items: (DiagramItem | String)
    # @rbs return: (HorizontalChoice | Sequence)
    def self.new(*items)
      return Sequence.new(*items) if items.size <= 1

      super
    end

    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(*items)
      super('g', items)
      all_but_last = @items[0...-1]
      middles = @items[1...-1]
      first = @items.first
      last = @items.last
      @needs_space = false

      @width =
        AR + # starting track
        (AR * 2 * (@items.size - 1)) + # in between tracks
        @items.sum { |x| x.width + (x.needs_space ? 20 : 0) } + # items
        (last.height.positive? ? AR : 0) + # needs space to curve up
        AR # ending track

      # Always exits at entrance height
      @height = 0

      # All but the last have a track running above them
      @upper_track = [AR * 2, VS, all_but_last.map(&:up).max + VS].max
      @up = [@upper_track, last.up].max

      # All but the first have a track running below them
      # Last either straight-lines or curves up, so has different calculation
      @lower_track = [
        VS,
        middles.any? ? middles.map { |x| x.height + [x.down + VS, AR * 2].max }.max : 0,
        last.height + last.down + VS
      ].max
      if first.height < @lower_track
        # Make sure there's at least 2*AR room between first exit and lower track
        @lower_track = [@lower_track, first.height + (AR * 2)].max
      end
      @down = [@lower_track, first.height + first.down].max
    end

    # @rbs return: String
    def to_s
      items = @items.map(&:to_s).join(', ')
      "HorizontalChoice(#{items})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: HorizontalChoice
    def format(x, y, width)
      # Hook up the two sides if self is narrower than its stated width.
      left_gap, right_gap = determine_gaps(width, @width)
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
      x += left_gap

      first = @items.first
      last = @items.last

      # upper track
      upper_span =
        @items[0...-1].sum { |item| item.width + (item.needs_space ? 20 : 0) } +
        ((@items.size - 2) * AR * 2) -
        AR

      Path.new(x, y)
          .arc('se')
          .up(@upper_track - (AR * 2))
          .arc('wn')
          .h(upper_span)
          .add(self)

      # lower track
      lower_span =
        @items[1..-1].sum { |item| item.width + (item.needs_space ? 20 : 0) } +
        ((@items.size - 2) * AR * 2) +
        (last.height.positive? ? AR : 0) -
        AR

      lower_start = x + AR + first.width + (first.needs_space ? 20 : 0) + (AR * 2)

      Path.new(lower_start, y + @lower_track)
          .h(lower_span)
          .arc('se')
          .up(@lower_track - (AR * 2))
          .arc('wn')
          .add(self)

      # Items
      @items.each_with_index do |item, i|
        # input track
        if i.zero?
          Path.new(x, y)
              .h(AR)
              .add(self)
          x += AR
        else
          Path.new(x, y - @upper_track)
              .arc('ne')
              .v(@upper_track - (AR * 2))
              .arc('ws')
              .add(self)
          x += AR * 2
        end

        # item
        item_width = item.width + (item.needs_space ? 20 : 0)
        item.format(x, y, item_width).add(self)
        x += item_width

        # output track
        if i == @items.size - 1
          if item.height.zero?
            Path.new(x, y).h(AR).add(self)
          else
            Path.new(x, y + item.height).arc('se').add(self)
          end
        elsif i.zero? && item.height > @lower_track
          # Needs to arc up to meet the lower track, not down.
          if item.height - @lower_track >= AR * 2
            Path.new(x, y + item.height)
                .arc('se')
                .v(@lower_track - item.height + (AR * 2))
                .arc('wn')
                .add(self)
          else
            # Not enough space to fit two arcs
            # so just bail and draw a straight line for now.
            Path.new(x, y + item.height)
                .l(AR * 2, @lower_track - item.height)
                .add(self)
          end
        else
          Path.new(x, y + item.height)
              .arc('ne')
              .v(@lower_track - item.height - (AR * 2))
              .arc('ws')
              .add(self)
        end
      end
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      line, line_vertical, roundcorner_bot_left, roundcorner_bot_right,
      roundcorner_top_left, roundcorner_top_right = TextDiagram.get_parts(
        %w[line line_vertical roundcorner_bot_left roundcorner_bot_right roundcorner_top_left
           roundcorner_top_right]
      )

      # Format all the child items, so we can know the maximum entry, exit, and height.
      item_tds = @items.map(&:text_diagram)

      # diagram_entry: distance from top to lowest entry, aka distance from top to diagram entry, aka final diagram entry and exit.
      diagram_entry = item_tds.map(&:entry).max
      # soil_to_baseline: distance from top to lowest entry before rightmost item, aka distance from skip-over-items line to rightmost entry, aka SOIL height.
      soil_to_baseline = item_tds[0...-1].map(&:entry).max
      # top_to_soil: distance from top to skip-over-items line.
      top_to_soil = diagram_entry - soil_to_baseline
      # baseline_to_suil: distance from lowest entry or exit after leftmost item to bottom, aka distance from entry to skip-under-items line, aka SUIL height.
      baseline_to_suil = item_tds[1..-1].map { |td| td.height - [td.entry, td.exit].min }.max - 1

      # The diagram starts with a line from its entry up to skip-over-items line:
      lines = Array.new(top_to_soil, '  ')
      lines << (roundcorner_top_left + line)
      lines += Array.new(soil_to_baseline, "#{line_vertical} ")
      lines << (roundcorner_bot_right + line)

      diagram_td = TextDiagram.new(lines.size - 1, lines.size - 1, lines)

      item_tds.each_with_index do |item_td, item_num|
        if item_num.positive?
          # All items except the leftmost start with a line from the skip-over-items line down to their entry,
          # with a joining-line across at the skip-under-items line:
          lines = ['  '] * top_to_soil
          # All such items except the rightmost also have a continuation of the skip-over-items line:
          line_to_next_item = item_num == item_tds.size - 1 ? ' ' : line
          lines << (roundcorner_top_right + line_to_next_item)
          lines += ["#{line_vertical} "] * soil_to_baseline
          lines << (roundcorner_bot_left + line)
          lines += ['  '] * baseline_to_suil
          lines << (line * 2)

          entry_td = TextDiagram.new(diagram_td.exit, diagram_td.exit, lines)
          diagram_td = diagram_td.append_right(entry_td, '')
        end

        part_td = TextDiagram.new(0, 0, [])

        if item_num < item_tds.size - 1
          # All items except the rightmost start with a segment of the skip-over-items line at the top.
          # followed by enough blank lines to push their entry down to the previous item's exit:
          lines = []
          lines << (line * item_td.width)
          lines += Array.new(soil_to_baseline - item_td.entry, ' ' * item_td.width)
          soil_segment = TextDiagram.new(0, 0, lines)
          part_td = part_td.append_below(soil_segment, [])
        end

        part_td = part_td.append_below(item_td, [], move_entry: true, move_exit: true)

        if item_num.positive?
          # All items except the leftmost end with enough blank lines to pad down to the skip-under-items
          # line, followed by a segment of the skip-under-items line:
          lines = Array.new(baseline_to_suil - (item_td.height - item_td.entry) + 1, ' ' * item_td.width)
          lines << (line * item_td.width)
          suil_segment = TextDiagram.new(0, 0, lines)
          part_td = part_td.append_below(suil_segment, [])
        end

        diagram_td = diagram_td.append_right(part_td, '')

        if item_num < item_tds.size - 1
          # All items except the rightmost have a line from their exit down to the skip-under-items line,
          # with a joining-line across at the skip-over-items line:
          lines = Array.new(top_to_soil, '  ')
          lines << (line * 2)
          lines += Array.new(diagram_td.exit - top_to_soil - 1, '  ')
          lines << (line + roundcorner_top_right)
          lines += Array.new(baseline_to_suil - (diagram_td.exit - diagram_td.entry), " #{line_vertical}")
          line_from_prev_item = item_num.positive? ? line : ' '
          lines << (line_from_prev_item + roundcorner_bot_left)

          entry = diagram_entry + 1 + (diagram_td.exit - diagram_td.entry)
          exit_td = TextDiagram.new(entry, diagram_entry + 1, lines)
        else
          # The rightmost item has a line from the skip-under-items line and from its exit up to the diagram exit:
          lines = []
          line_from_exit = diagram_td.exit == diagram_td.entry ? line : ' '
          lines << (line_from_exit + roundcorner_top_left)
          lines += Array.new(diagram_td.exit - diagram_td.entry, " #{line_vertical}")
          lines << (line + roundcorner_bot_right) if diagram_td.exit != diagram_td.entry
          lines += Array.new(baseline_to_suil - (diagram_td.exit - diagram_td.entry), " #{line_vertical}")
          lines << (line + roundcorner_bot_right)

          exit_td = TextDiagram.new(diagram_td.exit - diagram_td.entry, 0, lines)
        end
        diagram_td = diagram_td.append_right(exit_td, '')
      end

      diagram_td
    end
  end
end
