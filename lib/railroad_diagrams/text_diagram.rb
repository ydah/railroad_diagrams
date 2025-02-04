# frozen_string_literal: true

module RailroadDiagrams
  class TextDiagram
    PARTS_UNICODE = {
      'cross_diag' => '╳',
      'corner_bot_left' => '└',
      'corner_bot_right' => '┘',
      'corner_top_left' => '┌',
      'corner_top_right' => '┐',
      'cross' => '┼',
      'left' => '│',
      'line' => '─',
      'line_vertical' => '│',
      'multi_repeat' => '↺',
      'rect_bot' => '─',
      'rect_bot_dashed' => '┄',
      'rect_bot_left' => '└',
      'rect_bot_right' => '┘',
      'rect_left' => '│',
      'rect_left_dashed' => '┆',
      'rect_right' => '│',
      'rect_right_dashed' => '┆',
      'rect_top' => '─',
      'rect_top_dashed' => '┄',
      'rect_top_left' => '┌',
      'rect_top_right' => '┐',
      'repeat_bot_left' => '╰',
      'repeat_bot_right' => '╯',
      'repeat_left' => '│',
      'repeat_right' => '│',
      'repeat_top_left' => '╭',
      'repeat_top_right' => '╮',
      'right' => '│',
      'roundcorner_bot_left' => '╰',
      'roundcorner_bot_right' => '╯',
      'roundcorner_top_left' => '╭',
      'roundcorner_top_right' => '╮',
      'roundrect_bot' => '─',
      'roundrect_bot_dashed' => '┄',
      'roundrect_bot_left' => '╰',
      'roundrect_bot_right' => '╯',
      'roundrect_left' => '│',
      'roundrect_left_dashed' => '┆',
      'roundrect_right' => '│',
      'roundrect_right_dashed' => '┆',
      'roundrect_top' => '─',
      'roundrect_top_dashed' => '┄',
      'roundrect_top_left' => '╭',
      'roundrect_top_right' => '╮',
      'separator' => '─',
      'tee_left' => '┤',
      'tee_right' => '├'
    }.freeze

    PARTS_ASCII = {
      'cross_diag' => 'X',
      'corner_bot_left' => '\\',
      'corner_bot_right' => '/',
      'corner_top_left' => '/',
      'corner_top_right' => '\\',
      'cross' => '+',
      'left' => '|',
      'line' => '-',
      'line_vertical' => '|',
      'multi_repeat' => '&',
      'rect_bot' => '-',
      'rect_bot_dashed' => '-',
      'rect_bot_left' => '+',
      'rect_bot_right' => '+',
      'rect_left' => '|',
      'rect_left_dashed' => '|',
      'rect_right' => '|',
      'rect_right_dashed' => '|',
      'rect_top' => '-',
      'rect_top_dashed' => '-',
      'rect_top_left' => '+',
      'rect_top_right' => '+',
      'repeat_bot_left' => '\\',
      'repeat_bot_right' => '/',
      'repeat_left' => '|',
      'repeat_right' => '|',
      'repeat_top_left' => '/',
      'repeat_top_right' => '\\',
      'right' => '|',
      'roundcorner_bot_left' => '\\',
      'roundcorner_bot_right' => '/',
      'roundcorner_top_left' => '/',
      'roundcorner_top_right' => '\\',
      'roundrect_bot' => '-',
      'roundrect_bot_dashed' => '-',
      'roundrect_bot_left' => '\\',
      'roundrect_bot_right' => '/',
      'roundrect_left' => '|',
      'roundrect_left_dashed' => '|',
      'roundrect_right' => '|',
      'roundrect_right_dashed' => '|',
      'roundrect_top' => '-',
      'roundrect_top_dashed' => '-',
      'roundrect_top_left' => '/',
      'roundrect_top_right' => '\\',
      'separator' => '-',
      'tee_left' => '|',
      'tee_right' => '|'
    }.freeze

    class << self
      attr_accessor :parts

      def set_formatting(characters = nil, defaults = nil)
        return unless characters

        @parts = defaults ? defaults.dup : {}
        @parts.merge!(characters)
        @parts.each do |name, value|
          raise ArgumentError, "Text part #{name} is more than 1 character: #{value}" if value.size != 1
        end
      end

      def rect(item, dashed: false)
        rectish('rect', item, dashed)
      end

      def round_rect(item, dashed: false)
        rectish('roundrect', item, dashed)
      end

      def max_width(*args)
        max_width = 0
        args.each do |arg|
          width =
            case arg
            when TextDiagram
              arg.width
            when Array
              arg.map(&:length).max
            when Numeric
              arg.to_s.length
            else
              arg.length
            end
          max_width = width if width > max_width
        end
        max_width
      end

      def pad_l(string, width, pad)
        gap = width - string.length
        raise "Gap #{gap} must be a multiple of pad string '#{pad}'" unless gap % pad.length == 0

        (pad * (gap / pad.length)) + string
      end

      def pad_r(string, width, pad)
        gap = width - string.length
        raise "Gap #{gap} must be a multiple of pad string '#{pad}'" unless gap % pad.length == 0

        string + (pad * (gap / pad.length))
      end

      def get_parts(part_names)
        part_names.map { |name| @parts[name] }
      end

      def enclose_lines(lines, lefts, rights)
        unless lines.length == lefts.length && lines.length == rights.length
          raise 'All arguments must be the same length'
        end

        lines.each_with_index.map { |line, i| lefts[i] + line + rights[i] }
      end

      def gaps(outer_width, inner_width)
        diff = outer_width - inner_width
        case INTERNAL_ALIGNMENT
        when 'left'
          [0, diff]
        when 'right'
          [diff, 0]
        else
          left = diff / 2
          right = diff - left
          [left, right]
        end
      end

      private

      def rectish(rect_type, data, dashed)
        line_type = dashed ? '_dashed' : ''
        top_left, ctr_left, bot_left, top_right, ctr_right, bot_right, top_horiz, bot_horiz, line, cross =
          get_parts([
                      "#{rect_type}_top_left",
                      "#{rect_type}_left#{line_type}",
                      "#{rect_type}_bot_left",
                      "#{rect_type}_top_right",
                      "#{rect_type}_right#{line_type}",
                      "#{rect_type}_bot_right",
                      "#{rect_type}_top#{line_type}",
                      "#{rect_type}_bot#{line_type}",
                      'line',
                      'cross'
                    ])

        item_td = data.is_a?(TextDiagram) ? data : new(0, 0, [data])

        lines = [top_horiz * (item_td.width + 2)]
        if data.is_a?(TextDiagram)
          lines += item_td.expand(1, 1, 0, 0).lines
        else
          (0...item_td.lines.length).each do |i|
            lines += [(' ' + item_td.lines[i] + ' ')]
          end
        end
        lines += [(bot_horiz * (item_td.width + 2))]

        entry = item_td.entry + 1
        exit = item_td.exit + 1

        left_max_width = max_width(top_left, ctr_left, bot_left)
        lefts = [pad_r(ctr_left, left_max_width, ' ')] * lines.length
        lefts[0] = pad_r(top_left, left_max_width, top_horiz)
        lefts[-1] = pad_r(bot_left, left_max_width, bot_horiz)
        lefts[entry] = cross if data.is_a?(TextDiagram)

        right_max_width = max_width(top_right, ctr_right, bot_right)
        rights = [pad_l(ctr_right, right_max_width, ' ')] * lines.length
        rights[0] = pad_l(top_right, right_max_width, top_horiz)
        rights[-1] = pad_l(bot_right, right_max_width, bot_horiz)
        rights[exit] = cross if data.is_a?(TextDiagram)

        lines = enclose_lines(lines, lefts, rights)

        lefts = [' '] * lines.length
        lefts[entry] = line
        rights = [' '] * lines.length
        rights[exit] = line

        lines = enclose_lines(lines, lefts, rights)

        new(entry, exit, lines)
      end
    end

    attr_reader :entry, :exit, :height, :lines, :width

    def initialize(entry, exit, lines)
      @entry = entry
      @exit = exit
      @lines = lines.dup
      @height = lines.size
      @width = lines.any? ? lines[0].length : 0

      raise "Entry is not within diagram vertically:\n#{dump(false)}" unless entry <= lines.length
      raise "Exit is not within diagram vertically:\n#{dump(false)}" unless exit <= lines.length

      lines.each do |line|
        raise "Diagram data is not rectangular:\n#{dump(false)}" unless lines[0].length == line.length
      end
    end

    def alter(new_entry: nil, new_exit: nil, new_lines: nil)
      self.class.new(
        new_entry || @entry,
        new_exit || @exit,
        new_lines || @lines.dup
      )
    end

    def append_below(item, lines_between, move_entry: false, move_exit: false)
      new_width = [@width, item.width].max
      new_lines = center(new_width).lines
      lines_between.each { |line| new_lines << TextDiagram.pad_r(line, new_width, ' ') }
      new_lines += item.center(new_width).lines

      new_entry = move_entry ? @height + lines_between.size + item.entry : @entry
      new_exit = move_exit ? @height + lines_between.size + item.exit : @exit

      self.class.new(new_entry, new_exit, new_lines)
    end

    def append_right(item, chars_between)
      join_line = [@exit, item.entry].max
      new_height = [@height - @exit, item.height - item.entry].max + join_line

      left = expand(0, 0, join_line - @exit, new_height - @height - (join_line - @exit))
      right = item.expand(0, 0, join_line - item.entry, new_height - item.height - (join_line - item.entry))

      new_lines = (0...new_height).map do |i|
        sep = i == join_line ? chars_between : ' ' * chars_between.size
        left_line = i < left.lines.size ? left.lines[i] : ' ' * left.width
        right_line = i < right.lines.size ? right.lines[i] : ' ' * right.width
        "#{left_line}#{sep}#{right_line}"
      end

      self.class.new(
        @entry + (join_line - @exit),
        item.exit + (join_line - item.entry),
        new_lines
      )
    end

    def center(new_width, pad = ' ')
      raise 'Cannot center into smaller width' if width < @width
      return copy if new_width == @width

      total_padding = new_width - @width
      left_width = total_padding / 2
      left = [pad * left_width] * @height
      right = [pad * (total_padding - left_width)] * @height

      self.class.new(@entry, @exit, self.class.enclose_lines(@lines, left, right))
    end

    def copy
      self.class.new(@entry, @exit, @lines.dup)
    end

    def expand(left, right, top, bottom)
      return copy if [left, right, top, bottom].all?(&:zero?)

      new_lines = []
      top.times { new_lines << (' ' * (@width + left + right)) }

      @lines.each do |line|
        left_part = (line == @lines[@entry] ? self.class.parts['line'] : ' ') * left
        right_part = (line == @lines[@exit] ? self.class.parts['line'] : ' ') * right
        new_lines << "#{left_part}#{line}#{right_part}"
      end

      bottom.times { new_lines << (' ' * (@width + left + right)) }

      self.class.new(
        @entry + top,
        @exit + top,
        new_lines
      )
    end

    def dump(show = true)
      result = "height=#{@height}; len(lines)=#{@lines.length}"

      result += "; entry outside diagram: entry=#{@ntry}" if @entry > @lines.length
      result += "; exit outside diagram: exit=#{@exit}" if @exit > @lines.length

      (0...[@lines.length, @entry + 1, @exit + 1].max).each do |y|
        result += "\n[#{format('%03d', y)}]"
        result += " '#{@lines[y]}' len=#{@lines[y].length}" if y < @lines.length
        if y == @entry && y == @exit
          result += ' <- entry, exit'
        elsif y == @entry
          result += ' <- entry'
        elsif y == @exit
          result += ' <- exit'
        end
      end

      if show
        puts result
      else
        result
      end
    end

    private

    def inspect
      output = ["TextDiagram(entry=#{@entry}, exit=#{@exit}, height=#{@height})"]
      @lines.each_with_index do |line, i|
        marker = []
        marker << 'entry' if i == @entry
        marker << 'exit' if i == @exit
        output << (format('%3d: %-20s %s', i, line.inspect, marker.join(', ')))
      end
      output.join("\n")
    end
  end
end
