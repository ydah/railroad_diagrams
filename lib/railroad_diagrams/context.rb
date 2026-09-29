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
