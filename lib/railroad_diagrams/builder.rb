# frozen_string_literal: true

module RailroadDiagrams
  module Coercion
    def self.call(value, options = nil)
      rule = if options.is_a?(Proc)
               options
             elsif options.respond_to?(:coerce)
               options.coerce
             elsif options.is_a?(Hash)
               options[:coerce]
             end
      unless rule.nil?
        raise InvalidArgument, 'coerce must be callable' unless rule.respond_to?(:call)

        converted = rule.call(value)
        return converted if converted.is_a?(DiagramItem)
        raise InvalidArgument, 'coerce must return a DiagramItem or nil' unless converted.nil?
      end

      case value
      when DiagramItem then value
      when String then Terminal.new(value)
      when Symbol then NonTerminal.new(value.to_s)
      when nil then Skip.new
      when Array then Sequence.new(*value.map { |item| call(item, options) })
      else raise InvalidArgument, "cannot coerce #{value.class} to a diagram item"
      end
    end
  end

  module DSL
    def diagram(*items, **options)
      Diagram.new(*items.map { |item| coerce(item) }, **options)
    end

    def t(text, **options)
      Terminal.new(text.to_s, **options)
    end
    alias terminal t

    def nt(text, **options)
      NonTerminal.new(text.to_s, **options)
    end
    alias non_terminal nt

    def comment(text, **options)
      Comment.new(text.to_s, **options)
    end

    def seq(*items)
      Sequence.new(*items.map { |item| coerce(item) })
    end

    def stack(*items)
      Stack.new(*items.map { |item| coerce(item) })
    end

    def choice(*items, default: 0)
      Choice.new(default, *items.map { |item| coerce(item) })
    end

    def hchoice(*items)
      HorizontalChoice.new(*items.map { |item| coerce(item) })
    end

    def mchoice(type, *items, default: 0)
      MultipleChoice.new(default, type.to_s, *items.map { |item| coerce(item) })
    end

    def opt(item, skip: false)
      Optional.new(coerce(item), skip: skip)
    end

    def zero_or_more(item, sep = nil, skip: false)
      ZeroOrMore.new(coerce(item), sep.nil? ? nil : coerce(sep), skip: skip)
    end

    def one_or_more(item, sep = nil)
      OneOrMore.new(coerce(item), sep.nil? ? nil : coerce(sep))
    end

    def oseq(*items)
      OptionalSequence.new(*items.map { |item| coerce(item) })
    end

    def alt(first, second)
      AlternatingSequence.new(coerce(first), coerce(second))
    end

    def group(item, label = nil, **options)
      raise InvalidArgument, 'unknown group option' unless (options.keys - [:label]).empty?
      raise InvalidArgument, 'label specified twice' if !label.nil? && options.key?(:label)

      label = options[:label] if options.key?(:label)
      Group.new(coerce(item), label: label.is_a?(String) || label.nil? ? label : coerce(label))
    end

    def skip
      Skip.new
    end

    def repeat(item, **options)
      options[:separator] = coerce(options[:separator]) if options.key?(:separator) && !options[:separator].nil?
      Repeat.new(coerce(item), **options)
    end

    def list(item, sep: ',', **options)
      SeparatedList.new(coerce(item), coerce(sep), **options)
    end

    def except(item, excluded, **options)
      Except.new(coerce(item), excluded.is_a?(String) ? excluded : coerce(excluded), **options)
    end

    def block(**options)
      Block.new(**options)
    end

    def char_class(text, **options)
      CharClass.new(text.to_s, **options)
    end

    def special(text, **options)
      Special.new(text.to_s, **options)
    end

    private

    def coerce(value)
      Coercion.call(value, @coercion)
    end
  end

  class Builder
    include DSL

    attr_reader :coercion

    def initialize(coerce: nil)
      @coercion = if coerce.nil? && RailroadDiagrams.default_options.respond_to?(:coerce)
                    RailroadDiagrams.default_options.coerce
                  else
                    coerce
                  end
    end
  end

  def self.build(coerce: nil, &block)
    raise InvalidArgument, 'a block is required' unless block

    builder = Builder.new(coerce: coerce)
    value = block.arity.zero? ? builder.instance_eval(&block) : block.call(builder)
    Coercion.call(value, builder.coercion)
  end

  def self.diagram(**options, &block)
    coerce = options.delete(:coerce)
    Diagram.new(build(coerce: coerce, &block), **options)
  end
end
