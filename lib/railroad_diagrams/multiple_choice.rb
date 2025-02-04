# frozen_string_literal: true

module RailroadDiagrams
  class MultipleChoice < DiagramMultiContainer
    def initialize(default, type, *items)
      super('g', items)
      raise ArgumentError, "default must be between 0 and #{items.length - 1}" unless (0...items.length).cover?(default)
      raise ArgumentError, "type must be 'any' or 'all'" unless %w[any all].include?(type)

      @default = default
      @type = type
      @needs_space = true
      @inner_width = @items.map(&:width).max
      @width = 30 + AR + @inner_width + AR + 20
      @up = @items[0].up
      @down = @items[-1].down
      @height = @items[default].height

      @items.each_with_index do |item, i|
        minimum =
          if [default - 1, default + 1].include?(i)
            10 + AR
          else
            AR
          end

        if i < default
          @up += [minimum, item.height + item.down + VS + @items[i + 1].up].max
        elsif i > default
          @down += [minimum, item.up + VS + @items[i - 1].down + @items[i - 1].height].max
        end
      end

      @down -= @items[default].height # already counted in @height
    end

    def to_s
      items = @items.map(&:to_s).join(', ')
      "MultipleChoice(#{@default}, #{@type}, #{items})"
    end

    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)

      # Hook up the two sides if self is narrower than its stated width.
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
      x += left_gap

      default = @items[@default]

      # Do the elements that curve above
      above = @items[0...@default].reverse
      distance_from_y = 0
      distance_from_y = [10 + AR, default.up + VS + above.first.down + above.first.height].max if above.any?

      double_enumerate(above).each do |i, ni, item|
        Path.new(x + 30, y).up(distance_from_y - AR).arc('wn').add(self)
        item.format(x + 30 + AR, y - distance_from_y, @inner_width).add(self)
        Path.new(x + 30 + AR + @inner_width, y - distance_from_y + item.height)
            .arc('ne')
            .down(distance_from_y - item.height + default.height - AR - 10)
            .add(self)
        distance_from_y += [AR, item.up + VS + above[i + 1].down + above[i + 1].height].max if ni < -1
      end

      # Do the straight-line path.
      Path.new(x + 30, y).right(AR).add(self)
      @items[@default].format(x + 30 + AR, y, @inner_width).add(self)
      Path.new(x + 30 + AR + @inner_width, y + @height).right(AR).add(self)

      # Do the elements that curve below
      below = @items[(@default + 1)..-1] || []
      distance_from_y = [10 + AR, default.height + default.down + VS + below.first.up].max if below.any?

      below.each_with_index do |item, i|
        Path.new(x + 30, y).down(distance_from_y - AR).arc('ws').add(self)
        item.format(x + 30 + AR, y + distance_from_y, @inner_width).add(self)
        Path.new(x + 30 + AR + @inner_width, y + distance_from_y + item.height)
            .arc('se')
            .up(distance_from_y - AR + item.height - default.height - 10)
            .add(self)

        distance_from_y += [AR, item.height + item.down + VS + (below[i + 1]&.up || 0)].max
      end

      text = DiagramItem.new('g', attrs: { 'class' => 'diagram-text' }).add(self)
      DiagramItem.new(
        'title',
        text: @type == 'any' ? 'take one or more branches, once each, in any order' : 'take all branches, once each, in any order'
      ).add(text)

      DiagramItem.new(
        'path',
        attrs: {
          'd' => "M #{x + 30} #{y - 10} h -26 a 4 4 0 0 0 -4 4 v 12 a 4 4 0 0 0 4 4 h 26 z",
          'class' => 'diagram-text'
        }
      ).add(text)

      DiagramItem.new(
        'text',
        text: @type == 'any' ? '1+' : 'all',
        attrs: { 'x' => x + 15, 'y' => y + 4, 'class' => 'diagram-text' }
      ).add(text)

      DiagramItem.new(
        'path',
        attrs: {
          'd' => "M #{x + @width - 20} #{y - 10} h 16 a 4 4 0 0 1 4 4 v 12 a 4 4 0 0 1 -4 4 h -16 z",
          'class' => 'diagram-text'
        }
      ).add(text)

      DiagramItem.new(
        'text',
        text: '↺',
        attrs: { 'x' => x + @width - 10, 'y' => y + 4, 'class' => 'diagram-arrow' }
      ).add(text)

      self
    end

    def text_diagram
      multi_repeat = TextDiagram.get_parts(['multi_repeat']).first
      any_all = TextDiagram.rect(@type == 'any' ? '1+' : 'all')
      diagram_td = Choice.new(0, Skip.new).text_diagram
      repeat_td = TextDiagram.rect(multi_repeat)
      diagram_td = any_all.append_right(diagram_td, '')
      diagram_td.append_right(repeat_td, '')
    end

    private

    def double_enumerate(seq)
      length = seq.length
      seq.each_with_index.map { |item, i| [i, i - length, item] }
    end
  end
end
