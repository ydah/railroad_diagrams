# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # A blank, fixed-size block in a diagram.
  # @example
  #   Block.new(width: 40, height: 20)
  class Block < DiagramItem
    # rubocop:disable-next Metrics/ParameterLists
    def initialize(width: 50, up: 15, height: 25, down: 15, needs_space: true, id: nil, cls: nil, attrs: {})
      super('g', id: id, cls: cls, data_attrs: attrs)
      { width: width, up: up, height: height, down: down }.each do |name, value|
        unless (value.is_a?(Integer) || value.is_a?(Float)) && value.finite? && value >= 0
          raise InvalidArgument, "#{name} must be a finite non-negative number"
        end
      end
      raise InvalidArgument, 'needs_space must be a boolean' unless [true, false].include?(needs_space)

      @width = width
      @up = up
      @height = height
      @down = down
      @needs_space = needs_space
    end

    def to_s
      "Block(width=#{@width}, up=#{@up}, height=#{@height}, down=#{@down}, needs_space=#{@needs_space})"
    end

    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      Path.new(x, y).h(left_gap).add(self)
      x += left_gap
      DiagramItem.new('rect', attrs: rectangle(x, y, @width)).add(self)
      Path.new(x + @width, y + @height).h(right_gap).add(self)
      self
    end

    def text_diagram
      TextDiagram.rect('')
    end

    def measure(_context)
      Metrics.new(width: @width, up: @up, height: @height, down: @down, needs_space: @needs_space)
    end

    def render_svg(context, x, y, width)
      left_gap, right_gap = context.gaps(width, @width)
      group = Svg::Element.new('g', @attrs.dup)
      group << Svg::Element.new('path', { 'd' => Svg::PathData.new(x, y).h(left_gap) }, self_closing: true)
      x += left_gap
      group << Svg::Element.new('rect', rectangle(x, y, @width))
      group << Svg::Element.new('path', { 'd' => Svg::PathData.new(x + @width, y + @height).h(right_gap) }, self_closing: true)
      group
    end

    def render_text(context)
      TextDiagram.rect('', parts: context.parts)
    end

    def child_nodes
      []
    end

    def to_h
      Serialization.add_attributes(
        { 'type' => 'block', 'width' => @width, 'up' => @up, 'height' => @height,
          'down' => @down, 'needs_space' => @needs_space }, self
      )
    end

    private

    def rectangle(x, y, width)
      { 'x' => x, 'y' => y - @up, 'width' => width, 'height' => @up + @height + @down }
    end
  end
end
