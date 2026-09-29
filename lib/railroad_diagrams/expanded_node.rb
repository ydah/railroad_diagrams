# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # Nodes with their own meaning but the geometry of existing nodes.
  module ExpandedNode
    def format(x, y, width)
      expanded.format(x, y, width).add(self)
      self
    end

    def text_diagram
      expanded.text_diagram
    end

    def measure(context)
      context.metrics(expanded(context))
    end

    def render_svg(context, x, y, width)
      Svg::Element.new('g', @attrs.dup) << expanded(context).render_svg(context, x, y, width)
    end

    def render_text(context)
      expanded(context).render_text(context)
    end

    def walk(callback)
      callback.call(self)
      child_nodes.each { |child| child.walk(callback) }
    end

    private

    def expanded(_context = nil)
      @expanded
    end

    def adopt_expansion(node)
      @expanded = node
      @width = node.width
      @up = node.up
      @height = node.height
      @down = node.down
      @needs_space = node.needs_space
    end
  end
end
