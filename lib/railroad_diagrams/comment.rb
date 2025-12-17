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
      add_connecting_paths(x, y, left_gap, right_gap)
      add_text_element(x + left_gap, y)
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      TextDiagram.new(0, 0, [@text])
    end

    private

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs left_gap: Numeric
    # @rbs right_gap: Numeric
    # @rbs return: void
    def add_connecting_paths(x, y, left_gap, right_gap)
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y).h(right_gap).add(self)
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs return: void
    def add_text_element(x, y)
      text = DiagramItem.new(
        'text',
        attrs: { 'x' => x + (@width / 2), 'y' => y + 4, 'class' => 'comment' },
        text: @text
      )

      if @href
        a = DiagramItem.new('a', attrs: { 'xlink:href' => @href }, text: text).add(self)
        text.add(a)
      else
        text.add(self)
      end

      DiagramItem.new('title', attrs: {}, text: @title).add(self) if @title
    end
  end
end
