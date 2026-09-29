# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # Draws a choice where one or several branches may be taken.
  # @example
  #   MultipleChoice.new(0, 'any', 'a', 'b')
  class MultipleChoice < DiagramMultiContainer
    # @rbs default: Integer
    # @rbs type: String
    # @rbs *items: (DiagramItem | String)
    # @rbs return: void
    def initialize(default, type, *items, id: nil, cls: nil, attrs: {})
      super('g', items, nil, nil, id: id, cls: cls, data_attrs: attrs)
      raise InvalidArgument, "default must be between 0 and #{items.length - 1}" unless (0...items.length).cover?(default)
      raise InvalidArgument, "type must be 'any' or 'all'" unless %w[any all].include?(type)

      @default = default
      @type = type
      @needs_space = true
      @inner_width = @items.map(&:width).max
      @width = 30 + AR + @inner_width + AR + 20
      @up = @items[0].up
      @down = @items[-1].down
      @height = @items[default].height

      @items.each_with_index do |item, i|
        minimum =
          if [default - 1, default + 1].include?(i)
            10 + AR
          else
            AR
          end

        if i < default
          @up += [minimum, item.height + item.down + VS + @items[i + 1].up].max
        elsif i > default
          @down += [minimum, item.up + VS + @items[i - 1].down + @items[i - 1].height].max
        end
      end

      @down -= @items[default].height # already counted in @height
    end

    # @rbs return: String
    def to_s
      items = @items.map(&:to_s).join(', ')
      "MultipleChoice(#{@default}, #{@type}, #{items})"
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: MultipleChoice
    def format(x, y, width)
      left_gap, right_gap = determine_gaps(width, @width)

      # Hook up the two sides if self is narrower than its stated width.
      Path.new(x, y).h(left_gap).add(self)
      Path.new(x + left_gap + @width, y + @height).h(right_gap).add(self)
      x += left_gap

      default = @items[@default]

      # Do the elements that curve above
      above = @items[0...@default].reverse
      distance_from_y = 0
      distance_from_y = [10 + AR, default.up + VS + above.first.down + above.first.height].max if above.any?

      double_enumerate(above).each do |i, ni, item|
        Path.new(x + 30, y).up(distance_from_y - AR).arc('wn').add(self)
        item.format(x + 30 + AR, y - distance_from_y, @inner_width).add(self)
        Path.new(x + 30 + AR + @inner_width, y - distance_from_y + item.height)
            .arc('ne')
            .down(distance_from_y - item.height + default.height - AR - 10)
            .add(self)
        distance_from_y += [AR, item.up + VS + above[i + 1].down + above[i + 1].height].max if ni < -1
      end

      # Do the straight-line path.
      Path.new(x + 30, y).right(AR).add(self)
      @items[@default].format(x + 30 + AR, y, @inner_width).add(self)
      Path.new(x + 30 + AR + @inner_width, y + @height).right(AR).add(self)

      # Do the elements that curve below
      below = @items[(@default + 1)..-1] || []
      distance_from_y = [10 + AR, default.height + default.down + VS + below.first.up].max if below.any?

      below.each_with_index do |item, i|
        Path.new(x + 30, y).down(distance_from_y - AR).arc('ws').add(self)
        item.format(x + 30 + AR, y + distance_from_y, @inner_width).add(self)
        Path.new(x + 30 + AR + @inner_width, y + distance_from_y + item.height)
            .arc('se')
            .up(distance_from_y - AR + item.height - default.height - 10)
            .add(self)

        distance_from_y += [AR, item.height + item.down + VS + (below[i + 1]&.up || 0)].max
      end

      text = DiagramItem.new('g', attrs: { 'class' => 'diagram-text' }).add(self)
      DiagramItem.new(
        'title',
        text: @type == 'any' ? 'take one or more branches, once each, in any order' : 'take all branches, once each, in any order'
      ).add(text)

      DiagramItem.new(
        'path',
        attrs: {
          'd' => "M #{x + 30} #{y - 10} h -26 a 4 4 0 0 0 -4 4 v 12 a 4 4 0 0 0 4 4 h 26 z",
          'class' => 'diagram-text'
        }
      ).add(text)

      DiagramItem.new(
        'text',
        text: @type == 'any' ? '1+' : 'all',
        attrs: { 'x' => x + 15, 'y' => y + 4, 'class' => 'diagram-text' }
      ).add(text)

      DiagramItem.new(
        'path',
        attrs: {
          'd' => "M #{x + @width - 20} #{y - 10} h 16 a 4 4 0 0 1 4 4 v 12 a 4 4 0 0 1 -4 4 h -16 z",
          'class' => 'diagram-text'
        }
      ).add(text)

      DiagramItem.new(
        'text',
        text: '↺',
        attrs: { 'x' => x + @width - 10, 'y' => y + 4, 'class' => 'diagram-arrow' }
      ).add(text)

      self
    end

    # @rbs return: TextDiagram
    def text_diagram
      multi_repeat = TextDiagram.get_parts(['multi_repeat']).first
      any_all = TextDiagram.rect(@type == 'any' ? '1+' : 'all')
      diagram_td = Choice.new(@default, *@items).text_diagram
      repeat_td = TextDiagram.rect(multi_repeat)
      diagram_td = any_all.append_right(diagram_td, '')
      diagram_td.append_right(repeat_td, '')
    end

    def measure(context)
      items = @items.map { |item| context.metrics(item) }
      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      width = 30 + arc + items.map(&:width).max + arc + 20
      up = items.first.up
      down = items.last.down
      height = items[@default].height

      items.each_with_index do |item, index|
        minimum = [@default - 1, @default + 1].include?(index) ? 10 + arc : arc
        if index < @default
          up += [minimum, item.height + item.down + separation + items[index + 1].up].max
        elsif index > @default
          down += [minimum, item.up + separation + items[index - 1].down + items[index - 1].height].max
        end
      end
      down -= items[@default].height
      Metrics.new(width: width, up: up, height: height, down: down, needs_space: true)
    end

    def render_svg(context, x, y, width)
      metrics = context.metrics(self)
      items = @items.map { |item| context.metrics(item) }
      arc = context.options.arc_radius
      inner_width = items.map(&:width).max
      left_gap, right_gap = context.gaps(width, metrics.width)
      group = Svg::Element.new('g', @attrs.dup)
      group << svg_path(Svg::PathData.new(x, y).h(left_gap))
      group << svg_path(Svg::PathData.new(x + left_gap + metrics.width, y + metrics.height).h(right_gap))
      x += left_gap

      render_svg_above(context, group, x, y, inner_width)
      group << svg_path(Svg::PathData.new(x + 30, y).h(arc))
      group << context.render_svg(@items[@default], x + 30 + arc, y, inner_width)
      group << svg_path(Svg::PathData.new(x + 30 + arc + inner_width, y + metrics.height).h(arc))
      render_svg_below(context, group, x, y, inner_width)
      group << render_svg_annotation(context, x, y, metrics.width)
      group
    end

    def render_text(context)
      any_all = TextDiagram.rect(@type == 'any' ? '1+' : 'all', parts: context.parts)
      diagram = Choice.new(@default, *@items).render_text(context)
      repeat = TextDiagram.rect(context.parts.fetch('multi_repeat'), parts: context.parts)
      any_all.append_right(diagram, '').append_right(repeat, '')
    end

    def child_nodes
      @items.dup
    end

    private

    def svg_path(data)
      Svg::Element.new('path', { 'd' => data }, self_closing: true)
    end

    def render_svg_above(context, group, x, y, inner_width)
      above = @items[0...@default].reverse
      return if above.empty?

      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      default = context.metrics(@items[@default])
      first = context.metrics(above.first)
      distance = [10 + arc, default.up + separation + first.down + first.height].max
      double_enumerate(above).each do |index, negative_index, item|
        child = context.metrics(item)
        group << svg_path(Svg::PathData.new(x + 30, y, arc_radius: arc).v(-[0, distance - arc].max).arc('wn'))
        group << context.render_svg(item, x + 30 + arc, y - distance, inner_width)
        return_path = Svg::PathData.new(x + 30 + arc + inner_width, y - distance + child.height, arc_radius: arc)
                                   .arc('ne').v([0, distance - child.height + default.height - arc - 10].max)
        group << svg_path(return_path)
        if negative_index < -1
          following = context.metrics(above[index + 1])
          distance += [arc, child.up + separation + following.down + following.height].max
        end
      end
    end

    def render_svg_below(context, group, x, y, inner_width)
      below = @items[(@default + 1)..-1] || []
      return if below.empty?

      arc = context.options.arc_radius
      separation = context.options.vertical_separation
      default = context.metrics(@items[@default])
      distance = [10 + arc, default.height + default.down + separation + context.metrics(below.first).up].max
      below.each_with_index do |item, index|
        child = context.metrics(item)
        group << svg_path(Svg::PathData.new(x + 30, y, arc_radius: arc).v([0, distance - arc].max).arc('ws'))
        group << context.render_svg(item, x + 30 + arc, y + distance, inner_width)
        return_path = Svg::PathData.new(x + 30 + arc + inner_width, y + distance + child.height, arc_radius: arc)
                                   .arc('se').v(-[0, distance - arc + child.height - default.height - 10].max)
        group << svg_path(return_path)
        following = below[index + 1]
        distance += [arc, child.height + child.down + separation + (following ? context.metrics(following).up : 0)].max
      end
    end

    def render_svg_annotation(context, x, y, width)
      group = Svg::Element.new('g', { 'class' => 'diagram-text' })
      key = @type == 'any' ? :multiple_choice_any_tooltip : :multiple_choice_all_tooltip
      title = I18n.t(key, locale: context.options.locale)
      group << Svg::Element.new('title', {}, [Svg::TextNode.new(title)])
      left_path = {
        'd' => "M #{x + 30} #{y - 10} h -26 a 4 4 0 0 0 -4 4 v 12 a 4 4 0 0 0 4 4 h 26 z",
        'class' => 'diagram-text'
      }
      group << Svg::Element.new('path', left_path)
      group << Svg::Element.new('text', { 'x' => x + 15, 'y' => y + 4, 'class' => 'diagram-text' },
                                [Svg::TextNode.new(@type == 'any' ? '1+' : 'all')])
      right_path = {
        'd' => "M #{x + width - 20} #{y - 10} h 16 a 4 4 0 0 1 4 4 v 12 a 4 4 0 0 1 -4 4 h -16 z",
        'class' => 'diagram-text'
      }
      group << Svg::Element.new('path', right_path)
      group << Svg::Element.new('text', { 'x' => x + width - 10, 'y' => y + 4, 'class' => 'diagram-arrow' },
                                [Svg::TextNode.new('↺')])
      group
    end

    def double_enumerate(seq)
      length = seq.length
      seq.each_with_index.map { |item, i| [i, i - length, item] }
    end
  end
end
