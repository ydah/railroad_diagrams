# frozen_string_literal: true

module RailroadDiagrams
  module Transform
    module Simplifier
      RULES = (1..8).map { |number| :"s#{number}" }.freeze
      ATTRIBUTES = %w[id cls attrs].freeze

      module_function

      def call(node, except: [], rule_name: nil)
        raise InvalidArgument, 'node must be a diagram node' unless node.is_a?(DiagramItem)

        excluded = Array(except)
        raise InvalidArgument, 'unknown simplification rule' unless (excluded - RULES).empty?

        current = node.to_h
        10.times do
          updated = rewrite(current, excluded, rule_name, true)
          return RailroadDiagrams.from_h(current) if updated == current

          current = updated
        end
        RailroadDiagrams.from_h(current)
      end

      def rewrite(node, excluded, rule_name, root)
        before_children = %i[s5 s6 s7].reduce(node) do |current, rule|
          next current if excluded.include?(rule) || (rule == :s6 && !root)

          public_send(rule, current, rule_name) || current
        end
        children = before_children.each_with_object({}) do |(key, value), result|
          result[key] = if value.is_a?(Hash) && value['type']
                          rewrite(value, excluded, nil, false)
                        elsif value.is_a?(Array)
                          value.map { |child| child.is_a?(Hash) && child['type'] ? rewrite(child, excluded, nil, false) : child }
                        else
                          value
                        end
        end
        RULES.reduce(children) do |current, rule|
          next current if excluded.include?(rule) || (rule == :s6 && !root)

          public_send(rule, current, rule_name) || current
        end
      end

      def plain?(node)
        (node.keys & ATTRIBUTES).empty?
      end

      def attributes(node)
        node.slice(*ATTRIBUTES)
      end

      def s1(node, _rule_name = nil)
        return unless node['type'] == 'sequence'

        items = node['items'].flat_map do |item|
          item['type'] == 'sequence' && plain?(item) ? item['items'] : [item]
        end
        node.merge('items' => items) unless items == node['items']
      end

      def s2(node, _rule_name = nil)
        return unless plain?(node)

        return node['items'].first if node['type'] == 'sequence' && node['items'].size == 1

        node['items'].first if node['type'] == 'choice' && node['items'].size == 1
      end

      def s3(node, _rule_name = nil)
        return unless node['type'] == 'choice'

        items = node['items'].uniq
        return if items.size == node['items'].size

        node.merge('items' => items, 'default' => items.index(node['items'][node['default']]))
      end

      def s4(node, _rule_name = nil)
        return unless node['type'] == 'choice' && node['items'].size == 2

        index = node['items'].index { |item| item['type'] == 'skip' && plain?(item) }
        return unless index

        { 'type' => 'optional', 'item' => node['items'][1 - index], 'skip' => node['default'] == index }
          .merge(attributes(node))
      end

      def s5(node, _rule_name = nil)
        return unless node['type'] == 'sequence' && node['items'].size == 2

        item, zero = node['items']
        return unless zero['type'] == 'zero_or_more' && plain?(zero)

        sequence = zero['item']
        return unless sequence['type'] == 'sequence' && plain?(sequence) && sequence['items'].size == 2
        return unless sequence['items'][1] == item && zero['repeat']['type'] == 'skip' && plain?(zero['repeat'])

        { 'type' => 'one_or_more', 'item' => item, 'repeat' => sequence['items'][0] }.merge(attributes(node))
      end

      def s6(node, rule_name = nil)
        return unless rule_name && node['type'] == 'choice' && node['items'].size == 2

        recursive = node['items'].find do |item|
          item['type'] == 'sequence' && plain?(item) && item['items'].size == 2 &&
            item['items'][0]['type'] == 'non_terminal' && item['items'][0]['text'] == rule_name
        end
        return unless recursive

        base = (node['items'] - [recursive]).first
        return unless base

        suffix = recursive['items'][1]
        return if references?(base, rule_name) || references?(suffix, rule_name)

        { 'type' => 'sequence', 'items' => [base, {
          'type' => 'zero_or_more', 'item' => suffix,
          'repeat' => { 'type' => 'skip' }, 'skip' => false
        }] }.merge(attributes(node))
      end

      def s7(node, _rule_name = nil)
        return unless node['type'] == 'choice' && node['items'].size == 2

        left, right = node['items']
        return unless [left, right].all? { |item| item['type'] == 'sequence' && plain?(item) && item['items'].size == 2 }
        return unless left['items'][0] == right['items'][0]

        { 'type' => 'sequence', 'items' => [left['items'][0], {
          'type' => 'choice', 'default' => node['default'], 'items' => [left['items'][1], right['items'][1]]
        }] }.merge(attributes(node))
      end

      def s8(node, _rule_name = nil)
        return unless node['type'] == 'optional' && node['item']['type'] == 'optional' && plain?(node['item'])

        node.merge('item' => node['item']['item'])
      end

      def references?(node, name)
        return node['text'] == name if node['type'] == 'non_terminal'

        node.values.any? do |value|
          if value.is_a?(Hash) && value['type']
            references?(value, name)
          elsif value.is_a?(Array)
            value.any? { |item| item.is_a?(Hash) && item['type'] && references?(item, name) }
          else
            false
          end
        end
      end
    end
  end
end
