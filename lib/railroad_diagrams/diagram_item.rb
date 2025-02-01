# frozen_string_literal: true

module RailroadDiagrams
  class DiagramItem
    attr_reader :up, :down, :height, :width, :needs_space, :attrs, :children

    def initialize(name, attrs: {}, text: nil)
      @name = name
      @up = 0
      @height = 0
      @down = 0
      @width = 0
      @needs_space = false
      @attrs = attrs || {}
      @children = text ? [text] : []
    end

    def format(x, y, width)
      raise NotImplementedError
    end

    def text_diagram
      raise NotImplementedError 'Virtual'
    end

    def add(parent)
      parent.children.push self
      self
    end

    def write_svg(write)
      write.call("<#{@name}")
      @attrs.sort.each do |name, value|
        write.call(" #{name}=\"#{RailroadDiagrams.escape_attr(value)}\"")
      end
      write.call('>')
      write.call("\n") if @name in %w[g svg]
      @children.each do |child|
        if child.is_a?(DiagramItem) || child.is_a?(Path) || child.is_a?(Style)
          child.write_svg(write)
        else
          write.call(RailroadDiagrams.escape_html(child))
        end
      end
      write.call("</#{@name}>")
    end

    def walk(_callback)
      callback(self)
    end

    def to_str
      "DiagramItem(#{@name}, #{@attrs}, #{@children})"
    end

    private

    def wrap_string(value)
      if value.class <= DiagramItem
        value
      else
        Terminal.new(value)
      end
    end

    def determine_gaps(outer, inner)
      diff = outer - inner
      if INTERNAL_ALIGNMENT == 'left'
        [0, diff]
      elsif INTERNAL_ALIGNMENT == 'right'
        [diff, 0]
      else
        [diff / 2, diff / 2]
      end
    end

    def write_standalone(write, css = nil)
      write_svg(write)
    end
  end
end
