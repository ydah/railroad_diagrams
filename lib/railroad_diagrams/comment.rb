# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Comment < DiagramItem
    # @rbs text: String
    # @rbs href: String?
    # @rbs title: String?
    # @rbs cls: String
    # @rbs return: void
    def initialize(text, href = nil, title = nil, cls: '')
      super('g', attrs: { 'class' => "non-terminal #{cls}" })
      @text = text
      @href = href
      @title = title
      @cls = cls
      @width = (text.length * COMMENT_CHAR_WIDTH) + 10
      @up = 8
      @down = 8
      @needs_space = true
    end

    # @rbs return: String
    def to_s
      "Comment(#{@text}, href=#{@href}, title=#{@title}, cls=#{@cls})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs _width: Numeric
    # @rbs return: Comment
    def format(x, y, _width)
      left_gap, right_gap = determine_gaps(width, @width)

      # Hook up the two sides if self is narrower than its stated width.
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y).h(right_gap).add(self)

      text = DiagramItem.new(
        'text',
        attrs: { 'x' => x + left_gap + (@width / 2), 'y' => y + 4, 'class' => 'comment' },
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

    # @rbs return: TextDiagram
    def text_diagram
      # NOTE: href, title, and cls are ignored for text diagrams.
      TextDiagram.new(0, 0, [@text])
    end
  end
end
