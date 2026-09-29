# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Stack < DiagramMultiContainer
    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(*items)
      raise InvalidArgument, 'Stack requires at least one item' if items.empty?

      super('g', items)
      @needs_space = true
      calculate_dimensions
    end

    # @rbs return: String
    def to_s
      items = @items.map(&:to_s).join(', ')
      "Stack(#{items})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Stack
    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      Path.new(x, y).h(left_gap).add(self)
      x += left_gap
      x_initial = x

      inner_width, x = setup_initial_path(x, y)
      x, y = format_stacked_items(x, y, x_initial, inner_width)
      add_final_paths(x, y, right_gap)

      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      corner_bot_left, corner_bot_right, corner_top_left, corner_top_right, line, line_vertical = TextDiagram.get_parts(
        %w[corner_bot_left corner_bot_right corner_top_left corner_top_right line line_vertical]
      )

      item_tds = @items.map(&:text_diagram)
      max_width = item_tds.map(&:width).max
      left_lines = []
      right_lines = []
      separator_td = TextDiagram.new(0, 0, [line * max_width])
      diagram_td = nil
      item_tds.each_with_index do |item_td, item_num|
        if item_num.zero?
          left_lines += [line * 2]
          left_lines += [' ' * 2] * (item_td.height - item_td.entry - 1)
        else
          diagram_td = diagram_td.append_below(separator_td, [])
          left_lines += [corner_top_left + line]
          left_lines += ["#{line_vertical} "] * item_td.entry
          left_lines += [corner_bot_left + line]
          left_lines += [' ' * 2] * (item_td.height - item_td.entry - 1)
          right_lines += [' ' * 2] * item_td.exit
        end
        if item_num < item_tds.size - 1
          right_lines += [line + corner_top_right]
          right_lines += [" #{line_vertical}"] * (item_td.height - item_td.exit - 1)
          right_lines += [line + corner_bot_right]
        else
          right_lines += [line * 2]
        end
        left_pad, right_pad = TextDiagram.gaps(max_width, item_td.width)
        item_td = item_td.expand(left_pad, right_pad, 0, 0)
        diagram_td = item_num.zero? ? item_td : diagram_td.append_below(item_td, [])
      end
      left_td = TextDiagram.new(0, 0, left_lines)
      diagram_td = left_td.append_right(diagram_td, '')
      right_td = TextDiagram.new(0, right_lines.size - 1, right_lines)
      diagram_td.append_right(right_td, '')
    end

    def measure(context)
      item_metrics = @items.map { |item| context.metrics(item) }
      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      width = item_metrics.map { |metrics| metrics.width + (metrics.needs_space ? 20 : 0) }.max
      width += arc * 2 if item_metrics.size > 1

      height = 0
      item_metrics.each_with_index do |metrics, index|
        height += metrics.height
        height += [arc * 2, metrics.up + separation].max if index.positive?
        height += [arc * 2, metrics.down + separation].max if index < item_metrics.size - 1
      end
      Metrics.new(width: width, up: item_metrics.first.up, height: height,
                  down: item_metrics.last.down, needs_space: true)
    end

    def render_svg(context, x, y, width)
      metrics = context.metrics(self)
      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      left_gap, right_gap = context.gaps(width, metrics.width)
      group = Svg::Element.new('g')
      add_svg_path(group, Svg::PathData.new(x, y, arc_radius: arc).h(left_gap))
      x += left_gap
      x_initial = x

      inner_width = metrics.width
      if @items.size > 1
        add_svg_path(group, Svg::PathData.new(x, y, arc_radius: arc).h(arc))
        x += arc
        inner_width -= arc * 2
      end

      @items.each_with_index do |item, index|
        item_metrics = context.metrics(item)
        group << item.render_svg(context, x, y, inner_width)
        x += inner_width
        y += item_metrics.height
        next if index == @items.size - 1

        next_metrics = context.metrics(@items[index + 1])
        loop_back = Svg::PathData.new(x, y, arc_radius: arc)
                                 .arc('ne')
                                 .v([0, item_metrics.down + separation - (arc * 2)].max)
                                 .arc('es').h(-inner_width).arc('nw')
                                 .v([0, next_metrics.up + separation - (arc * 2)].max)
                                 .arc('ws')
        add_svg_path(group, loop_back)
        y += [item_metrics.down + separation, arc * 2].max +
             [next_metrics.up + separation, arc * 2].max
        x = x_initial + arc
      end

      if @items.size > 1
        add_svg_path(group, Svg::PathData.new(x, y, arc_radius: arc).h(arc))
        x += arc
      end
      add_svg_path(group, Svg::PathData.new(x, y, arc_radius: arc).h(right_gap))
      group
    end

    def render_text(context)
      corner_bot_left, corner_bot_right, corner_top_left, corner_top_right, line, line_vertical =
        context.parts.values_at(*%w[corner_bot_left corner_bot_right corner_top_left corner_top_right line line_vertical])
      item_tds = @items.map { |item| item.render_text(context) }
      max_width = item_tds.map(&:width).max
      left_lines = []
      right_lines = []
      expanded = []

      item_tds.each_with_index do |item_td, index|
        if index.zero?
          left_lines << (line * 2)
          left_lines.concat([' ' * 2] * (item_td.height - item_td.entry - 1))
        else
          left_lines << (corner_top_left + line)
          left_lines.concat(["#{line_vertical} "] * item_td.entry)
          left_lines << (corner_bot_left + line)
          left_lines.concat([' ' * 2] * (item_td.height - item_td.entry - 1))
          right_lines.concat([' ' * 2] * item_td.exit)
        end
        if index < item_tds.size - 1
          right_lines << (line + corner_top_right)
          right_lines.concat([" #{line_vertical}"] * (item_td.height - item_td.exit - 1))
          right_lines << (line + corner_bot_right)
        else
          right_lines << (line * 2)
        end

        left_pad, = context.gaps(max_width, item_td.width)
        left_pad = left_pad.floor
        right_pad = max_width - item_td.width - left_pad
        lines = item_td.lines.each_with_index.map do |text, row|
          left = (row == item_td.entry ? line : ' ') * left_pad
          right = (row == item_td.exit ? line : ' ') * right_pad
          "#{left}#{text}#{right}"
        end
        expanded << TextDiagram.new(item_td.entry, item_td.exit, lines)
      end

      middle = TextDiagram.new(expanded.first.entry, expanded.first.exit,
                               Text::Builder.stack(expanded, [line * max_width]))
      left = TextDiagram.new(0, 0, left_lines)
      right = TextDiagram.new(0, right_lines.size - 1, right_lines)
      left.append_right(middle, '').append_right(right, '')
    end

    def child_nodes
      @items.dup
    end

    private

    def add_svg_path(group, path_data)
      group << Svg::Element.new('path', { 'd' => path_data }, self_closing: true)
    end

    # @rbs return: void
    def calculate_dimensions
      @width = @items.map { |item| item.width + (item.needs_space ? 20 : 0) }.max
      @width += AR * 2 if @items.size > 1

      @up = @items.first.up
      @down = @items.last.down
      @height = 0
      last_index = @items.size - 1

      @items.each_with_index do |item, i|
        @height += item.height
        @height += [AR * 2, item.up + VS].max if i.positive?
        @height += [AR * 2, item.down + VS].max if i < last_index
      end
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs return: [Numeric, Numeric]
    def setup_initial_path(x, y)
      return [@width, x] if @items.size == 1

      Path.new(x, y).h(AR).add(self)
      [@width - (AR * 2), x + AR]
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs x_initial: Numeric
    # @rbs inner_width: Numeric
    # @rbs return: [Numeric, Numeric]
    def format_stacked_items(x, y, x_initial, inner_width)
      @items.each_with_index do |item, i|
        item.format(x, y, inner_width).add(self)
        x += inner_width
        y += item.height

        next if i == @items.size - 1

        x, y = add_loop_back_path(x, y, x_initial, inner_width, item, i)
      end
      [x, y]
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs x_initial: Numeric
    # @rbs inner_width: Numeric
    # @rbs item: DiagramItem
    # @rbs index: Integer
    # @rbs return: [Numeric, Numeric]
    def add_loop_back_path(x, y, x_initial, inner_width, item, index)
      next_item = @items[index + 1]

      Path.new(x, y)
          .arc('ne')
          .down([0, item.down + VS - (AR * 2)].max)
          .arc('es')
          .left(inner_width)
          .arc('nw')
          .down([0, next_item.up + VS - (AR * 2)].max)
          .arc('ws')
          .add(self)

      y += [item.down + VS, AR * 2].max + [next_item.up + VS, AR * 2].max
      x = x_initial + AR
      [x, y]
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs right_gap: Numeric
    # @rbs return: void
    def add_final_paths(x, y, right_gap)
      if @items.size > 1
        Path.new(x, y).h(AR).add(self)
        x += AR
      end
      Path.new(x, y).h(right_gap).add(self)
    end
  end
end
