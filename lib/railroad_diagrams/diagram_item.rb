# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # format を呼ぶたびに前回の描画結果（子要素）を捨てて冪等にする（BUG-05）
  module ResetChildrenOnFormat
    # @rbs *args: untyped
    # @rbs return: untyped
    def format(*args)
      @children.clear
      super
    end
  end

  # Base class for diagram nodes and structural traversal.
  # @example
  #   Sequence.new('a', 'b').each_node.map(&:class)
  class DiagramItem
    include Enumerable #[DiagramItem]

    # @rbs subclass: Class
    # @rbs return: void
    def self.inherited(subclass)
      super
      subclass.prepend(ResetChildrenOnFormat)
    end

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
    def initialize(name, attrs: {}, text: nil, id: nil, data_attrs: {}, cls: nil)
      @name = name
      @up = 0
      @height = 0
      @down = 0
      @width = 0
      @needs_space = false
      @attrs = (attrs || {}).dup
      apply_user_attributes(id, data_attrs, cls)
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
      raise NotImplementedError, "#{self.class}#text_diagram is not implemented"
    end

    # @rbs parent: DiagramItem
    # @rbs return: DiagramItem
    def add(parent)
      parent.children.push self
      self
    end

    # @rbs write: untyped
    # @rbs return: void
    def write_svg(write)
      write = Writer.wrap(write)
      write_opening_tag(write)
      write_children(write)
      write.call("</#{@name}>")
    end

    # @rbs callback: ^(DiagramItem) -> void
    # @rbs return: void
    def walk(callback)
      callback.call(self)
    end

    # Return the node's direct structural children.
    # @example
    #   Sequence.new('a', 'b').child_nodes.size #=> 2
    def child_nodes
      []
    end

    # Visit this node and descendants in preorder.
    # @example
    #   Sequence.new('a', 'b').each_node.map(&:class)
    def each_node(&block)
      return enum_for(:each_node) unless block

      block.call(self)
      child_nodes.each { |child| child.each_node(&block) if child.respond_to?(:each_node) }
      self
    end
    alias each each_node

    # Compare node structure and user attributes.
    # @example
    #   Terminal.new('x') == Terminal.new('x') #=> true
    def ==(other)
      other.class == self.class && structural_state == other.send(:structural_state)
    end
    alias eql? ==

    # Hash the same structural state used by equality.
    # @example
    #   [Terminal.new('x'), Terminal.new('x')].uniq.size #=> 1
    def hash
      [self.class, structural_state].hash
    end

    # @rbs write: ^(String) -> void
    # @rbs _css: String?
    # @rbs return: void
    def write_standalone(write, _css = nil)
      write_svg(write)
    end

    # @rbs return: String
    def to_str
      Deprecation.warn('DiagramItem#to_str is deprecated; use #inspect')
      inspect
    end

    # @rbs return: String
    # @example
    #   Sequence.new('a', 'b').inspect
    def inspect
      Introspection.call(self)
    end

    private

    def structural_state
      to_h
    rescue ParseError
      [@name, @attrs, @items&.map { |item| item.is_a?(Style) ? item.to_s : item.to_h }]
    end

    def apply_user_attributes(id, data_attrs, cls)
      if id
        raise InvalidArgument, 'id must be a valid SVG identifier' unless id.is_a?(String) && /\A[A-Za-z_][\w.-]*\z/.match?(id)

        @attrs['id'] = id
      end
      raise InvalidArgument, 'attrs must be a Hash' unless data_attrs.is_a?(Hash)

      data_attrs.each do |name, value|
        raise InvalidArgument, "unsupported SVG attribute: #{name.inspect}" unless name.is_a?(String) && /\Adata-[A-Za-z0-9_-]+\z/.match?(name)

        @attrs[name] = value.to_s
      end
      return if cls.nil?
      raise InvalidArgument, 'cls must be a String' unless cls.is_a?(String)
      return if cls.empty?

      @attrs['class'] = [@attrs['class'], cls].compact.join(' ').strip
    end

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
        half = diff.is_a?(Integer) && diff.odd? ? diff / 2.0 : diff / 2
        [half, half]
      end
    end
  end
end
