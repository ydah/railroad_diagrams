# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Group < DiagramItem
    # @rbs item: DiagramItem | String
    # @rbs label: (DiagramItem | String)?
    # @rbs return: void
    def initialize(item, label = nil)
      super('g')
      @item = wrap_string(item)

      @label =
        if label.is_a?(DiagramItem)
          label
        elsif label
          Comment.new(label)
        end

      item_width = @item.width + (@item.needs_space ? 20 : 0)
      label_width = @label ? @label.width : 0
      @width = [item_width, label_width, AR * 2].max

      @height = @item.height

      @box_up = [@item.up + VS, AR].max
      @up = @box_up
      @up += @label.up + @label.height + @label.down if @label

      @down = [@item.down + VS, AR].max

      @needs_space = true
    end

    # @rbs return: String
    def to_s
      "Group(#{@item}, label=#{@label})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: Group
    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
      x += left_gap

      DiagramItem.new(
        'rect',
        attrs: {
          'x' => x,
          'y' => y - @box_up,
          'width' => @width,
          'height' => @height + @box_up + @down,
          'rx' => AR,
          'ry' => AR,
          'class' => 'group-box'
        }
      ).add(self)

      @item.format(x, y, @width).add(self)
      @label&.format(x, y - (@box_up + @label.down + @label.height), @width)&.add(self)

      self
    end

    # @rbs callback: ^(DiagramItem) -> void
    # @rbs return: void
    def walk(callback)
      callback.call(self)
      item.walk(callback)
      label&.walk(callback)
    end

    # @rbs return: TextDiagram
    def text_diagram
      diagram_td = TextDiagram.round_rect(@item.text_diagram, dashed: true)
      if @label
        label_td = @label.text_diagram
        diagram_td = label_td.append_below(diagram_td, [], move_entry: true, move_exit: true).expand(0, 0, 1, 0)
      end
      diagram_td
    end
  end
end
