# frozen_string_literal: true

module RailroadDiagrams
  module Importers
    module W3cEbnf
      class Builder
        def initialize(rules, filename: nil, simplify: false)
          @rules = rules
          @filename = filename
          @simplify = simplify
        end

        def build
          document = Document.new(title: @filename ? File.basename(@filename) : 'Grammar')
          @rules.each do |rule|
            node = build_node(rule.expression)
            node = Transform::Simplifier.call(node, rule_name: rule.name) if @simplify
            document.add_rule(rule.name, node)
          end
          document
        end

        private

        def build_node(expression)
          type, *parts = expression
          case type
          when :name then NonTerminal.new(parts[0])
          when :string then Terminal.new(parts[0])
          when :char_class, :hex_char then CharClass.new(parts[0])
          when :sequence then Sequence.new(*parts[0].map { |part| build_node(part) })
          when :choice then Choice.new(0, *parts[0].map { |part| build_node(part) })
          when :optional then Optional.new(build_node(parts[0]))
          when :zero_or_more then ZeroOrMore.new(build_node(parts[0]))
          when :one_or_more then OneOrMore.new(build_node(parts[0]))
          when :except then Except.new(build_node(parts[0]), build_node(parts[1]))
          else raise InvalidArgument, "unknown EBNF expression: #{type.inspect}"
          end
        end
      end
    end
  end
end
