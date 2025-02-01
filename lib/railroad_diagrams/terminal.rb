# frozen_string_literal: true

module RailroadDiagrams
  class Terminal < DiagramItem
    def initialize(text, href = nil, title = nil, cls: '')
      super('g', attrs: { 'class' => "terminal #{cls}" })
      @text = text
      @href = href
      @title = title
      @cls = cls
      @width = (text.length * CHAR_WIDTH) + 20
      @up = 11
      @down = 11
      @needs_space = true
    end

    def to_s
      "Terminal(#{@text}, href=#{@href}, title=#{@title}, cls=#{@cls})"
    end

    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)

      # Hook up the two sides if self is narrower than its stated width.
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y).h(right_gap).add(self)

      DiagramItem.new(
        'rect',
        attrs: {
          'x' => x + left_gap,
          'y' => y - 11,
          'width' => @width,
          'height' => @up + @down,
          'rx' => 10,
          'ry' => 10
        }
      ).add(self)

      text = DiagramItem.new(
        'text',
        attrs: {
          'x' => x + left_gap + (@width / 2),
          'y' => y + 4
        },
        text: @text
      )
      if @href
        a = DiagramItem.new('a', attrs: { 'xlink:href' => @href }, text: text).add(self)
        text.add(a)
      else
        text.add(self)
      end
      DiagramItem.new('title', attrs: {}, text: @title).add(self) if @title
      self
    end

    def text_diagram
      # NOTE: href, title, and cls are ignored for text diagrams.
      TextDiagram.round_rect(@text)
    end
  end
end
