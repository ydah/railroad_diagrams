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
    attr_reader :options, :measurer, :parts, :ids

    def initialize(options = RailroadDiagrams.default_options, parts: nil)
      @options = options
      @measurer = options.measurer || Measurer::Monospace.new(options)
      @parts = (parts || Text::Parts.for(options.text_charset)).dup.freeze
      @ids = IdGenerator.new(options.id_prefix)
      @metrics = {}.compare_by_identity
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
  end
end
