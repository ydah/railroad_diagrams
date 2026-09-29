# frozen_string_literal: true

module RailroadDiagrams
  module Transform
    # Finds likely grammar mistakes without changing the rules.
    # @example
    #   Transform::Lint.call([['entry', NonTerminal.new('missing')]])
    module Lint
      # A lint result with kind, rule, name, and message fields.
      # @example
      #   Transform::Lint.call([['entry', NonTerminal.new('missing')]]).first.message
      Warning = Struct.new(:kind, :rule, :name, :message)

      module_function

      # Returns warnings for the given ordered rule pairs.
      # @example
      #   Transform::Lint.call([['entry', Terminal.new('a')]])
      def call(rules)
        definitions = rules.map(&:first)
        references = []
        warnings = []

        rules.each_with_index do |(name, node), index|
          warnings << Warning.new(:duplicate_definition, name, name, "duplicate rule definition: #{name}") if definitions[0...index].include?(name)

          node.each_node do |item|
            if item.is_a?(NonTerminal)
              target = item.instance_variable_get(:@text)
              references << target
              warnings << Warning.new(:undefined_reference, name, target, "undefined rule: #{target}") unless definitions.include?(target)
            elsif item.is_a?(Choice)
              check_choice(item, name, warnings)
            end
          end
        end

        definitions.uniq.drop(1).each do |name|
          next if references.include?(name)

          warnings << Warning.new(:unreferenced_rule, name, name, "rule is never referenced: #{name}")
        end
        warnings.uniq { |warning| [warning.kind, warning.rule, warning.name, warning.message] }
      end

      # @private
      def check_choice(node, name, warnings)
        seen = []
        items = node.child_nodes
        warnings << Warning.new(:empty_choice, name, nil, 'choice has no alternatives') if items.empty?
        items.each_with_index do |item, index|
          if seen.any? { |previous| previous == item }
            warnings << Warning.new(:unreachable_branch, name, nil, "choice branch #{index + 1} duplicates an earlier branch")
          end
          seen << item
        end
      end
    end
  end
end
