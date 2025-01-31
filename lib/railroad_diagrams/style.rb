# frozen_string_literal: true

module RailroadDiagrams
  class Style
    def initialize(css)
      @css = css
    end

    class << self
      def default_style
        <<~CSS
          svg.railroad-diagram {
            background-color:hsl(30,20%,95%);
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
          svg.railroad-diagram text.label{
            text-anchor:start;
          }
          svg.railroad-diagram text.comment{
            font:italic 12px monospace;
          }
          svg.railroad-diagram rect{
            stroke-width:3;
            stroke:black;
            fill:hsl(120,100%,90%);
          }
          svg.railroad-diagram rect.group-box {
            stroke: gray;
            stroke-dasharray: 10 5;
            fill: none;
          }
        CSS
      end
    end

    def to_s
      "Style(#{@css})"
    end

    def add(parent)
      parent.children.push(self)
      self
    end

    def format
      self
    end

    def text_diagram
      TextDiagram.new
    end

    def write_svg(write)
      # Write included stylesheet as CDATA. See https://developer.mozilla.org/en-US/docs/Web/SVG/Element/style
      cdata = "/* <![CDATA[ */\n#{@css}\n/* ]]> */\n"
      write.call("<style>#{cdata}</style>")
    end
  end
end
