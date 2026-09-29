# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class TextDiagram
    PARTS_UNICODE = Text::Parts::UNICODE
    PARTS_ASCII = Text::Parts::ASCII
    NARROW_LINE = /\A[ -~\u2500-\u257F]*\z/.freeze

    class << self
      attr_accessor :parts #: Hash[String, String]?

      # @rbs characters: Hash[String, String]?
      # @rbs defaults: Hash[String, String]?
      # @rbs return: void
      def set_formatting(characters = nil, defaults = nil)
        return unless characters

        @parts = defaults ? defaults.dup : {}
        @parts.merge!(characters)
        @parts.each do |name, value|
          raise InvalidArgument, "Text part #{name} is more than 1 character: #{value}" if value.size != 1
        end
      end

      # @rbs item: String | TextDiagram
      # @rbs dashed: bool
      # @rbs parts: Hash[String, String]?
      # @rbs return: TextDiagram
      def rect(item, dashed: false, parts: nil)
        rectish('rect', item, dashed, parts)
      end

      # @rbs item: String | TextDiagram
      # @rbs dashed: bool
      # @rbs parts: Hash[String, String]?
      # @rbs return: TextDiagram
      def round_rect(item, dashed: false, parts: nil)
        rectish('roundrect', item, dashed, parts)
      end

      # @rbs *args: (TextDiagram | Array[String] | Numeric | String)
      # @rbs return: Integer
      def max_width(*args)
        max_width = 0
        args.each do |arg|
          width =
            case arg
            when TextDiagram
              arg.width
            when Array
              arg.map { |line| Unicode::DisplayWidth.of(line) }.max
            when Numeric
              Unicode::DisplayWidth.of(arg.to_s)
            else
              Unicode::DisplayWidth.of(arg)
            end
          max_width = width if width > max_width
        end
        max_width
      end

      # @rbs string: String
      # @rbs width: Integer
      # @rbs pad: String
      # @rbs return: String
      def pad_l(string, width, pad)
        gap = width - Unicode::DisplayWidth.of(string)
        pad_width = Unicode::DisplayWidth.of(pad)
        raise "Gap #{gap} must be a multiple of pad string '#{pad}'" unless (gap % pad_width).zero?

        (pad * (gap / pad_width)) + string
      end

      # @rbs string: String
      # @rbs width: Integer
      # @rbs pad: String
      # @rbs return: String
      def pad_r(string, width, pad)
        gap = width - Unicode::DisplayWidth.of(string)
        pad_width = Unicode::DisplayWidth.of(pad)
        raise "Gap #{gap} must be a multiple of pad string '#{pad}'" unless (gap % pad_width).zero?

        string + (pad * (gap / pad_width))
      end

      # @rbs part_names: Array[String]
      # @rbs return: Array[String]
      def get_parts(part_names)
        Context.legacy.parts.values_at(*part_names)
      end

      # @rbs lines: Array[String]
      # @rbs lefts: Array[String]
      # @rbs rights: Array[String]
      # @rbs return: Array[String]
      def enclose_lines(lines, lefts, rights)
        unless lines.length == lefts.length && lines.length == rights.length
          raise 'All arguments must be the same length'
        end

        lines.each_with_index.map { |line, i| lefts[i] + line + rights[i] }
      end

      # @rbs outer_width: Integer
      # @rbs inner_width: Integer
      # @rbs return: [Integer, Integer]
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

      # @rbs rect_type: String
      # @rbs data: String | TextDiagram
      # @rbs dashed: bool
      # @rbs parts: Hash[String, String]?
      # @rbs return: TextDiagram
      def rectish(rect_type, data, dashed, parts)
        line_type = dashed ? '_dashed' : ''
        top_left, ctr_left, bot_left, top_right, ctr_right, bot_right, top_horiz, bot_horiz, line, cross =
          (parts || Context.legacy.parts).values_at(
            "#{rect_type}_top_left", "#{rect_type}_left#{line_type}", "#{rect_type}_bot_left",
            "#{rect_type}_top_right", "#{rect_type}_right#{line_type}", "#{rect_type}_bot_right",
            "#{rect_type}_top#{line_type}", "#{rect_type}_bot#{line_type}", 'line', 'cross'
          )

        item_td = data.is_a?(TextDiagram) ? data : new(0, 0, [data])

        lines = [top_horiz * (item_td.width + 2)]
        if data.is_a?(TextDiagram)
          lines += item_td.expand(1, 1, 0, 0).lines
        else
          (0...item_td.lines.length).each do |i|
            lines += [" #{item_td.lines[i]} "]
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

    attr_reader :entry #: Integer
    attr_reader :exit #: Integer
    attr_reader :height #: Integer
    attr_reader :lines #: Array[String]
    attr_reader :width #: Integer

    # @rbs entry: Integer
    # @rbs exit: Integer
    # @rbs lines: Array[String]
    # @rbs return: void
    def initialize(entry, exit, lines)
      @entry = entry
      @exit = exit
      @lines = lines.dup
      @height = lines.size
      @width = lines.any? ? line_width(lines[0]) : 0

      raise "Entry is not within diagram vertically:\n#{dump(false)}" unless entry <= lines.length
      raise "Exit is not within diagram vertically:\n#{dump(false)}" unless exit <= lines.length

      lines.each do |line|
        raise "Diagram data is not rectangular:\n#{dump(false)}" unless @width == line_width(line)
      end
    end

    # @rbs new_entry: Integer?
    # @rbs new_exit: Integer?
    # @rbs new_lines: Array[String]?
    # @rbs return: TextDiagram
    def alter(new_entry: nil, new_exit: nil, new_lines: nil)
      self.class.new(
        new_entry || @entry,
        new_exit || @exit,
        new_lines || @lines.dup
      )
    end

    # @rbs item: TextDiagram
    # @rbs lines_between: Array[String]
    # @rbs move_entry: bool
    # @rbs move_exit: bool
    # @rbs return: TextDiagram
    def append_below(item, lines_between, move_entry: false, move_exit: false)
      new_width = [@width, item.width].max
      new_lines = center(new_width).lines
      lines_between.each { |line| new_lines << TextDiagram.pad_r(line, new_width, ' ') }
      new_lines += item.center(new_width).lines

      new_entry = move_entry ? @height + lines_between.size + item.entry : @entry
      new_exit = move_exit ? @height + lines_between.size + item.exit : @exit

      trusted_copy(new_entry, new_exit, new_lines, new_width)
    end

    # @rbs item: TextDiagram
    # @rbs chars_between: String
    # @rbs return: TextDiagram
    def append_right(item, chars_between)
      join_line = [@exit, item.entry].max
      new_height = [@height - @exit, item.height - item.entry].max + join_line

      left = expand(0, 0, join_line - @exit, new_height - @height - (join_line - @exit))
      right = item.expand(0, 0, join_line - item.entry, new_height - item.height - (join_line - item.entry))
      separator_width = Unicode::DisplayWidth.of(chars_between)

      new_lines = (0...new_height).map do |i|
        sep = i == join_line ? chars_between : ' ' * separator_width
        left_line = i < left.lines.size ? left.lines[i] : ' ' * left.width
        right_line = i < right.lines.size ? right.lines[i] : ' ' * right.width
        "#{left_line}#{sep}#{right_line}"
      end

      trusted_copy(
        @entry + (join_line - @exit),
        item.exit + (join_line - item.entry),
        new_lines,
        @width + separator_width + item.width
      )
    end

    # @rbs new_width: Integer
    # @rbs pad: String
    # @rbs return: TextDiagram
    def center(new_width, pad = ' ')
      raise InvalidArgument, "Cannot center into smaller width (#{new_width} < #{@width})" if new_width < @width
      return copy if new_width == @width

      total_padding = new_width - @width
      left_width = total_padding / 2
      left = [pad * left_width] * @height
      right = [pad * (total_padding - left_width)] * @height

      new_lines = self.class.enclose_lines(@lines, left, right)
      pad == ' ' ? trusted_copy(@entry, @exit, new_lines, new_width) : self.class.new(@entry, @exit, new_lines)
    end

    # @rbs return: TextDiagram
    def copy
      trusted_copy(@entry, @exit, @lines.dup, @width)
    end

    # @rbs left: Integer
    # @rbs right: Integer
    # @rbs top: Integer
    # @rbs bottom: Integer
    # @rbs return: TextDiagram
    def expand(left, right, top, bottom)
      return copy if [left, right, top, bottom].all?(&:zero?)

      new_lines = []
      top.times { new_lines << (' ' * (@width + left + right)) }

      line_char, = self.class.get_parts(['line'])
      @lines.each_with_index do |line, i|
        left_part = (i == @entry ? line_char : ' ') * left
        right_part = (i == @exit ? line_char : ' ') * right
        new_lines << "#{left_part}#{line}#{right_part}"
      end

      bottom.times { new_lines << (' ' * (@width + left + right)) }

      new_width = @width + left + right
      if [left, right, top, bottom].all? { |amount| amount >= 0 } &&
         ((left.zero? && right.zero?) || Unicode::DisplayWidth.of(line_char) == 1)
        trusted_copy(@entry + top, @exit + top, new_lines, new_width)
      else
        self.class.new(@entry + top, @exit + top, new_lines)
      end
    end

    # @rbs show: bool
    # @rbs return: (String | nil)
    def dump(show = true)
      result = "height=#{@height}; len(lines)=#{@lines.length}"

      result += "; entry outside diagram: entry=#{@entry}" if @entry > @lines.length
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

    # @rbs return: String
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

    private

    def line_width(line)
      NARROW_LINE.match?(line) ? line.length : Unicode::DisplayWidth.of(line)
    end

    # Call only when every line is built from already rectangular diagrams.
    def trusted_copy(entry, exit, lines, width)
      result = dup
      result.instance_variable_set(:@entry, entry)
      result.instance_variable_set(:@exit, exit)
      result.instance_variable_set(:@lines, lines)
      result.instance_variable_set(:@height, lines.size)
      result.instance_variable_set(:@width, width)
      result
    end
  end
end
