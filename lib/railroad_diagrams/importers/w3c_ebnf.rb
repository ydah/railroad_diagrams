# frozen_string_literal: true

require 'railroad_diagrams'
require_relative '../transform/simplifier'
require_relative 'w3c_ebnf/lexer'
require_relative 'w3c_ebnf/parser'
require_relative 'w3c_ebnf/builder'

module RailroadDiagrams
  module Importers
    module W3cEbnf
      module_function

      def parse(source, filename: nil, simplify: false)
        rules = Parser.new(source, filename: filename).parse
        Builder.new(rules, filename: filename, simplify: simplify).build
      end
    end
  end
end
