# frozen_string_literal: true

module RailroadDiagrams
  module Importers
    module W3cEbnf
      Token = Struct.new(:type, :value, :line, :column)

      class Lexer
        def initialize(source, filename: nil)
          raise InvalidArgument, 'source must be a String' unless source.is_a?(String)

          @source = source.gsub(/\r\n?/, "\n")
          @filename = filename || '<input>'
          @lines = @source.split("\n", -1)
          @offset = 0
          @line = 1
          @column = 1
        end

        def tokens
          result = []
          until @offset == @source.length
            if current.match?(/[[:space:]]/)
              advance(1)
              next
            end

            line = @line
            column = @column
            type, value = next_token
            result << Token.new(type, value, line, column)
          end
          result << Token.new(:eof, nil, @line, @column)
        end

        def error(message, line = @line, column = @column)
          source_line = @lines[line - 1] || ''
          raise ParseError.new("#{@filename}:#{line}:#{column}: #{message}\n  #{source_line}\n  #{' ' * (column - 1)}^",
                               line: line, column: column, source_line: source_line)
        end

        private

        def current
          @source[@offset]
        end

        def remaining
          @source[@offset..-1]
        end

        def advance(length)
          @source[@offset, length].each_char do |char|
            if char == "\n"
              @line += 1
              @column = 1
            else
              @column += 1
            end
          end
          @offset += length
        end

        def next_token
          return delimited(:comment, '/*', '*/') if remaining.start_with?('/*')

          if remaining.start_with?('::=')
            advance(3)
            return [:define, '::=']
          end

          return bracket_token if current == '['
          return quoted_string if ["'", '"'].include?(current)
          return hex_char if remaining.start_with?('#x')

          punctuation = { '(' => :lparen, ')' => :rparen, '|' => :pipe,
                          '-' => :minus, '?' => :question, '*' => :star, '+' => :plus }
          if punctuation.key?(current)
            char = current
            advance(1)
            return [punctuation.fetch(char), char]
          end
          if (match = /\A[A-Za-z_][A-Za-z0-9_.]*/.match(remaining))
            advance(match[0].length)
            return [:name, match[0]]
          end

          error("unexpected character #{current.inspect}")
        end

        def delimited(type, opening, closing)
          length = remaining.index(closing, opening.length)
          error("unterminated #{type}") unless length

          value = remaining[0, length + closing.length]
          advance(value.length)
          [type, value]
        end

        def bracket_token
          line = @line
          column = @column
          if (match = /\A\[\d+[a-z]?\]/.match(remaining))
            advance(match[0].length)
            return [:rule_number, match[0]]
          end
          type = remaining.match?(/\A\[[[:space:]]*(?:wfc|vc):/i) ? :constraint : :char_class
          value = delimited(type, '[', ']')[1]
          error('empty character class', line, column) if type == :char_class && value.match?(/\A\[\^?\]/)
          [type, value]
        end

        def quoted_string
          quote = current
          length = remaining.index(quote, 1)
          error('unterminated string') unless length

          value = remaining[1, length - 1]
          advance(length + 1)
          [:string, value]
        end

        def hex_char
          match = /\A#x[0-9a-fA-F]+/.match(remaining)
          error('expected hexadecimal digits after #x') unless match

          advance(match[0].length)
          [:hex_char, match[0]]
        end
      end
    end
  end
end
