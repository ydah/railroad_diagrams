# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # Draws choices side by side.
  # @example
  #   HorizontalChoice.new('red', 'blue')
  class HorizontalChoice < DiagramMultiContainer
    TEXT_PARTS = %w[line line_vertical roundcorner_bot_left roundcorner_bot_right
                    roundcorner_top_left roundcorner_top_right].freeze

    # @rbs *items: (DiagramItem | String)
    # @rbs return: (HorizontalChoice | Sequence)
    def self.new(*items, id: nil, cls: nil, attrs: {})
      return Sequence.new(*items, id: id, cls: cls, attrs: attrs) if items.size <= 1

      super
    end

    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(*items, id: nil, cls: nil, attrs: {})
      super('g', items, nil, nil, id: id, cls: cls, data_attrs: attrs)
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

    def measure(context)
      item_metrics = @items.map { |item| context.metrics(item) }
      first = item_metrics.first
      last = item_metrics.last
      arc = context.options.arc_radius
      upper_track, lower_track = context_tracks(context, item_metrics)
      width = arc + (arc * 2 * (item_metrics.size - 1)) +
              item_metrics.sum { |metrics| metrics.width + (metrics.needs_space ? 20 : 0) } +
              (last.height.positive? ? arc : 0) + arc

      Metrics.new(width: width, up: [upper_track, last.up].max, height: 0,
                  down: [lower_track, first.height + first.down].max, needs_space: false)
    end

    def render_svg(context, x, y, width)
      metrics = context.metrics(self)
      item_metrics = @items.map { |item| context.metrics(item) }
      first = item_metrics.first
      last = item_metrics.last
      arc = context.options.arc_radius
      upper_track, lower_track = context_tracks(context, item_metrics)
      left_gap, right_gap = context.gaps(width, metrics.width)
      group = Svg::Element.new('g')
      add_svg_path(group, Svg::PathData.new(x, y, arc_radius: arc).h(left_gap))
      add_svg_path(group, Svg::PathData.new(x + left_gap + metrics.width, y + metrics.height,
                                            arc_radius: arc).h(right_gap))
      x += left_gap

      upper_span = item_metrics[0...-1].sum { |item| item.width + (item.needs_space ? 20 : 0) } +
                   ((item_metrics.size - 2) * arc * 2) - arc
      upper = Svg::PathData.new(x, y, arc_radius: arc).arc('se')
                           .v(-[0, upper_track - (arc * 2)].max).arc('wn').h(upper_span)
      add_svg_path(group, upper)

      lower_span = item_metrics[1..-1].sum { |item| item.width + (item.needs_space ? 20 : 0) } +
                   ((item_metrics.size - 2) * arc * 2) +
                   (last.height.positive? ? arc : 0) - arc
      lower_start = x + arc + first.width + (first.needs_space ? 20 : 0) + (arc * 2)
      lower = Svg::PathData.new(lower_start, y + lower_track, arc_radius: arc)
                           .h(lower_span).arc('se').v(-[0, lower_track - (arc * 2)].max).arc('wn')
      add_svg_path(group, lower)

      @items.each_with_index do |item, index|
        item_metrics_for_node = item_metrics[index]
        if index.zero?
          add_svg_path(group, Svg::PathData.new(x, y, arc_radius: arc).h(arc))
          x += arc
        else
          input = Svg::PathData.new(x, y - upper_track, arc_radius: arc)
                               .arc('ne').v(upper_track - (arc * 2)).arc('ws')
          add_svg_path(group, input)
          x += arc * 2
        end

        item_width = item_metrics_for_node.width + (item_metrics_for_node.needs_space ? 20 : 0)
        group << context.render_svg(item, x, y, item_width)
        x += item_width

        output = if index == @items.size - 1
                   if item_metrics_for_node.height.zero?
                     Svg::PathData.new(x, y, arc_radius: arc).h(arc)
                   else
                     Svg::PathData.new(x, y + item_metrics_for_node.height, arc_radius: arc).arc('se')
                   end
                 elsif index.zero? && item_metrics_for_node.height > lower_track
                   if item_metrics_for_node.height - lower_track >= arc * 2
                     Svg::PathData.new(x, y + item_metrics_for_node.height, arc_radius: arc)
                                  .arc('se').v(lower_track - item_metrics_for_node.height + (arc * 2)).arc('wn')
                   else
                     Svg::PathData.new(x, y + item_metrics_for_node.height, arc_radius: arc)
                                  .l(arc * 2, lower_track - item_metrics_for_node.height)
                   end
                 else
                   Svg::PathData.new(x, y + item_metrics_for_node.height, arc_radius: arc)
                                .arc('ne').v(lower_track - item_metrics_for_node.height - (arc * 2)).arc('ws')
                 end
        add_svg_path(group, output)
      end
      group
    end

    # @rbs return: TextDiagram
    def text_diagram
      render_text_diagram(@items.map(&:text_diagram), TextDiagram.get_parts(TEXT_PARTS))
    end

    def render_text(context)
      render_text_diagram(@items.map { |item| item.render_text(context) }, context.parts.values_at(*TEXT_PARTS))
    end

    def child_nodes
      @items.dup
    end

    private

    def context_tracks(context, item_metrics)
      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      first = item_metrics.first
      last = item_metrics.last
      upper_track = [arc * 2, separation, item_metrics[0...-1].map(&:up).max + separation].max
      middle_clearance = if item_metrics.size > 2
                           item_metrics[1...-1].map do |metrics|
                             metrics.height + [metrics.down + separation, arc * 2].max
                           end.max
                         else
                           0
                         end
      lower_track = [separation, middle_clearance, last.height + last.down + separation].max
      lower_track = [lower_track, first.height + (arc * 2)].max if first.height < lower_track
      [upper_track, lower_track]
    end

    def add_svg_path(group, path_data)
      group << Svg::Element.new('path', { 'd' => path_data }, self_closing: true)
    end

    def render_text_diagram(item_tds, parts)
      line, line_vertical, roundcorner_bot_left, roundcorner_bot_right,
      roundcorner_top_left, roundcorner_top_right = parts

      # Format all the child items, so we can know the maximum entry, exit, and height.

      # diagram_entry: distance from top to lowest entry, aka distance from top to diagram entry, aka final diagram entry and exit.
      diagram_entry = item_tds.map(&:entry).max
      # soil_to_baseline: distance from top to lowest entry before rightmost item, aka distance from skip-over-items line to rightmost entry, aka SOIL height.
      soil_to_baseline = item_tds[0...-1].map(&:entry).max
      # top_to_soil: distance from top to skip-over-items line.
      top_to_soil = diagram_entry - soil_to_baseline
      # baseline_to_suil: distance from lowest entry or exit after leftmost item to bottom, aka distance from entry to skip-under-items line, aka SUIL height.
      baseline_to_suil = item_tds.map { |td| td.height - [td.entry, td.exit].min }.max - 1

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
