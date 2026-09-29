# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'railroad_diagrams'
require 'asciidoctor'
require 'asciidoctor/extensions'
require 'railroad_diagrams/importers/yaml_grammar'

module RailroadDiagrams
  module Asciidoctor
    class BlockProcessor < ::Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :railroad
      on_context :listing
      parse_content_as :raw

      def process(parent, reader, attrs)
        document = Importers::YamlGrammar.parse(reader.lines.join("\n"))
        html = document.rules.map do |name, node|
          diagram = node.is_a?(Diagram) ? node : Diagram.new(node)
          "<figure><figcaption>#{RailroadDiagrams.escape_html(name)}</figcaption>#{diagram.to_standalone_svg}</figure>"
        end.join("\n")
        create_pass_block(parent, html, attrs, subs: nil)
      end
    end
  end
end

Asciidoctor::Extensions.register do
  block RailroadDiagrams::Asciidoctor::BlockProcessor
end
# rubocop:enable Naming/FileName
