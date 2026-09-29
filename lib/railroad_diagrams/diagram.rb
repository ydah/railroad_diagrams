# rbs_inline: enabled
# frozen_string_literal: true

require 'digest/sha1'

module RailroadDiagrams
  class Diagram < DiagramMultiContainer
    # @rbs *items: (DiagramItem | String)
    # @rbs type: String
    # @rbs return: void
    def initialize(*items, type: 'simple', title: nil, desc: nil, **unknown)
      raise InvalidArgument, "unknown option(s): #{unknown.keys.join(', ')}" unless unknown.empty?
      raise InvalidArgument, "unknown diagram type: #{type.inspect}" unless %w[simple complex].include?(type)
      raise InvalidArgument, 'title must be a String' if title && !title.is_a?(String)
      raise InvalidArgument, 'desc must be a String or :auto' if desc && !desc.is_a?(String) && desc != :auto

      super('svg', items.to_a, { 'class' => DIAGRAM_CLASS })
      @type = type
      @title = title
      @desc = desc
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
      render_text(Context.legacy)
    end

    def measure(context)
      up = 0
      down = 0
      height = 0
      width = 0
      children = visible_nodes(context).map { |item| context.metrics(item) }
      children.each do |item|
        width += item.width + (item.needs_space ? 20 : 0)
        up = [up, item.up - height].max
        height += item.height
        down = [down - item.height, item.down].max
      end
      width -= 10 if children.first&.needs_space
      width -= 10 if children.last&.needs_space
      Metrics.new(width: width, up: up, height: height, down: down, needs_space: false)
    end

    # rubocop:disable-next Metrics/ParameterLists
    def render_svg(context, _x = 0, _y = 0, _width = nil, padding_top: 20, padding_right: nil,
                   padding_bottom: nil, padding_left: nil)
      padding_right ||= padding_top
      padding_bottom ||= padding_top
      padding_left ||= padding_right
      metrics = context.metrics(self)
      svg_width = metrics.width + padding_left + padding_right
      svg_height = metrics.up + metrics.height + metrics.down + padding_top + padding_bottom
      precision = context.options.precision
      rendered_width = precision ? Svg::NumberFormat.call(svg_width, precision) : svg_width.to_s
      rendered_height = precision ? Svg::NumberFormat.call(svg_height, precision) : svg_height.to_s
      attrs = @attrs.merge('class' => context.options.diagram_class,
                           'width' => rendered_width, 'height' => rendered_height,
                           'viewBox' => "0 0 #{rendered_width} #{rendered_height}")
      root = Svg::Element.new('svg', attrs)
      add_accessible_name(root, context) if @title || @desc
      @items.each { |item| root << item.render_svg(context) if item.is_a?(Style) }
      group_attrs = context.options.stroke_odd_pixel_length ? { 'transform' => 'translate(.5 .5)' } : {}
      group = Svg::Element.new('g', group_attrs)
      x = padding_left
      y = padding_top + metrics.up
      nodes = visible_nodes(context)
      nodes.each_with_index do |item, index|
        child = context.metrics(item)
        if child.needs_space && index.positive?
          group << svg_path(x, y, 10)
          x += 10
        end
        group << item.render_svg(context, x, y, child.width)
        x += child.width
        y += child.height
        if child.needs_space && index < nodes.length - 1
          group << svg_path(x, y, 10)
          x += 10
        end
      end
      root << group
      root.attrs['xmlns:xlink'] = 'http://www.w3.org/1999/xlink' if context.uses_xlink
      root
    end

    def render_text(context)
      render_items = visible_nodes(context)
      return TextDiagram.new(0, 0, []) if render_items.empty?

      diagrams = render_items.each_with_index.map do |item, index|
        diagram = item.render_text(context)
        if context.metrics(item).needs_space
          diagram.expand(index.positive? ? 1 : 0, index < render_items.length - 1 ? 1 : 0, 0, 0)
        else
          diagram
        end
      end
      Text::Builder.row(diagrams, context.parts.fetch('separator'))
    end

    def child_nodes
      @items.reject { |item| item.is_a?(Style) }
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
    def to_svg(**options)
      context = Context.new(RailroadDiagrams.default_options.merge(**options))
      Svg::Serializer.call(render_svg(context), precision: context.options.precision,
                                                optimize_paths: context.options.optimize_paths)
    end

    # @rbs css: (String | bool)?
    # @rbs css_variables: bool
    # @rbs **options: untyped
    # @rbs return: String
    def to_standalone_svg(css: nil, css_variables: false, **options)
      context = Context.new(RailroadDiagrams.default_options.merge(**options))
      root = render_svg(context)
      root.attrs['xmlns'] = 'http://www.w3.org/2000/svg'
      root.attrs['xmlns:xlink'] = 'http://www.w3.org/1999/xlink'
      css = Theme[context.options.theme].css(css_variables: css_variables) if css.nil? || css == true
      root << Svg::StyleText.new(css) if css
      Svg::Serializer.call(root, precision: context.options.precision, optimize_paths: context.options.optimize_paths)
    end

    # @rbs charset: Symbol
    # @rbs escape_html: bool
    # @rbs strip_trailing: bool
    # @rbs **options: untyped
    # @rbs return: String
    def to_text(charset: :unicode, escape_html: false, strip_trailing: false, **options)
      options[:text_charset] = charset
      context = Context.new(RailroadDiagrams.default_options.merge(**options))
      lines = render_text(context).lines
      lines = lines.map(&:rstrip) if strip_trailing
      output = "#{lines.join("\n")}\n"
      escape_html ? output.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;') : output
    end

    # @rbs **options: untyped
    # @rbs return: String
    def to_markdown(**options)
      output = to_text(**options)
      fence = '`' * [3, output.scan(/`+/).map(&:length).max.to_i + 1].max
      "#{fence}text\n#{output}#{fence}\n"
    end

    # @rbs title: String
    # @rbs charset: Symbol
    # @rbs **options: untyped
    # @rbs return: String
    def to_html(title: 'Railroad diagram', charset: :unicode, **options)
      raise InvalidArgument, 'title must be a String' unless title.is_a?(String)

      locale = options.fetch(:locale, RailroadDiagrams.default_options.locale)
      I18n.t(:describe_truncated, locale: locale)
      css = Theme[options.fetch(:theme, RailroadDiagrams.default_options.theme)].css(css_variables: false)
      escaped_title = RailroadDiagrams.escape_html(title)
      text_options = options.dup
      text_options[:charset] = charset
      text_options[:escape_html] = true
      text = to_text(**text_options)
      <<~HTML
        <!doctype html>
        <html lang="#{RailroadDiagrams.escape_attr(locale.to_s)}">
        <head><meta charset="utf-8" /><title>#{escaped_title}</title><style>#{css}</style></head>
        <body><main><h1>#{escaped_title}</h1>#{to_svg(**options)}<details><summary>Text diagram</summary><pre>#{text}</pre></details></main></body>
        </html>
      HTML
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

    def visible_nodes(context)
      @items.reject do |item|
        item.is_a?(Style) || (item.is_a?(Start) && !context.options.show_start) ||
          (item.is_a?(End) && !context.options.show_end)
      end
    end

    def add_accessible_name(root, context)
      source = [to_s, @title, @desc].join("\0")
      prefix = context.options.id_prefix || "rr-#{Digest::SHA1.hexdigest(source)[0, 8]}-"
      ids = IdGenerator.new(prefix)
      labels = []
      if @title
        id = ids.next
        root << Svg::Element.new('title', { 'id' => id }, [Svg::TextNode.new(@title)])
        labels << id
      end
      if @desc
        id = ids.next
        description = @desc == :auto ? A11y::Describer.call(self, locale: context.options.locale) : @desc
        root << Svg::Element.new('desc', { 'id' => id }, [Svg::TextNode.new(description)])
        labels << id
      end
      root.attrs['role'] = 'img'
      root.attrs['aria-labelledby'] = labels.join(' ')
    end

    def svg_path(x, y, length)
      Svg::Element.new('path', { 'd' => Svg::PathData.new(x, y).h(length) }, self_closing: true)
    end

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
