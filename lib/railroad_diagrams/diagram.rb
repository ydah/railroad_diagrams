# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Diagram < DiagramMultiContainer
    # @rbs *items: (DiagramItem | String)
    # @rbs type: String
    # @rbs return: void
    def initialize(*items, type: 'simple', **unknown)
      raise InvalidArgument, "unknown option(s): #{unknown.keys.join(', ')}" unless unknown.empty?
      raise InvalidArgument, "unknown diagram type: #{type.inspect}" unless %w[simple complex].include?(type)

      super('svg', items.to_a, { 'class' => DIAGRAM_CLASS })
      @type = type
      @formatted = false

      ensure_start_and_end_items
      calculate_dimensions
    end

    # @rbs return: String
    def to_s
      items = @items.map(&:to_s).join(', ')
      pieces = items.empty? ? [] : [items]
      pieces.push("type=#{@type}") if @type != 'simple'
      "Diagram(#{pieces.join(', ')})"
    end

    # @rbs padding_top: Numeric
    # @rbs padding_right: Numeric?
    # @rbs padding_bottom: Numeric?
    # @rbs padding_left: Numeric?
    # @rbs return: Diagram
    def format(padding_top = 20, padding_right = nil, padding_bottom = nil, padding_left = nil)
      padding_right ||= padding_top
      padding_bottom ||= padding_top
      padding_left ||= padding_right

      g = create_group_element
      format_items_into_group(g, padding_left, padding_top)
      set_svg_attributes(padding_top, padding_right, padding_bottom, padding_left)
      g.add(self)
      @formatted = true
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      return TextDiagram.new(0, 0, []) if @items.empty?

      separator, = TextDiagram.get_parts(['separator'])
      render_items = @items.reject { |item| item.is_a?(Style) }
      diagram_td = render_items[0].text_diagram
      render_items[1..-1].each do |item|
        item_td = item.text_diagram
        item_td = item_td.expand(1, 1, 0, 0) if item.needs_space
        diagram_td = diagram_td.append_right(item_td, separator)
      end
      diagram_td
    end

    # @rbs write: ^(String) -> void
    # @rbs return: void
    def write_svg(write)
      format unless @formatted

      super
    end

    # @rbs write: untyped
    # @rbs escape_html: bool
    # @rbs return: void
    def write_text(write, escape_html: true)
      write = Writer.wrap(write)
      output = text_diagram
      output = "#{output.lines.join("\n")}\n"
      output = output.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;') if escape_html
      write.call(output)
    end

    # @rbs return: String
    def to_svg
      out = +''
      write_svg(out)
      out
    end

    # @rbs css: (String | bool)?
    # @rbs return: String
    def to_standalone_svg(css: nil)
      out = +''
      write_standalone(out, css)
      out
    end

    # @rbs charset: Symbol
    # @rbs escape_html: bool
    # @rbs return: String
    def to_text(charset: :unicode, escape_html: false)
      parts = { unicode: TextDiagram::PARTS_UNICODE, ascii: TextDiagram::PARTS_ASCII }.fetch(charset) do
        raise InvalidArgument, "unknown charset: #{charset.inspect}"
      end
      previous = TextDiagram.parts
      TextDiagram.set_formatting(parts)
      output = "#{text_diagram.lines.join("\n")}\n"
      escape_html ? output.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;') : output
    ensure
      TextDiagram.parts = previous if defined?(previous)
    end

    # @rbs write: ^(String) -> void
    # @rbs css: String?
    # @rbs return: void
    def write_standalone(write, css = nil)
      format unless @formatted
      style = add_style_and_namespaces(css)
      begin
        super(write)
      ensure
        cleanup_standalone_artifacts(style)
      end
    end

    private

    # @rbs return: void
    def ensure_start_and_end_items
      return unless @items.any?

      @items.unshift(Start.new(@type)) unless @items.first.is_a?(Start)
      @items.push(End.new(@type)) unless @items.last.is_a?(End)
    end

    # @rbs return: void
    def calculate_dimensions
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

      @width -= 10 if @items.first&.needs_space
      @width -= 10 if @items.last&.needs_space
    end

    # @rbs return: DiagramItem
    def create_group_element
      g = DiagramItem.new('g')
      g.attrs['transform'] = 'translate(.5 .5)' if STROKE_ODD_PIXEL_LENGTH
      g
    end

    # @rbs g: DiagramItem
    # @rbs padding_left: Numeric
    # @rbs padding_top: Numeric
    # @rbs return: void
    def format_items_into_group(g, padding_left, padding_top)
      x = padding_left
      y = padding_top + @up

      @items.each do |item|
        if item.is_a?(Style)
          item.add(self)
          next
        end

        x = add_leading_spacing(x, y, item, g)
        item.format(x, y, item.width).add(g)
        x += item.width
        y += item.height
        x = add_trailing_spacing(x, y, item, g)
      end
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs item: DiagramItem
    # @rbs g: DiagramItem
    # @rbs return: Numeric
    def add_leading_spacing(x, y, item, g)
      return x unless item.needs_space

      Path.new(x, y).h(10).add(g)
      x + 10
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs item: DiagramItem
    # @rbs g: DiagramItem
    # @rbs return: Numeric
    def add_trailing_spacing(x, y, item, g)
      return x unless item.needs_space

      Path.new(x, y).h(10).add(g)
      x + 10
    end

    # @rbs padding_top: Numeric
    # @rbs padding_right: Numeric
    # @rbs padding_bottom: Numeric
    # @rbs padding_left: Numeric
    # @rbs return: void
    def set_svg_attributes(padding_top, padding_right, padding_bottom, padding_left)
      @attrs['width'] = (@width + padding_left + padding_right).to_s
      @attrs['height'] = (@up + @height + @down + padding_top + padding_bottom).to_s
      @attrs['viewBox'] = "0 0 #{@attrs['width']} #{@attrs['height']}"
    end

    # css: nil / true => 既定CSS、false => <style> なし、String => そのCSS
    # @rbs css: (String | bool)?
    # @rbs return: Style?
    def add_style_and_namespaces(css)
      css = Style.default_style if css.nil? || css == true
      style = css ? Style.new(css).add(self) : nil
      @attrs['xmlns'] = 'http://www.w3.org/2000/svg'
      @attrs['xmlns:xlink'] = 'http://www.w3.org/1999/xlink'
      style
    end

    # @rbs style: Style?
    # @rbs return: void
    def cleanup_standalone_artifacts(style)
      @children.delete_at(@children.rindex { |c| c.equal?(style) }) if style
      @attrs.delete('xmlns')
      @attrs.delete('xmlns:xlink')
    end

    # @rbs value: DiagramItem | Style | String
    # @rbs return: DiagramItem | Style
    def wrap_string(value)
      value.is_a?(Style) ? value : super
    end
  end
end
