# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class IdGenerator
    def initialize(prefix)
      @prefix = prefix || 'rr'
      @next = 0
    end

    def next
      @next += 1
      "#{@prefix}#{@next}"
    end
  end

  class Context
    attr_reader :options, :measurer, :parts, :ids, :uses_xlink

    def initialize(options = RailroadDiagrams.default_options, parts: nil)
      if options.id_prefix && (!options.id_prefix.is_a?(String) || !/\A[A-Za-z_][\w.-]*\z/.match?(options.id_prefix))
        raise InvalidArgument, 'id_prefix must be a valid SVG identifier prefix'
      end

      @options = options
      @measurer = options.measurer || Measurer::Monospace.new(options)
      @parts = (parts || Text::Parts.for(options.text_charset)).dup.freeze
      @ids = IdGenerator.new(options.id_prefix)
      @metrics = {}.compare_by_identity
      @warned_link = false
      @uses_xlink = false
    end

    def self.legacy
      new(RailroadDiagrams.default_options, parts: TextDiagram.parts)
    end

    def metrics(node)
      @metrics[node] ||= node.measure(self)
    end

    def render_svg(node, x, y, width)
      element = node.render_svg(self, x, y, width)
      apply_node_attributes(element, node)
      return element unless @options.debug

      size = metrics(node)
      bounds_attrs = {
        'class' => 'debug-bounds', 'x' => x, 'y' => y - size.up,
        'width' => width, 'height' => size.up + size.height + size.down,
        'style' => 'fill:none;stroke:red;stroke-width:1;stroke-dasharray:3 2;pointer-events:none'
      }
      bounds = Svg::Element.new('rect', bounds_attrs, self_closing: true)
      wrapper_attrs = {
        'data-type' => node.class.name.split('::').last,
        'data-updown' => "#{size.up} #{size.height} #{size.down}"
      }
      Svg::Element.new('g', wrapper_attrs) << element << bounds
    end

    def apply_node_attributes(element, node)
      node.attrs.each do |name, value|
        next unless name == 'id' || name == 'class' || name.start_with?('data-')

        element.attrs[name] = name == 'id' && @options.id_prefix ? "#{@options.id_prefix}#{value}" : value
      end
      element
    end

    def text_width(text, role = :label)
      @measurer.respond_to?(:width) ? @measurer.width(text, role) : @measurer.call(text, role)
    end

    def gaps(outer, inner)
      difference = outer - inner
      case @options.internal_alignment
      when :left then [0, difference]
      when :right then [difference, 0]
      else
        half = difference.is_a?(Integer) && difference.odd? ? difference / 2.0 : difference / 2
        [half, half]
      end
    end

    def link_attrs(url)
      return nil unless url

      unless LinkPolicy.allowed?(url, policy: @options.link_policy)
        case @options.link_policy_violation
        when :raise then raise InvalidArgument, 'rejected link URL'
        when :warn
          warn 'railroad_diagrams: rejected link URL' unless @warned_link
          @warned_link = true
        else raise InvalidArgument, "unknown link policy violation: #{@options.link_policy_violation.inspect}"
        end
        return nil
      end

      attrs = case @options.href_mode
              when :xlink then { 'xlink:href' => url }
              when :href then { 'href' => url }
              when :both then { 'href' => url, 'xlink:href' => url }
              else raise InvalidArgument, "unknown href mode: #{@options.href_mode.inspect}"
              end
      @uses_xlink = true if attrs.key?('xlink:href')
      attrs['target'] = @options.link_target if @options.link_target
      rel = [@options.link_rel, (@options.link_target == '_blank' ? 'noopener noreferrer' : nil)].compact.join(' ')
      attrs['rel'] = rel.split.uniq.join(' ') unless rel.empty?
      attrs
    end
  end
end
