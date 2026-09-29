# frozen_string_literal: true

module RailroadDiagrams
  module Importers
    module W3cEbnf
      Rule = Struct.new(:name, :expression, :line, :column)

      class Parser
        def initialize(source, filename: nil)
          @lexer = Lexer.new(source, filename: filename)
          @tokens = @lexer.tokens.reject { |token| %i[comment constraint].include?(token.type) }
          @index = 0
        end

        def parse
          rules = []
          names = {}
          until peek.type == :eof
            advance if peek.type == :rule_number
            name = expect(:name)
            @lexer.error("duplicate rule #{name.value.inspect}", name.line, name.column) if names.key?(name.value)
            expect(:define)
            expression = alternation
            rules << Rule.new(name.value, expression, name.line, name.column)
            names[name.value] = true
            unexpected('rule definition') unless rule_start? || peek.type == :eof
          end
          rules
        end

        private

        def peek(offset = 0)
          @tokens[@index + offset] || @tokens.last
        end

        def advance
          token = peek
          @index += 1
          token
        end

        def expect(type)
          return advance if peek.type == type

          unexpected(type == :rparen ? "')'" : type.to_s)
        end

        def unexpected(expected)
          token = peek
          found = token.type == :eof ? 'end of input' : token.value.inspect
          @lexer.error("expected #{expected} but found #{found}", token.line, token.column)
        end

        def rule_start?
          offset = peek.type == :rule_number ? 1 : 0
          peek(offset).type == :name && peek(offset + 1).type == :define
        end

        def alternation
          items = [sequence]
          items << sequence while peek.type == :pipe && advance
          items.size == 1 ? items.first : [:choice, items]
        end

        def sequence
          items = []
          until %i[pipe rparen eof].include?(peek.type) || rule_start?
            unexpected('expression') unless primary_start?(peek.type)

            items << difference
          end
          unexpected('expression') if items.empty?

          items.size == 1 ? items.first : [:sequence, items]
        end

        def difference
          item = postfix
          return item unless peek.type == :minus && advance

          [:except, item, postfix]
        end

        def postfix
          item = primary
          operators = { question: :optional, star: :zero_or_more, plus: :one_or_more }
          operator = operators[peek.type]
          operator ? [operator, item].tap { advance } : item
        end

        def primary_start?(type)
          %i[name string char_class hex_char lparen].include?(type)
        end

        def primary
          token = advance
          case token.type
          when :name, :string, :char_class, :hex_char
            [token.type, token.value]
          when :lparen
            expression = alternation
            expect(:rparen)
            expression
          else
            @index -= 1
            unexpected('expression')
          end
        end
      end
    end
  end
end
