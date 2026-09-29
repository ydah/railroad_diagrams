# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # rubocop:disable-next Metrics/ClassLength
  # Draws alternative paths, with one default path.
  # @example
  #   Choice.new(0, 'yes', 'no')
  class Choice < DiagramMultiContainer
    # @rbs default: Integer
    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(default, *items, id: nil, cls: nil, attrs: {})
      super('g', items, nil, nil, id: id, cls: cls, data_attrs: attrs)
      unless default.is_a?(Integer) && (0...items.size).cover?(default)
        raise InvalidArgument, "default index out of range: #{default.inspect} (0...#{items.size})"
      end

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

    # @rbs context: Context
    # @rbs return: Metrics
    def measure(context)
      choice_layout(context).first
    end

    # @rbs context: Context
    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Svg::Element
    def render_svg(context, x, y, width)
      metrics = context.metrics(self)
      separators = choice_layout(context).last
      arc = context.options.arc_radius
      left_gap, right_gap = context.gaps(width, metrics.width)
      group = Svg::Element.new('g', @attrs.dup)
      group << svg_path(Svg::PathData.new(x, y).h(left_gap))
      group << svg_path(Svg::PathData.new(x + left_gap + metrics.width, y + metrics.height).h(right_gap))
      x += left_gap
      inner_width = metrics.width - (arc * 4)
      default = context.metrics(@items[@default])

      distance = 0
      (@default - 1).downto(0) do |index|
        item = @items[index]
        child = context.metrics(item)
        lower = context.metrics(@items[index + 1])
        distance += lower.up + separators[index] + child.down + child.height
        path = Svg::PathData.new(x, y, arc_radius: arc).arc('se').v(-[0, distance - (arc * 2)].max).arc('wn')
        group << svg_path(path)
        group << context.render_svg(item, x + (arc * 2), y - distance, inner_width)
        path = Svg::PathData.new(x + (arc * 2) + inner_width, y - distance + child.height,
                                 arc_radius: arc).arc('ne')
        path.v([0, distance - child.height + default.height - (arc * 2)].max).arc('ws')
        group << svg_path(path)
      end

      group << svg_path(Svg::PathData.new(x, y).h([0, arc * 2].max))
      group << context.render_svg(@items[@default], x + (arc * 2), y, inner_width)
      group << svg_path(Svg::PathData.new(x + (arc * 2) + inner_width, y + metrics.height).h([0, arc * 2].max))

      distance = 0
      (@default + 1...@items.size).each do |index|
        item = @items[index]
        child = context.metrics(item)
        upper = context.metrics(@items[index - 1])
        distance += upper.height + upper.down + separators[index - 1] + child.up
        path = Svg::PathData.new(x, y, arc_radius: arc).arc('ne').v([0, distance - (arc * 2)].max).arc('ws')
        group << svg_path(path)
        group << context.render_svg(item, x + (arc * 2), y + distance, inner_width)
        path = Svg::PathData.new(x + (arc * 2) + inner_width, y + distance + child.height,
                                 arc_radius: arc).arc('se')
        path.v(-[0, distance - (arc * 2) + child.height - default.height].max).arc('wn')
        group << svg_path(path)
      end
      group
    end

    # @rbs context: Context
    # @rbs return: TextDiagram
    def render_text(context)
      cross, line, vertical, bottom_left, bottom_right, top_left, top_right =
        context.parts.values_at('cross', 'line', 'line_vertical', 'roundcorner_bot_left',
                                'roundcorner_bot_right', 'roundcorner_top_left', 'roundcorner_top_right')
      items = @items.map { |item| expand_text(item.render_text(context), 1, 1, line) }
      max_width = items.map(&:width).max
      diagram = TextDiagram.new(0, 0, [])
      items.each_with_index do |item, index|
        left_pad, right_pad = text_gaps(context, max_width, item.width)
        item = expand_text(item, left_pad, right_pad, line)
        left_lines = [vertical] * item.height
        right_lines = [vertical] * item.height
        separator = index.positive?
        move_entry = false
        move_exit = false
        if index <= @default
          left_lines[item.entry] = top_left
          right_lines[item.exit] = top_right
          if index.zero?
            (0...item.entry).each { |row| left_lines[row] = ' ' }
            (0...item.exit).each { |row| right_lines[row] = ' ' }
          end
        end
        if index >= @default
          left_lines[item.entry] = bottom_left
          right_lines[item.exit] = bottom_right
          if index == @items.size - 1
            (item.entry + 1...item.height).each { |row| left_lines[row] = ' ' }
            (item.exit + 1...item.height).each { |row| right_lines[row] = ' ' }
          end
        end
        if index == @default
          left_lines[item.entry] = cross
          right_lines[item.exit] = cross
          move_entry = true
          move_exit = true
          if index.zero? && index == @items.size - 1
            left_lines[item.entry] = line
            right_lines[item.exit] = line
          elsif index.zero?
            left_lines[item.entry] = top_right
            right_lines[item.exit] = top_left
          elsif index == @items.size - 1
            left_lines[item.entry] = bottom_right
            right_lines[item.exit] = bottom_left
          end
        end
        left_join = TextDiagram.new(item.entry, item.entry, left_lines)
        right_join = TextDiagram.new(item.exit, item.exit, right_lines)
        item = left_join.append_right(item, '').append_right(right_join, '')
        between = separator ? [vertical + (' ' * (TextDiagram.max_width(diagram, item) - 2)) + vertical] : []
        diagram = diagram.append_below(item, between, move_entry: move_entry, move_exit: move_exit)
      end
      diagram
    end

    # @rbs return: Array[DiagramItem]
    def child_nodes
      @items.dup
    end

    private

    def choice_layout(context)
      children = @items.map { |item| context.metrics(item) }
      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      width = (arc * 4) + children.map(&:width).max
      separators = Array.new(children.size - 1, separation)
      up = 0
      (@default - 1).downto(0) do |index|
        arcs = index == @default - 1 ? arc * 2 : arc
        item = children[index]
        lower = children[index + 1]
        entry_delta = lower.up + separation + item.down + item.height
        exit_delta = lower.height + lower.up + separation + item.down
        separator = separation
        separator += [arcs - entry_delta, arcs - exit_delta].max if entry_delta < arcs || exit_delta < arcs
        separators[index] = separator
        up += lower.up + separator + item.down + item.height
      end
      up += children[0].up

      height = children[@default].height
      down = 0
      (@default + 1...children.size).each do |index|
        arcs = index == @default + 1 ? arc * 2 : arc
        item = children[index]
        upper = children[index - 1]
        entry_delta = upper.height + upper.down + separation + item.up
        exit_delta = upper.down + separation + item.up + item.height
        separator = separation
        separator += [arcs - entry_delta, arcs - exit_delta].max if entry_delta < arcs || exit_delta < arcs
        separators[index - 1] = separator
        down += upper.down + separator + item.up + item.height
      end
      down += children[-1].down
      [Metrics.new(width: width, up: up, height: height, down: down, needs_space: false), separators]
    end

    def svg_path(data)
      Svg::Element.new('path', { 'd' => data }, self_closing: true)
    end

    def expand_text(diagram, left, right, line)
      rows = diagram.lines.each_with_index.map do |text, index|
        "#{index == diagram.entry ? line * left : ' ' * left}#{text}" \
          "#{index == diagram.exit ? line * right : ' ' * right}"
      end
      TextDiagram.new(diagram.entry, diagram.exit, rows)
    end

    def text_gaps(context, outer, inner)
      difference = outer - inner
      case context.options.internal_alignment
      when :left then [0, difference]
      when :right then [difference, 0]
      else
        left = difference / 2
        [left, difference - left]
      end
    end

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
