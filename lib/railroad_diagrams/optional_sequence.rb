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

    def measure(context)
      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      children = @items.map { |item| context.metrics(item) }
      height = children.sum(&:height)
      width = 0
      up = 0
      down = children.first.down
      height_so_far = 0.0

      children.each_with_index do |item, index|
        up = [up, [arc * 2, item.up + separation].max - height_so_far].max
        height_so_far += item.height
        down = [height + down, height_so_far + [arc * 2, item.down + separation].max].max - height if index.positive?
        item_width = item.width + (item.needs_space ? 10 : 0)
        width += index.zero? ? arc + [item_width, arc].max : (arc * 2) + [item_width, arc].max + arc
      end
      Metrics.new(width: width, up: up, height: height, down: down, needs_space: false)
    end

    def render_svg(context, x, y, width)
      metrics = context.metrics(self)
      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      left_gap, right_gap = context.gaps(width, metrics.width)
      group = Svg::Element.new('g', @attrs.dup)
      group << path(x, y) { |p| p.h([0, left_gap].max) }
      group << path(x + left_gap + metrics.width, y + metrics.height) { |p| p.h([0, right_gap].max) }
      x += left_gap
      upper_line_y = y - metrics.up
      last = @items.size - 1

      @items.each_with_index do |item, index|
        child = context.metrics(item)
        item_space = child.needs_space ? 10 : 0
        item_width = child.width + item_space
        if index.zero?
          group << path(x, y, arc) do |p|
            p.arc('se').v(-[0, y - upper_line_y - (arc * 2)].max).arc('wn')
             .h([0, item_width - arc].max).arc('ne')
             .v([0, y + child.height - upper_line_y - (arc * 2)].max).arc('ws')
          end
          group << path(x, y) { |p| p.h([0, item_space + arc].max) }
          group << item.render_svg(context, x + item_space + arc, y, child.width)
          x += item_width + arc
          y += child.height
          next
        end

        if index < last
          group << path(x, upper_line_y, arc) do |p|
            p.h([0, (arc * 2) + [item_width, arc].max + arc].max).arc('ne')
             .v([0, y - upper_line_y + child.height - (arc * 2)].max).arc('ws')
          end
        end
        group << path(x, y) { |p| p.h(arc * 2) }
        group << item.render_svg(context, x + (arc * 2), y, child.width)
        group << path(x + (arc * 2) + child.width, y + child.height) { |p| p.h([0, item_space + arc].max) }
        group << path(x, y, arc) do |p|
          p.arc('ne').v([0, child.height + [child.down + separation, arc * 2].max - (arc * 2)].max)
           .arc('ws').h([0, item_width - arc].max)
           .arc('se').v(-[0, child.down + separation - (arc * 2)].max).arc('wn')
        end
        x += (arc * 2) + [item_width, arc].max + arc
        y += child.height
      end
      group
    end

    def render_text(context)
      render_text_diagram(context.parts, context)
    end

    def child_nodes
      @items.dup
    end

    # @rbs return: TextDiagram
    def text_diagram
      render_text_diagram(Context.legacy.parts, nil)
    end

    private

    def path(x, y, arc = AR)
      data = Svg::PathData.new(x, y, arc_radius: arc)
      yield data
      Svg::Element.new('path', { 'd' => data }, self_closing: true)
    end

    def render_text_diagram(parts, context)
      line, line_vertical, roundcorner_bot_left, roundcorner_bot_right,
      roundcorner_top_left, roundcorner_top_right = parts.values_at(
        'line', 'line_vertical', 'roundcorner_bot_left', 'roundcorner_bot_right',
        'roundcorner_top_left', 'roundcorner_top_right'
      )

      # Format all the child items, so we can know the maximum entry.
      item_tds = @items.map { |item| context ? item.render_text(context) : item.text_diagram }

      # diagramEntry: distance from top to lowest entry, aka distance from top to diagram entry, aka final diagram entry and exit.
      diagram_entry = item_tds.map(&:entry).max
      # SOILHeight: distance from top to lowest entry before rightmost item, aka distance from skip-over-items line to rightmost entry, aka SOIL height.
      soil_height = item_tds[0...-1].map(&:entry).max
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
          lines = (['   '] * top_to_soil) +
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
