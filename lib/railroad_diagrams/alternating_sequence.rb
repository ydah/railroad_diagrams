# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # Draws two paths that cross between the entry and exit.
  # @example
  #   AlternatingSequence.new('true', 'false')
  class AlternatingSequence < DiagramMultiContainer
    # @rbs *items: (DiagramItem | String)
    # @rbs return: AlternatingSequence
    def self.new(*items, id: nil, cls: nil, attrs: {})
      raise InvalidArgument, "AlternatingSequence takes exactly two arguments, but got #{items.size} arguments." unless items.size == 2

      super
    end

    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(*items, id: nil, cls: nil, attrs: {})
      super('g', items, nil, nil, id: id, cls: cls, data_attrs: attrs)
      @needs_space = false

      arc = AR
      vert = VS
      first, second = @items

      arc_x = 1 / Math.sqrt(2) * arc * 2
      arc_y = (1 - (1 / Math.sqrt(2))) * arc * 2
      cross_y = [arc, vert].max
      cross_x = (cross_y - arc_y) + arc_x

      first_out = [
        arc + arc, (cross_y / 2) + arc + arc, (cross_y / 2) + vert + first.down
      ].max
      @up = first_out + first.height + first.up

      second_in = [
        arc + arc, (cross_y / 2) + arc + arc, (cross_y / 2) + vert + second.up
      ].max
      @down = second_in + second.height + second.down

      @height = 0

      first_width = (first.needs_space ? 20 : 0) + first.width
      second_width = (second.needs_space ? 20 : 0) + second.width
      @width = (2 * arc) + [first_width, cross_x, second_width].max + (2 * arc)
    end

    # @rbs return: String
    def to_s
      items = @items.map(&:to_s).join(', ')
      "AlternatingSequence(#{items})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: AlternatingSequence
    def format(x, y, width)
      arc = AR
      gaps = determine_gaps(width, @width)
      Path.new(x, y).right(gaps[0]).add(self)
      x += gaps[0]
      Path.new(x + @width, y + @height).right(gaps[1]).add(self)
      # bounding box
      # Path(x+gaps[0], y).up(@up).right(@width).down(@up+@down).left(@width).up(@up).add(self)
      first, second = @items

      # top
      first_in = @up - first.up
      first_out = @up - first.up - first.height
      Path.new(x, y).arc('se').up(first_in - (2 * arc)).arc('wn').add(self)
      first.format(x + (2 * arc), y - first_in, @width - (4 * arc)).add(self)
      Path.new(x + @width - (2 * arc), y - first_out)
          .arc('ne').down(first_out - (2 * arc)).arc('ws').add(self)

      # bottom
      second_in = @down - second.down - second.height
      second_out = @down - second.down
      Path.new(x, y)
          .arc('ne')
          .down(second_in - (2 * arc))
          .arc('ws')
          .add(self)
      second.format(x + (2 * arc), y + second_in, @width - (4 * arc)).add(self)
      Path.new(x + @width - (2 * arc), y + second_out)
          .arc('se').up(second_out - (2 * arc)).arc('wn').add(self)

      # crossover
      arc_x = 1 / Math.sqrt(2) * arc * 2
      arc_y = (1 - (1 / Math.sqrt(2))) * arc * 2
      cross_y = [arc, VS].max
      cross_x = (cross_y - arc_y) + arc_x
      cross_bar = (@width - (4 * arc) - cross_x) / 2

      Path.new(x + arc, y - (cross_y / 2) - arc)
          .arc('ws')
          .right(cross_bar)
          .arc_8('n', 'cw')
          .l(cross_x - arc_x, cross_y - arc_y)
          .arc_8('sw', 'ccw')
          .right(cross_bar)
          .arc('ne')
          .add(self)

      Path.new(x + arc, y + (cross_y / 2) + arc)
          .arc('wn')
          .right(cross_bar)
          .arc_8('s', 'ccw')
          .l(cross_x - arc_x, -(cross_y - arc_y))
          .arc_8('nw', 'cw')
          .right(cross_bar)
          .arc('se')
          .add(self)

      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      cross_diag, corner_bot_left, corner_bot_right, corner_top_left, corner_top_right,
      line, line_vertical, tee_left, tee_right = TextDiagram.get_parts(
        %w[
          cross_diag roundcorner_bot_left roundcorner_bot_right
          roundcorner_top_left roundcorner_top_right line
          line_vertical tee_left tee_right
        ]
      )

      first_td = @items[0].text_diagram
      second_td = @items[1].text_diagram
      max_width = [TextDiagram.max_width(first_td, second_td), 4].max
      left_width, right_width = TextDiagram.gaps(max_width, 0)

      left_lines = []
      right_lines = []
      separator = []

      left_size, right_size = TextDiagram.gaps(first_td.width, 0)
      diagram_td = first_td.expand(left_width - left_size, right_width - right_size, 0, 0)

      left_lines += [' ' * 2] * diagram_td.entry
      left_lines << (corner_top_left + line)
      left_lines += ["#{line_vertical} "] * (diagram_td.height - diagram_td.entry - 1)
      left_lines << (corner_bot_left + line)

      right_lines += [' ' * 2] * diagram_td.entry
      right_lines << (line + corner_top_right)
      right_lines += [" #{line_vertical}"] * (diagram_td.height - diagram_td.entry - 1)
      right_lines << (line + corner_bot_right)

      separator << ("#{line * (left_width - 1)}#{corner_top_right} #{corner_top_left}#{line * (right_width - 2)}")
      separator << ("#{' ' * (left_width - 1)} #{cross_diag} #{' ' * (right_width - 2)}")
      separator << ("#{line * (left_width - 1)}#{corner_bot_right} #{corner_bot_left}#{line * (right_width - 2)}")

      left_lines << (' ' * 2)
      right_lines << (' ' * 2)

      left_size, right_size = TextDiagram.gaps(second_td.width, 0)
      second_td = second_td.expand(left_width - left_size, right_width - right_size, 0, 0)
      diagram_td = diagram_td.append_below(second_td, separator, move_entry: true, move_exit: true)

      left_lines << (corner_top_left + line)
      left_lines += ["#{line_vertical} "] * second_td.entry
      left_lines << (corner_bot_left + line)

      right_lines << (line + corner_top_right)
      right_lines += [" #{line_vertical}"] * second_td.entry
      right_lines << (line + corner_bot_right)

      mid_point = first_td.height + (separator.size / 2)
      diagram_td = diagram_td.alter(new_entry: mid_point, new_exit: mid_point)

      left_td = TextDiagram.new(mid_point, mid_point, left_lines)
      right_td = TextDiagram.new(mid_point, mid_point, right_lines)

      diagram_td = left_td.append_right(diagram_td, '').append_right(right_td, '')
      TextDiagram.new(1, 1, [corner_top_left, tee_left, corner_bot_left])
                 .append_right(diagram_td, '')
                 .append_right(TextDiagram.new(1, 1, [corner_top_right, tee_right, corner_bot_right]), '')
    end

    # @rbs context: Context
    # @rbs return: Metrics
    def measure(context)
      arc = context.options.arc_radius
      vert = context.options.vertical_separation
      first, second = @items.map { |item| context.metrics(item) }
      arc_x = 1 / Math.sqrt(2) * arc * 2
      arc_y = (1 - (1 / Math.sqrt(2))) * arc * 2
      cross_y = [arc, vert].max
      cross_x = (cross_y - arc_y) + arc_x

      first_out = [arc + arc, (cross_y / 2) + arc + arc, (cross_y / 2) + vert + first.down].max
      up = first_out + first.height + first.up
      second_in = [arc + arc, (cross_y / 2) + arc + arc, (cross_y / 2) + vert + second.up].max
      down = second_in + second.height + second.down
      first_width = (first.needs_space ? 20 : 0) + first.width
      second_width = (second.needs_space ? 20 : 0) + second.width
      width = (2 * arc) + [first_width, cross_x, second_width].max + (2 * arc)
      Metrics.new(width: width, up: up, height: 0, down: down, needs_space: false)
    end

    # @rbs context: Context
    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Svg::Element
    def render_svg(context, x, y, width)
      metrics = context.metrics(self)
      arc = context.options.arc_radius
      gaps = context.gaps(width, metrics.width)
      group = Svg::Element.new('g', @attrs.dup)
      group << svg_path(Svg::PathData.new(x, y).h([0, gaps[0]].max))
      x += gaps[0]
      group << svg_path(Svg::PathData.new(x + metrics.width, y + metrics.height).h([0, gaps[1]].max))
      first, second = @items
      first_metrics, second_metrics = @items.map { |item| context.metrics(item) }

      first_in = metrics.up - first_metrics.up
      first_out = metrics.up - first_metrics.up - first_metrics.height
      group << svg_path(Svg::PathData.new(x, y, arc_radius: arc).arc('se').v(-[0, first_in - (2 * arc)].max).arc('wn'))
      group << context.render_svg(first, x + (2 * arc), y - first_in, metrics.width - (4 * arc))
      path = Svg::PathData.new(x + metrics.width - (2 * arc), y - first_out, arc_radius: arc)
      group << svg_path(path.arc('ne').v([0, first_out - (2 * arc)].max).arc('ws'))

      second_in = metrics.down - second_metrics.down - second_metrics.height
      second_out = metrics.down - second_metrics.down
      group << svg_path(Svg::PathData.new(x, y, arc_radius: arc).arc('ne').v([0, second_in - (2 * arc)].max).arc('ws'))
      group << context.render_svg(second, x + (2 * arc), y + second_in, metrics.width - (4 * arc))
      path = Svg::PathData.new(x + metrics.width - (2 * arc), y + second_out, arc_radius: arc)
      group << svg_path(path.arc('se').v(-[0, second_out - (2 * arc)].max).arc('wn'))

      add_crossovers(group, context, x, y, metrics.width)
      group
    end

    # @rbs context: Context
    # @rbs return: TextDiagram
    def render_text(context)
      cross, bottom_left, bottom_right, top_left, top_right, line, vertical, tee_left, tee_right =
        context.parts.values_at('cross_diag', 'roundcorner_bot_left', 'roundcorner_bot_right',
                                'roundcorner_top_left', 'roundcorner_top_right', 'line',
                                'line_vertical', 'tee_left', 'tee_right')
      first = @items[0].render_text(context)
      second = @items[1].render_text(context)
      max_width = [TextDiagram.max_width(first, second), 4].max
      left_width, right_width = text_gaps(context, max_width, 0)
      left_lines = []
      right_lines = []
      separator = []

      left_size, right_size = text_gaps(context, first.width, 0)
      diagram = expand_text(first, left_width - left_size, right_width - right_size, line)
      left_lines += [' ' * 2] * diagram.entry
      left_lines << (top_left + line)
      left_lines += ["#{vertical} "] * (diagram.height - diagram.entry - 1)
      left_lines << (bottom_left + line)
      right_lines += [' ' * 2] * diagram.entry
      right_lines << (line + top_right)
      right_lines += [" #{vertical}"] * (diagram.height - diagram.entry - 1)
      right_lines << (line + bottom_right)
      separator << ("#{line * (left_width - 1)}#{top_right} #{top_left}#{line * (right_width - 2)}")
      separator << ("#{' ' * (left_width - 1)} #{cross} #{' ' * (right_width - 2)}")
      separator << ("#{line * (left_width - 1)}#{bottom_right} #{bottom_left}#{line * (right_width - 2)}")
      left_lines << (' ' * 2)
      right_lines << (' ' * 2)

      left_size, right_size = text_gaps(context, second.width, 0)
      second = expand_text(second, left_width - left_size, right_width - right_size, line)
      diagram = diagram.append_below(second, separator, move_entry: true, move_exit: true)
      left_lines << (top_left + line)
      left_lines += ["#{vertical} "] * second.entry
      left_lines << (bottom_left + line)
      right_lines << (line + top_right)
      right_lines += [" #{vertical}"] * second.entry
      right_lines << (line + bottom_right)

      midpoint = first.height + (separator.size / 2)
      diagram = diagram.alter(new_entry: midpoint, new_exit: midpoint)
      left_td = TextDiagram.new(midpoint, midpoint, left_lines)
      right_td = TextDiagram.new(midpoint, midpoint, right_lines)
      diagram = left_td.append_right(diagram, '').append_right(right_td, '')
      TextDiagram.new(1, 1, [top_left, tee_left, bottom_left])
                 .append_right(diagram, '')
                 .append_right(TextDiagram.new(1, 1, [top_right, tee_right, bottom_right]), '')
    end

    # @rbs return: Array[DiagramItem]
    def child_nodes
      @items.dup
    end

    private

    def add_crossovers(group, context, x, y, width)
      arc = context.options.arc_radius
      arc_x = 1 / Math.sqrt(2) * arc * 2
      arc_y = (1 - (1 / Math.sqrt(2))) * arc * 2
      cross_y = [arc, context.options.vertical_separation].max
      cross_x = (cross_y - arc_y) + arc_x
      cross_bar = (width - (4 * arc) - cross_x) / 2

      path = Svg::PathData.new(x + arc, y - (cross_y / 2) - arc, arc_radius: arc)
      path.arc('ws').h([0, cross_bar].max).arc_8('n', 'cw')
          .l(cross_x - arc_x, cross_y - arc_y).arc_8('sw', 'ccw').h([0, cross_bar].max).arc('ne')
      group << svg_path(path)
      path = Svg::PathData.new(x + arc, y + (cross_y / 2) + arc, arc_radius: arc)
      path.arc('wn').h([0, cross_bar].max).arc_8('s', 'ccw')
          .l(cross_x - arc_x, -(cross_y - arc_y)).arc_8('nw', 'cw').h([0, cross_bar].max).arc('se')
      group << svg_path(path)
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
  end
end
