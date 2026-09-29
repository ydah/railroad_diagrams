# frozen_string_literal: true

require 'psych'
require 'railroad_diagrams'

module RailroadDiagrams
  module Importers
    class YamlGrammar
      OPERATORS = %w[choice optional zero_or_more one_or_more repeat list group comment stack hchoice oseq alt except].freeze
      ARRAYS = { 'stack' => Stack, 'hchoice' => HorizontalChoice,
                 'oseq' => OptionalSequence, 'alt' => AlternatingSequence }.freeze

      def self.parse(source, filename: '<yaml>')
        new(source, filename).parse
      end

      def initialize(source, filename)
        @source = source
        @filename = filename || '<yaml>'
        @lines = source.is_a?(String) ? source.lines : []
      end

      def parse
        raise ParseError, 'YAML source must be a string' unless @source.is_a?(String)

        value = if Psych::VERSION.to_i >= 4
                  Psych.safe_load(@source, permitted_classes: [], aliases: false)
                else
                  Psych.safe_load(@source, [], [], false)
                end
        root = (Psych::VERSION.to_i >= 4 ? Psych.parse(@source, filename: @filename) : Psych.parse(@source, @filename))&.root
        fields = mapping(value, root, %w[title rules])
        title = fields['title'] && string(*fields['title'], 'title')
        rules = fields['rules'] || fail_at(root, 'missing rules')
        entries = mapping(*rules)
        document = title ? Document.new(title: title) : Document.new
        entries.each do |name, (rule, node)|
          fail_at(node, 'rule name must not be empty') if name.empty?

          document.add_rule(name, build(rule, node))
        end
        document
      rescue Psych::Exception => e
        raise_parse_error(e)
      end

      private

      def mapping(value, node, allowed = nil)
        fail_at(node, 'expected a mapping') unless value.is_a?(Hash) && node.is_a?(Psych::Nodes::Mapping)
        fail_at(node, 'mapping keys must be strings') unless value.keys.all?(String)

        result = {}
        node.children.each_slice(2) do |key_node, value_node|
          key = key_node.value
          fail_at(key_node, 'mapping keys must be strings') unless key_node.is_a?(Psych::Nodes::Scalar) && value.key?(key)
          fail_at(key_node, "duplicate key: #{key}") if result.key?(key)
          fail_at(key_node, "unknown key: #{key}") if allowed && !allowed.include?(key)

          result[key] = [value.fetch(key), value_node]
        end
        result
      end

      def build(value, node)
        case value
        when nil then Skip.new
        when String then scalar(value)
        when Array
          fail_at(node, 'expected a sequence') unless node.is_a?(Psych::Nodes::Sequence)

          Sequence.new(*value.zip(node.children).map { |child, child_node| build(child, child_node) })
        when Hash then build_operator(value, node)
        else fail_at(node, "expected a string, sequence, mapping, or null; got #{value.class}")
        end
      rescue InvalidArgument, ArgumentError => e
        fail_at(node, e.message)
      end

      def scalar(value)
        match = /\A<([^<>]+)>\z/.match(value)
        match ? NonTerminal.new(match[1]) : Terminal.new(value)
      end

      def build_operator(value, node)
        fields = mapping(value, node)
        operator = fields.keys.find { |key| OPERATORS.include?(key) }
        fail_at(node, 'node mapping must contain an operator') if fields.empty?
        fail_at(node.children.first, "unknown key: #{fields.keys.first}") unless operator
        allowed = [operator]
        allowed << 'default' if operator == 'choice'
        allowed << 'skip' if operator == 'optional'
        fields.each_key do |key|
          fail_at(key_node(node, key), "unknown key: #{key}") unless allowed.include?(key)
        end
        entry = fields.fetch(operator)
        case operator
        when 'choice'
          items = sequence(*entry, 'choice')
          Choice.new(integer_option(fields, 'default', 0), *items)
        when 'optional'
          optional_node(entry, fields)
        when 'zero_or_more', 'one_or_more'
          repeat_node(operator, entry)
        when 'repeat', 'list', 'group', 'except'
          structured_node(operator, entry)
        when 'comment'
          Comment.new(string(*entry, 'comment'))
        else
          items = sequence(*entry, operator)
          ARRAYS.fetch(operator).new(*items)
        end
      end

      def optional_node(entry, outer)
        value, node = entry
        return Optional.new(build(value, node), skip: boolean_option(outer, 'skip', false)) unless value.is_a?(Hash) && value.key?('item')

        fields = mapping(value, node, %w[item skip])
        fail_at(node, 'skip specified twice') if outer.key?('skip') && fields.key?('skip')

        Optional.new(build(*required(fields, 'item', node)),
                     skip: boolean_option(fields, 'skip', boolean_option(outer, 'skip', false)))
      end

      def repeat_node(operator, entry)
        value, node = entry
        if value.is_a?(Hash) && value.key?('item')
          fields = mapping(value, node, operator == 'zero_or_more' ? %w[item separator skip] : %w[item separator])
          item = build(*required(fields, 'item', node))
          separator = fields['separator'] && build(*fields['separator'])
          return ZeroOrMore.new(item, separator, skip: boolean_option(fields, 'skip', false)) if operator == 'zero_or_more'

          return OneOrMore.new(item, separator)
        end

        item = build(value, node)
        operator == 'zero_or_more' ? ZeroOrMore.new(item) : OneOrMore.new(item)
      end

      def structured_node(operator, entry)
        value, node = entry
        return Repeat.new(build(value, node)) if operator == 'repeat' && !value.is_a?(Hash)
        return Group.new(build(value, node)) if operator == 'group' && !value.is_a?(Hash)

        fields = mapping(value, node, {
          'repeat' => %w[item min max separator label], 'list' => %w[item separator min trailing],
          'group' => %w[item label], 'except' => %w[item excluded label]
        }.fetch(operator))
        item = build(*required(fields, 'item', node))
        case operator
        when 'repeat'
          Repeat.new(item, min: integer_option(fields, 'min', 1), max: optional_integer(fields, 'max'),
                           separator: fields['separator'] && build(*fields['separator']), label: label_option(fields))
        when 'list'
          separator = fields['separator'] ? build(*fields['separator']) : Terminal.new(',')
          SeparatedList.new(item, separator, min: integer_option(fields, 'min', 1),
                                             trailing: boolean_option(fields, 'trailing', false))
        when 'group'
          label = fields['label'] && label_value(*fields['label'])
          Group.new(item, label: label)
        else
          excluded = required(fields, 'excluded', node)
          excluded_value = excluded[0].is_a?(String) && !excluded[0].match?(/\A<[^<>]+>\z/) ? excluded[0] : build(*excluded)
          Except.new(item, excluded_value, label: label_option(fields))
        end
      end

      def sequence(value, node, name)
        fail_at(node, "#{name} must be a sequence") unless value.is_a?(Array) && node.is_a?(Psych::Nodes::Sequence)

        value.zip(node.children).map { |item, item_node| build(item, item_node) }
      end

      def required(fields, name, node)
        fields[name] || fail_at(node, "missing #{name}")
      end

      def string(value, node, name)
        fail_at(node, "#{name} must be a string") unless value.is_a?(String)

        value
      end

      def integer_option(fields, name, default)
        return default unless fields.key?(name)

        value, node = fields.fetch(name)
        fail_at(node, "#{name} must be an integer") unless value.is_a?(Integer)

        value
      end

      def optional_integer(fields, name)
        return nil unless fields.key?(name)

        value, node = fields.fetch(name)
        fail_at(node, "#{name} must be an integer or null") unless value.nil? || value.is_a?(Integer)

        value
      end

      def boolean_option(fields, name, default)
        return default unless fields.key?(name)

        value, node = fields.fetch(name)
        fail_at(node, "#{name} must be a boolean") unless [true, false].include?(value)

        value
      end

      def label_option(fields)
        return :auto unless fields.key?('label')

        value, node = fields.fetch('label')
        fail_at(node, 'label must be a string or null') unless value.nil? || value.is_a?(String)

        value
      end

      def label_value(value, node)
        value.is_a?(String) || value.nil? ? value : build(value, node)
      end

      def key_node(mapping_node, key)
        mapping_node.children.each_slice(2).find { |item, _| item.value == key }.first
      end

      def fail_at(node, message)
        line = node ? node.start_line + 1 : 1
        column = node ? node.start_column + 1 : 1
        source_line = @lines[line - 1]&.chomp
        raise ParseError.new("#{@filename}:#{line}:#{column}: #{message}\n#{source_line}\n#{' ' * (column - 1)}^",
                             line: line, column: column, source_line: source_line)
      end

      def raise_parse_error(error)
        line = error.respond_to?(:line) ? error.line : nil
        column = error.respond_to?(:column) ? error.column : nil
        line ||= 1
        column ||= 1
        source_line = @lines[line - 1]&.chomp
        raise ParseError.new("#{@filename}:#{line}:#{column}: #{error.message}",
                             line: line, column: column, source_line: source_line)
      end
    end
  end
end
