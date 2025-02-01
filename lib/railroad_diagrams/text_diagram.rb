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

      def rect(item, dashed = false)
        rectish('rect', item, dashed)
      end

      def round_rect(item, dashed = false)
        rectish('roundrect', item, dashed)
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
        parts = get_parts([
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

        item_td = data.is_a?(TextDiagram) ? data : new(0, 0, [data.to_s])

        lines = [parts[6] * (item_td.width + 2)]
        lines += item_td.expand(1, 1, 0, 0).lines.map { |line| " #{line} " }
        lines << (parts[7] * (item_td.width + 2))

        entry = item_td.entry + 1
        exit = item_td.exit + 1

        left_max = [parts[0], parts[1], parts[2]].map(&:size).max
        lefts = Array.new(lines.size, parts[1].ljust(left_max))
        lefts[0] = parts[0].ljust(left_max, parts[6])
        lefts[-1] = parts[2].ljust(left_max, parts[7])
        lefts[entry] = parts[9].ljust(left_max) if data.is_a?(TextDiagram)

        right_max = [parts[3], parts[4], parts[5]].map(&:size).max
        rights = Array.new(lines.size, parts[4].rjust(right_max))
        rights[0] = parts[3].rjust(right_max, parts[6])
        rights[-1] = parts[5].rjust(right_max, parts[7])
        rights[exit] = parts[9].rjust(right_max) if data.is_a?(TextDiagram)

        new_lines = lines.each_with_index.map do |line, i|
          lefts[i] + line + rights[i]
        end

        lefts = Array.new(lines.size, ' ')
        lefts[entry] = parts[8]
        rights = Array.new(lines.size, ' ')
        rights[exit] = parts[8]

        new_lines = new_lines.each_with_index.map do |line, i|
          lefts[i] + line + rights[i]
        end

        new(entry, exit, new_lines)
      end
    end

    attr_reader :entry, :exit, :height, :lines, :width

    def initialize(entry, exit, lines)
      @entry = entry
      @exit = exit
      @lines = lines.dup
      @height = lines.size
      @width = lines.empty? ? 0 : lines.first.size

      validate
    end

    def alter(new_entry = nil, new_exit = nil, new_lines = nil)
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

    private

    def validate
      return if @lines.empty?

      line_length = @lines.first.size
      @lines.each do |line|
        raise ArgumentError, "Diagram is not rectangular:\n#{inspect}" unless line.size == line_length
      end

      raise ArgumentError, "Entry point out of bounds:\n#{inspect}" if @entry >= @height

      return unless @exit >= @height

      raise ArgumentError, "Exit point out of bounds:\n#{inspect}"
    end

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
