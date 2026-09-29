# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Terminal < DiagramItem
    # @rbs text: String
    # @rbs href: String?
    # @rbs title: String?
    # @rbs cls: String
    # @rbs return: void
    def initialize(text, href = nil, title = nil, cls: '')
      super('g', attrs: { 'class' => "terminal #{cls}" })
      @text = text.to_s
      @href = href
      @title = title
      @cls = cls
      @width = (Unicode::DisplayWidth.of(@text) * CHAR_WIDTH) + 20
      @up = 11
      @down = 11
      @needs_space = true
    end

    # @rbs return: String
    def to_s
      "Terminal(#{@text}, href=#{@href}, title=#{@title}, cls=#{@cls})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Terminal
    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      add_connecting_paths(x, y, left_gap, right_gap)
      add_background_rect(x + left_gap, y)
      add_text_element(x + left_gap, y)
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      TextDiagram.round_rect(@text)
    end

    def measure(context)
      Metrics.new(width: context.text_width(@text, :label) + 20,
                  up: 11, height: 0, down: 11, needs_space: true)
    end

    def render_svg(context, x, y, width)
      metrics = context.metrics(self)
      left_gap, right_gap = context.gaps(width, metrics.width)
      group = Svg::Element.new('g', @attrs.dup)
      group << (Svg::Element.new('title') << Svg::TextNode.new(@title)) if @title
      group << Svg::Element.new('path', { 'd' => Svg::PathData.new(x, y).h(left_gap) }, self_closing: true)
      group << Svg::Element.new('path', { 'd' => Svg::PathData.new(x + left_gap + metrics.width, y).h(right_gap) }, self_closing: true)
      rect = { 'x' => x + left_gap, 'y' => y - 11, 'width' => metrics.width,
               'height' => 22, 'rx' => context.options.arc_radius, 'ry' => context.options.arc_radius }
      group << Svg::Element.new('rect', rect)
      text = Svg::Element.new('text', { 'x' => x + left_gap + (metrics.width / 2), 'y' => y + 4 })
      text << Svg::TextNode.new(@text)
      if (attrs = context.link_attrs(@href))
        link = Svg::Element.new('a', attrs)
        link << text
        group << link
      else
        group << text
      end
      group
    end

    def render_text(context)
      TextDiagram.round_rect(@text, parts: context.parts)
    end

    def child_nodes
      []
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
    def add_background_rect(x, y)
      DiagramItem.new(
        'rect',
        attrs: {
          'x' => x,
          'y' => y - 11,
          'width' => @width,
          'height' => @up + @down,
          'rx' => 10,
          'ry' => 10
        }
      ).add(self)
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs return: void
    def add_text_element(x, y)
      text = DiagramItem.new(
        'text',
        attrs: { 'x' => x + (@width / 2), 'y' => y + 4 },
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
