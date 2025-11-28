# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Style
    # @rbs css: String
    # @rbs return: void
    def initialize(css)
      @css = css
    end

    class << self
      # @rbs return: String
      def default_style
        <<~CSS
          * {
            color: #333333;
          }
          svg.railroad-diagram {
            background-color: white;
          }
          svg.railroad-diagram path {
            stroke-width:3;
            stroke:black;
            fill:rgba(0,0,0,0);
          }
          svg.railroad-diagram text {
            font:bold 14px monospace;
            text-anchor:middle;
          }
          svg.railroad-diagram text.label {
            text-anchor:start;
          }
          svg.railroad-diagram text.comment {
            font:italic 12px monospace;
          }
          svg.railroad-diagram rect {
            stroke-width:3;
            stroke: #333333;
            fill:hsl(120,100%,90%);
          }
          svg.railroad-diagram path {
            stroke: #333333;
          }
          svg.railroad-diagram .terminal rect {
            fill: hsl(190, 100%, 83%);
          }
          svg.railroad-diagram .non-terminal rect {
            fill: hsl(223, 100%, 83%);
          }
          svg.railroad-diagram rect.group-box {
            stroke: gray;
            stroke-dasharray: 10 5;
            fill: none;
          }
        CSS
      end
    end

    # @rbs return: String
    def to_s
      "Style(#{@css})"
    end

    # @rbs parent: DiagramItem
    # @rbs return: Style
    def add(parent)
      parent.children.push(self)
      self
    end

    # @rbs return: Style
    def format
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      TextDiagram.new
    end

    # @rbs write: ^(String) -> void
    # @rbs return: void
    def write_svg(write)
      # Write included stylesheet as CDATA. See https://developer.mozilla.org/en-US/docs/Web/SVG/Element/style
      cdata = "/* <![CDATA[ */\n#{@css}\n/* ]]> */\n"
      write.call("<style>#{cdata}</style>")
    end
  end
end
