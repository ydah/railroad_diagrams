# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'railroad_diagrams'
require 'jekyll'
require 'railroad_diagrams/importers/yaml_grammar'

module RailroadDiagrams
  module Jekyll
    FENCE = /^```railroad[ \t]*\r?\n(.*?)^```[ \t]*$/m.freeze

    module_function

    def render_fences(content)
      content.gsub(FENCE) do
        document = Importers::YamlGrammar.parse(Regexp.last_match(1))
        document.rules.map do |name, node|
          diagram = node.is_a?(Diagram) ? node : Diagram.new(node)
          "<figure><figcaption>#{RailroadDiagrams.escape_html(name)}</figcaption>#{diagram.to_standalone_svg}</figure>"
        end.join("\n")
      end
    end
  end
end

%i[pages documents].each do |owner|
  Jekyll::Hooks.register(owner, :pre_render) do |item|
    item.content = RailroadDiagrams::Jekyll.render_fences(item.content)
  end
end
# rubocop:enable Naming/FileName
