# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Start < DiagramItem
    # @rbs type: String
    # @rbs label: String?
    # @rbs return: void
    def initialize(type = 'simple', label: nil)
      super('g')
      @width =
        if label
          [20, (label.length * CHAR_WIDTH) + 10].max
        else
          20
        end
      @up = 10
      @down = 10
      @type = type
      @label = label
    end

    # @rbs return: String
    def to_s
      "Start(#{@type}, label=#{@label})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs _width: Numeric
    # @rbs return: Start
    def format(x, y, _width)
      path = Path.new(x, y - 10)
      if @type == 'complex'
        path.down(20).m(0, -10).right(@width).add(self)
      else
        path.down(20).m(10, -20).down(20).m(-10, -10).right(@width).add(self)
      end
      if @label
        DiagramItem.new(
          'text',
          attrs: {
            'x' => x,
            'y' => y - 15,
            'style' => 'text-anchor:start'
          },
          text: @label
        ).add(self)
      end
      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      cross, line, tee_right = TextDiagram.get_parts(%w[cross line tee_right])
      start =
        if @type == 'simple'
          tee_right + cross + line
        else
          tee_right + line
        end

      label_td = TextDiagram.new(0, 0, [])
      if @label
        label_td = TextDiagram.new(0, 0, [@label])
        start = TextDiagram.pad_r(start, label_td.width, line)
      end
      start_td = TextDiagram.new(0, 0, [start])
      label_td.append_below(start_td, [], move_entry: true, move_exit: true)
    end
  end
end
