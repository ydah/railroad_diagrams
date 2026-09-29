# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Svg
    module Serializer
      module_function

      def call(element, precision: nil, optimize_paths: false)
        output = +''
        write(element, output, precision, optimize_paths)
        output
      end

      def write(node, output, precision, optimize_paths)
        case node
        when Element
          output << "<#{node.name}"
          node.attrs.sort.each do |name, value|
            value = value.dup.optimize! if optimize_paths && value.is_a?(PathData)
            rendered = value.is_a?(PathData) ? value.to_s(->(number) { NumberFormat.call(number, precision, kind: :path) }) : value
            rendered = NumberFormat.call(rendered, precision) if rendered.is_a?(Numeric)
            output << " #{name}=\"#{RailroadDiagrams.escape_attr(rendered)}\""
          end
          if node.self_closing
            output << ' />'
          else
            output << '>'
            output << "\n" if %w[g svg].include?(node.name)
            node.children.each { |child| write(child, output, precision, optimize_paths) }
            output << "</#{node.name}>"
          end
        when TextNode
          output << RailroadDiagrams.escape_html(node.text)
        when CData
          safe_text = node.text.gsub(']]>', ']]]]><![CDATA[>').gsub(%r{</style}i, '<\\/style')
          output << "<![CDATA[#{safe_text}]]>"
        when StyleText
          css = node.css.gsub(']]>', ']]]]><![CDATA[>').gsub(%r{</style}i, '<\\/style')
          output << "<style>/* <![CDATA[ */\n#{css}\n/* ]]> */\n</style>"
        else
          raise ArgumentError, "unsupported SVG node: #{node.class}"
        end
        output
      end
    end
  end
end
