# frozen_string_literal: true

module RailroadDiagrams
  # @private
  module Coercion
    # @private
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

  # Helpers for building node trees with short grammar expressions.
  # @example
  #   RailroadDiagrams.build { seq('SELECT', :column) }
  module DSL
    # @example
    #   diagram('a', :rule)
    def diagram(*items, **options)
      Diagram.new(*items.map { |item| coerce(item) }, **options)
    end

    # @example
    #   t('SELECT')
    def t(text, **options)
      Terminal.new(text.to_s, **options)
    end
    alias terminal t

    # @example
    #   nt('expression')
    def nt(text, **options)
      NonTerminal.new(text.to_s, **options)
    end
    alias non_terminal nt

    # @example
    #   comment('optional')
    def comment(text, **options)
      Comment.new(text.to_s, **options)
    end

    # @example
    #   seq('SELECT', :column)
    def seq(*items)
      Sequence.new(*items.map { |item| coerce(item) })
    end

    # @example
    #   stack('first', 'second')
    def stack(*items)
      Stack.new(*items.map { |item| coerce(item) })
    end

    # @example
    #   choice('yes', 'no', default: 1)
    def choice(*items, default: 0)
      Choice.new(default, *items.map { |item| coerce(item) })
    end

    # @example
    #   hchoice('yes', 'no')
    def hchoice(*items)
      HorizontalChoice.new(*items.map { |item| coerce(item) })
    end

    # @example
    #   mchoice('any', 'a', 'b')
    def mchoice(type, *items, default: 0)
      MultipleChoice.new(default, type.to_s, *items.map { |item| coerce(item) })
    end

    # @example
    #   opt('DISTINCT')
    def opt(item, skip: false)
      Optional.new(coerce(item), skip: skip)
    end

    # @example
    #   zero_or_more('digit', ',')
    def zero_or_more(item, sep = nil, skip: false)
      ZeroOrMore.new(coerce(item), sep.nil? ? nil : coerce(sep), skip: skip)
    end

    # @example
    #   one_or_more('digit', ',')
    def one_or_more(item, sep = nil)
      OneOrMore.new(coerce(item), sep.nil? ? nil : coerce(sep))
    end

    # @example
    #   oseq('a', 'b')
    def oseq(*items)
      OptionalSequence.new(*items.map { |item| coerce(item) })
    end

    # @example
    #   alt('a', 'b')
    def alt(first, second)
      AlternatingSequence.new(coerce(first), coerce(second))
    end

    # @example
    #   group('a', label: 'group')
    def group(item, label = nil, **options)
      raise InvalidArgument, 'unknown group option' unless (options.keys - [:label]).empty?
      raise InvalidArgument, 'label specified twice' if !label.nil? && options.key?(:label)

      label = options[:label] if options.key?(:label)
      Group.new(coerce(item), label: label.is_a?(String) || label.nil? ? label : coerce(label))
    end

    # @example
    #   skip
    def skip
      Skip.new
    end

    # @example
    #   repeat('digit', min: 2, max: 4)
    def repeat(item, **options)
      options[:separator] = coerce(options[:separator]) if options.key?(:separator) && !options[:separator].nil?
      Repeat.new(coerce(item), **options)
    end

    # @example
    #   list(:column, sep: ',')
    def list(item, sep: ',', **options)
      SeparatedList.new(coerce(item), coerce(sep), **options)
    end

    # @example
    #   except('letter', 'x')
    def except(item, excluded, **options)
      Except.new(coerce(item), excluded.is_a?(String) ? excluded : coerce(excluded), **options)
    end

    # @example
    #   block(width: 40)
    def block(**options)
      Block.new(**options)
    end

    # @example
    #   char_class('[a-z]')
    def char_class(text, **options)
      CharClass.new(text.to_s, **options)
    end

    # @example
    #   special('EOF')
    def special(text, **options)
      Special.new(text.to_s, **options)
    end

    private

    def coerce(value)
      Coercion.call(value, @coercion)
    end
  end

  # Executes DSL expressions with configurable value coercion.
  # @example
  #   Builder.new.seq('SELECT', :column)
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

  # Evaluate a DSL block and return its root node.
  # @example
  #   RailroadDiagrams.build { seq('SELECT', :column) }
  def self.build(coerce: nil, &block)
    raise InvalidArgument, 'a block is required' unless block

    builder = Builder.new(coerce: coerce)
    value = block.arity.zero? ? builder.instance_eval(&block) : block.call(builder)
    Coercion.call(value, builder.coercion)
  end

  # Evaluate a DSL block and wrap it in a complete diagram.
  # @example
  #   RailroadDiagrams.diagram(theme: :dark) { seq('SELECT', :column) }
  def self.diagram(**options, &block)
    coerce = options.delete(:coerce)
    Diagram.new(build(coerce: coerce, &block), **options)
  end
end
