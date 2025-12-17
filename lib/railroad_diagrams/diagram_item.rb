# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class DiagramItem
    attr_reader :up #: Numeric
    attr_reader :down #: Numeric
    attr_reader :height #: Numeric
    attr_reader :width #: Numeric
    attr_reader :needs_space #: bool
    attr_reader :attrs #: Hash[String, String | Numeric]
    attr_reader :children #: Array[DiagramItem | Path | Style | String]

    # @rbs name: String
    # @rbs attrs: Hash[String, String | Numeric]
    # @rbs text: String?
    # @rbs return: void
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

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: DiagramItem
    def format(x, y, width)
      raise NotImplementedError
    end

    # @rbs return: TextDiagram
    def text_diagram
      raise NotImplementedError 'Virtual'
    end

    # @rbs parent: DiagramItem
    # @rbs return: DiagramItem
    def add(parent)
      parent.children.push self
      self
    end

    # @rbs write: ^(String) -> void
    # @rbs return: void
    def write_svg(write)
      write_opening_tag(write)
      write_children(write)
      write.call("</#{@name}>")
    end

    # @rbs _callback: ^(DiagramItem) -> void
    # @rbs return: void
    def walk(_callback)
      callback(self)
    end

    # @rbs return: String
    def to_str
      "DiagramItem(#{@name}, #{@attrs}, #{@children})"
    end

    private

    # @rbs write: ^(String) -> void
    # @rbs return: void
    def write_opening_tag(write)
      write.call("<#{@name}")
      @attrs.sort.each do |name, value|
        write.call(" #{name}=\"#{RailroadDiagrams.escape_attr(value)}\"")
      end
      write.call('>')
      write.call("\n") if container_element?
    end

    # @rbs write: ^(String) -> void
    # @rbs return: void
    def write_children(write)
      @children.each do |child|
        if child.respond_to?(:write_svg)
          child.write_svg(write)
        else
          write.call(RailroadDiagrams.escape_html(child))
        end
      end
    end

    # @rbs return: bool
    def container_element?
      %w[g svg].include?(@name)
    end

    # @rbs value: DiagramItem | String
    # @rbs return: DiagramItem
    def wrap_string(value)
      value.is_a?(DiagramItem) ? value : Terminal.new(value)
    end

    # @rbs outer: Numeric
    # @rbs inner: Numeric
    # @rbs return: [Numeric, Numeric]
    def determine_gaps(outer, inner)
      diff = outer - inner
      case INTERNAL_ALIGNMENT
      when 'left'
        [0, diff]
      when 'right'
        [diff, 0]
      else
        [diff / 2, diff / 2]
      end
    end

    # @rbs write: ^(String) -> void
    # @rbs _css: String?
    # @rbs return: void
    def write_standalone(write, _css = nil)
      write_svg(write)
    end
  end
end
