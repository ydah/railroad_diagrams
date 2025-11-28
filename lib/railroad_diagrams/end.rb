# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class End < DiagramItem
    # @rbs type: String
    # @rbs return: void
    def initialize(type = 'simple')
      super('path')
      @width = 20
      @up = 10
      @down = 10
      @type = type
    end

    # @rbs return: String
    def to_s
      "End(type=#{@type})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs _width: Numeric
    # @rbs return: End
    def format(x, y, _width)
      @attrs['d'] =
        if @type == 'simple'
          "M #{x} #{y} h 20 m -10 -10 v 20 m 10 -20 v 20"
        else
          "M #{x} #{y} h 20 m 0 -10 v 20"
        end
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      cross, line, tee_left = TextDiagram.get_parts(%w[cross line tee_left])
      end_node =
        if @type == 'simple'
          line + cross + tee_left
        else
          line + tee_left
        end

      TextDiagram.new(0, 0, [end_node])
    end
  end
end
