# frozen_string_literal: true

require 'json'
require 'psych'

module RailroadDiagrams
  module Serialization
    CONTAINERS = {
      'sequence' => Sequence,
      'stack' => Stack,
      'horizontal_choice' => HorizontalChoice,
      'optional_sequence' => OptionalSequence,
      'alternating_sequence' => AlternatingSequence
    }.freeze

    module Node
      def to_h
        Serialization.dump(self)
      end

      def to_json(*args)
        JSON.generate(to_h, *args)
      end

      def to_yaml
        Psych.dump(to_h)
      end
    end

    module_function

    # rubocop:disable-next Metrics/CyclomaticComplexity
    def dump(node)
      type = node.class.name.split('::').last.gsub(/([a-z\d])([A-Z])/, '\\1_\\2').downcase
      result = { 'type' => type }
      case node
      when Diagram
        result['diagram_type'] = node.instance_variable_get(:@type)
        items = node.instance_variable_get(:@items).dup
        if items.size > 2
          items.shift if default_edge?(items.first, 'start', result['diagram_type'])
          items.pop if default_edge?(items.last, 'end', result['diagram_type'])
        end
        result['items'] = items.map(&:to_h)
        result['title'] = node.instance_variable_get(:@title) if node.instance_variable_get(:@title)
        desc = node.instance_variable_get(:@desc)
        result[desc == :auto ? 'desc_auto' : 'desc'] = desc == :auto ? true : desc if desc
      when Terminal, NonTerminal, Comment
        result['text'] = node.instance_variable_get(:@text)
        %w[href title].each do |field|
          value = node.instance_variable_get("@#{field}")
          result[field] = value unless value.nil?
        end
      when Start, End
        result['diagram_type'] = node.instance_variable_get(:@type)
        label = node.instance_variable_get(:@label)
        result['label'] = label unless label.nil?
      when ZeroOrMore
        repeated = node.child_nodes[1]
        result['item'] = repeated.child_nodes[0].to_h
        result['repeat'] = repeated.child_nodes[1].to_h
        result['skip'] = node.instance_variable_get(:@default).zero?
      when Optional
        result['item'] = node.child_nodes[1].to_h
        result['skip'] = node.instance_variable_get(:@default).zero?
      when Choice
        result['default'] = node.instance_variable_get(:@default)
        result['items'] = node.child_nodes.map(&:to_h)
      when MultipleChoice
        result['default'] = node.instance_variable_get(:@default)
        result['choice_type'] = node.instance_variable_get(:@type)
        result['items'] = node.child_nodes.map(&:to_h)
      when OneOrMore
        result['item'] = node.child_nodes[0].to_h
        result['repeat'] = node.child_nodes[1].to_h
      when Group
        result['item'] = node.child_nodes[0].to_h
        result['label'] = node.child_nodes[1].to_h if node.child_nodes[1]
      when Sequence, Stack, HorizontalChoice, OptionalSequence, AlternatingSequence
        result['items'] = node.child_nodes.map(&:to_h)
      when Skip
        # No structural fields.
      else
        raise ParseError, "cannot serialize #{node.class}"
      end
      add_attributes(result, node)
    end

    def default_edge?(node, type, diagram_type)
      return false unless (type == 'start' && node.is_a?(Start)) || (type == 'end' && node.is_a?(End))

      dump(node) == { 'type' => type, 'diagram_type' => diagram_type }
    end

    def add_attributes(result, node)
      attributes = node.attrs
      result['id'] = attributes['id'] if attributes.key?('id')
      cls = if node.is_a?(Diagram)
              node.instance_variable_get(:@diagram_cls)
            elsif node.is_a?(Terminal) || node.is_a?(NonTerminal) || node.is_a?(Comment)
              node.instance_variable_get(:@cls)
            else
              attributes['class']
            end
      result['cls'] = cls if cls && !cls.empty?
      data = attributes.select { |name, _| name.start_with?('data-') }
      result['attrs'] = data unless data.empty?
      result
    end

    # rubocop:disable-next Metrics/CyclomaticComplexity, Metrics/MethodLength
    def parse(value)
      raise ParseError, 'node must be an object with string keys' unless value.is_a?(Hash) && value.keys.all?(String)
      raise ParseError, 'unsupported schema version' if value.key?('schema_version') && value['schema_version'] != 1

      type = value['type']
      common = common_options(value)
      case type
      when 'diagram'
        check_keys(value, %w[type schema_version diagram_type items title desc desc_auto], common)
        raise ParseError, 'desc and desc_auto are mutually exclusive' if value.key?('desc') && value.key?('desc_auto')

        desc = value['desc_auto'] == true ? :auto : optional_string(value, 'desc')
        raise ParseError, 'desc_auto must be true' if value.key?('desc_auto') && value['desc_auto'] != true

        Diagram.new(*parse_items(value), type: required_string(value, 'diagram_type'),
                                         title: optional_string(value, 'title'), desc: desc, **common)
      when 'terminal', 'non_terminal', 'comment'
        check_keys(value, %w[type schema_version text href title], common)
        klass = { 'terminal' => Terminal, 'non_terminal' => NonTerminal, 'comment' => Comment }.fetch(type)
        klass.new(required_string(value, 'text'), href: optional_string(value, 'href'),
                                                  title: optional_string(value, 'title'), **common)
      when 'start', 'end'
        check_keys(value, %w[type schema_version diagram_type label], common)
        klass = type == 'start' ? Start : End
        klass.new(required_string(value, 'diagram_type'), label: optional_string(value, 'label'), **common)
      when 'skip'
        check_keys(value, %w[type schema_version], common)
        Skip.new(**common)
      when 'choice'
        check_keys(value, %w[type schema_version default items], common)
        Choice.new(required_integer(value, 'default'), *parse_items(value), **common)
      when 'optional'
        check_keys(value, %w[type schema_version item skip], common)
        Optional.new(parse(required(value, 'item')), skip: required_boolean(value, 'skip'), **common)
      when 'zero_or_more'
        check_keys(value, %w[type schema_version item repeat skip], common)
        ZeroOrMore.new(parse(required(value, 'item')), parse(required(value, 'repeat')),
                       skip: required_boolean(value, 'skip'), **common)
      when 'multiple_choice'
        check_keys(value, %w[type schema_version default choice_type items], common)
        MultipleChoice.new(required_integer(value, 'default'), required_string(value, 'choice_type'),
                           *parse_items(value), **common)
      when 'one_or_more'
        check_keys(value, %w[type schema_version item repeat], common)
        OneOrMore.new(parse(required(value, 'item')), parse(required(value, 'repeat')), **common)
      when 'group'
        check_keys(value, %w[type schema_version item label], common)
        Group.new(parse(required(value, 'item')), label: value.key?('label') ? parse(value['label']) : nil, **common)
      when 'block'
        check_keys(value, %w[type schema_version width up height down needs_space], common)
        Block.new(width: required_number(value, 'width'), up: required_number(value, 'up'),
                  height: required_number(value, 'height'), down: required_number(value, 'down'),
                  needs_space: required_boolean(value, 'needs_space'), **common)
      when 'repeat'
        check_keys(value, %w[type schema_version item min max separator label], common)
        Repeat.new(parse(required(value, 'item')), min: required_integer(value, 'min'),
                                                   max: nullable_integer(value, 'max'), separator: nullable_node(value, 'separator'),
                                                   label: parse_label(value, 'label'), **common)
      when 'separated_list'
        check_keys(value, %w[type schema_version item separator min trailing], common)
        SeparatedList.new(parse(required(value, 'item')), parse(required(value, 'separator')),
                          min: required_integer(value, 'min'), trailing: required_boolean(value, 'trailing'), **common)
      when 'except'
        check_keys(value, %w[type schema_version item excluded label], common)
        excluded = required(value, 'excluded')
        Except.new(parse(required(value, 'item')), excluded.is_a?(String) ? excluded : parse(excluded),
                   label: parse_label(value, 'label'), **common)
      when 'char_class', 'special'
        check_keys(value, %w[type schema_version text href title], common)
        klass = type == 'char_class' ? CharClass : Special
        klass.new(required_string(value, 'text'), href: optional_string(value, 'href'),
                                                  title: optional_string(value, 'title'), **common)
      else
        klass = CONTAINERS[type]
        raise ParseError, "unknown node type: #{type.inspect}" unless klass

        check_keys(value, %w[type schema_version items], common)
        klass.new(*parse_items(value), **common)
      end
    rescue InvalidArgument, ArgumentError => e
      raise ParseError, e.message
    end

    def required(value, key)
      raise ParseError, "missing #{key}" unless value.key?(key)

      value[key]
    end

    def required_string(value, key)
      item = required(value, key)
      raise ParseError, "#{key} must be a string" unless item.is_a?(String)

      item
    end

    def optional_string(value, key)
      return nil unless value.key?(key)

      required_string(value, key)
    end

    def required_integer(value, key)
      item = required(value, key)
      raise ParseError, "#{key} must be an integer" unless item.is_a?(Integer)

      item
    end

    def nullable_integer(value, key)
      item = required(value, key)
      return nil if item.nil?

      required_integer(value, key)
    end

    def required_number(value, key)
      item = required(value, key)
      raise ParseError, "#{key} must be a number" unless item.is_a?(Numeric)

      item
    end

    def required_boolean(value, key)
      item = required(value, key)
      raise ParseError, "#{key} must be a boolean" unless [true, false].include?(item)

      item
    end

    def nullable_node(value, key)
      item = required(value, key)
      item.nil? ? nil : parse(item)
    end

    def parse_label(value, key)
      item = required(value, key)
      return :auto if item == { 'auto' => true }
      raise ParseError, "#{key} must be a string, null, or auto" unless item.nil? || item.is_a?(String)

      item
    end

    def parse_items(value)
      items = required(value, 'items')
      raise ParseError, 'items must be an array' unless items.is_a?(Array)

      items.map { |item| parse(item) }
    end

    def common_options(value)
      options = {}
      options[:id] = required_string(value, 'id') if value.key?('id')
      options[:cls] = required_string(value, 'cls') if value.key?('cls')
      if value.key?('attrs')
        attrs = value['attrs']
        raise ParseError, 'attrs must be an object of strings' unless attrs.is_a?(Hash) && attrs.all? { |key, item| key.is_a?(String) && item.is_a?(String) }

        options[:attrs] = attrs
      end
      options
    end

    def check_keys(value, fields, _common)
      unknown = value.keys - fields - %w[id cls attrs]
      raise ParseError, "unknown field(s): #{unknown.join(', ')}" unless unknown.empty?
    end
  end

  DiagramItem.include(Serialization::Node)

  def self.from_h(value)
    Serialization.parse(value)
  end

  def self.from_json(source)
    from_h(JSON.parse(source))
  rescue JSON::ParserError => e
    raise ParseError, e.message
  end

  def self.from_yaml(source)
    value = if Psych::VERSION.to_i >= 4
              Psych.safe_load(source, permitted_classes: [], permitted_symbols: [], aliases: false)
            else
              Psych.safe_load(source, [], [], false)
            end
    from_h(value)
  rescue Psych::Exception => e
    raise ParseError, e.message
  end
end
