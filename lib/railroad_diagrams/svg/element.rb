# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Svg
    class Element
      attr_reader :name, :attrs, :children, :role, :self_closing

      def initialize(name, attrs = {}, children = [], role: nil, self_closing: false)
        @name = name
        @attrs = attrs
        @children = children
        @role = role
        @self_closing = self_closing
      end

      def <<(child)
        @children << child
        self
      end
    end

    TextNode = Struct.new(:text)
    CData = Struct.new(:text)
    StyleText = Struct.new(:css)
  end
end
