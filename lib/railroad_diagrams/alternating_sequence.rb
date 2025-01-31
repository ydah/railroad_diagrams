# frozen_string_literal: true

module RailroadDiagrams
  class AlternatingSequence < DiagramMultiContainer
    def self.new(*items)
      raise "AlternatingSequence takes exactly two arguments, but got #{items.size} arguments." unless items.size == 2

      super
    end

    def initialize(*items)
      super('g', items)
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

    def to_s
      items = @items.map(&:to_s).join(', ')
      "AlternatingSequence(#{items})"
    end

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
      max_width = TextDiagram._max_width(first_td, second_td)
      left_width, right_width = TextDiagram._gaps(max_width, 0)

      left_lines = []
      right_lines = []
      separator = []

      left_size, right_size = TextDiagram._gaps(first_td.width, 0)
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

      left_size, right_size = TextDiagram._gaps(second_td.width, 0)
      second_td = second_td.expand(left_width - left_size, right_width - right_size, 0, 0)
      diagram_td = diagram_td.append_below(second_td, separator, move_entry: true, move_exit: true)

      left_lines << (corner_top_left + line)
      left_lines += ["#{line_vertical} "] * second_td.entry
      left_lines << (corner_bot_left + line)

      right_lines << (line + corner_top_right)
      right_lines += [" #{line_vertical}"] * second_td.entry
      right_lines << (line + corner_bot_right)

      mid_point = first_td.height + (separator.size / 2)
      diagram_td = diagram_td.alter(entry: mid_point, exit: mid_point)

      left_td = TextDiagram.new(mid_point, mid_point, left_lines)
      right_td = TextDiagram.new(mid_point, mid_point, right_lines)

      diagram_td = left_td.append_right(diagram_td, '').append_right(right_td, '')
      TextDiagram.new(1, 1, [corner_top_left, tee_left, corner_bot_left])
                 .append_right(diagram_td, '')
                 .append_right(TextDiagram.new(1, 1, [corner_top_right, tee_right, corner_bot_right]), '')
    end
  end
end
