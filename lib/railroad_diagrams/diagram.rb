# frozen_string_literal: true

module RailroadDiagrams
  class Diagram < DiagramMultiContainer
    def initialize(*items, **kwargs)
      super('svg', items.to_a, { 'class' => DIAGRAM_CLASS })
      @type = kwargs.fetch(:type, 'simple')

      if @items.any?
        @items.unshift(Start.new(@type)) unless @items.first.is_a?(Start)
        @items.push(End.new(@type)) unless @items.last.is_a?(End)
      end

      @up = 0
      @down = 0
      @height = 0
      @width = 0

      @items.each do |item|
        next if item.is_a?(Style)

        @width += item.width + (item.needs_space ? 20 : 0)
        @up = [@up, item.up - @height].max
        @height += item.height
        @down = [@down - item.height, item.down].max
      end

      @width -= 10 if @items[0].needs_space
      @width -= 10 if @items[-1].needs_space
      @formatted = false
    end

    def to_s
      items = items.map(&:to_s).join(', ')
      pieces = items ? [items] : []
      pieces.push("type=#{@type}") if @type != 'simple'
      "Diagram(#{pieces.join(', ')})"
    end

    def format(padding_top = 20, padding_right = nil, padding_bottom = nil, padding_left = nil)
      padding_right = padding_top if padding_right.nil?
      padding_bottom = padding_top if padding_bottom.nil?
      padding_left = padding_right if padding_left.nil?

      x = padding_left
      y = padding_top + @up
      g = DiagramItem.new('g')
      g.attrs['transform'] = 'translate(.5 .5)' if STROKE_ODD_PIXEL_LENGTH

      @items.each do |item|
        if item.needs_space
          Path.new(x, y).h(10).add(g)
          x += 10
        end
        item.format(x, y, item.width).add(g)
        x += item.width
        y += item.height
        if item.needs_space
          Path.new(x, y).h(10).add(g)
          x += 10
        end
      end

      @attrs['width'] = (@width + padding_left + padding_right).to_s
      @attrs['height'] = (@up + @height + @down + padding_top + padding_bottom).to_s
      @attrs['viewBox'] = "0 0 #{@attrs['width']} #{@attrs['height']}"
      g.add(self)
      @formatted = true
      self
    end

    def text_diagram
      separator, = TextDiagram.get_parts(['separator'])
      diagram_td = items[0].text_diagram
      items[1..].each do |item|
        item_td = item.text_diagram
        item_td.expand(1, 1, 0, 0) if item.needs_space
        diagram_td = diagram_td.append_right(separator)
      end
    end

    def write_svg(write)
      format unless @formatted

      super
    end

    def write_text(_write)
      output = text_diagram
      output = "#{output.lines.join("\n")}\n"
      output = output.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;') if ESCAPE_HTML
      write(output)
    end

    def write_standalone(write, css = nil)
      format unless @formatted
      css = Style.default_style if css
      Style.new(css).add(self)
      @attrs['xmlns'] = 'http://www.w3.org/2000/svg'
      @attrs['xmlns:xlink'] = 'http://www.w3.org/1999/xlink'
      DiagramItem.write_svg(write)
      @children.pop
      @attrs.delete('xmlns')
      @attrs.delete('xmlns:xlink')
    end
  end
end
