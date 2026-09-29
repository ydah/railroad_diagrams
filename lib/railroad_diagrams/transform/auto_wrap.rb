# frozen_string_literal: true

module RailroadDiagrams
  module Transform
    module AutoWrap
      module_function

      def call(diagram, context, max_width:)
        unless max_width.is_a?(Numeric) && !max_width.is_a?(Complex) && max_width.finite? && max_width.positive?
          raise InvalidArgument, 'max_width must be a finite positive number'
        end
        return diagram if context.metrics(diagram).width + 40 <= max_width

        nodes = diagram.child_nodes
        first = nodes.first if nodes.first.is_a?(Start)
        last = nodes.last if nodes.last.is_a?(End)
        body = nodes[(first ? 1 : 0)...(last ? -1 : nodes.length)]
        return diagram if body.empty?

        edge_width = [first, last].compact.sum { |node| context.metrics(node).width }
        budget = max_width - 40 - edge_width - (context.options.arc_radius * 2) - 40
        items = flatten_wide_sequences(body, context, budget)
        rows = pack(items, context, budget)
        return diagram if rows.size < 2

        stack = Stack.new(*rows.map { |row| row.size == 1 ? row.first : Sequence.new(*row) })
        copy = diagram.dup
        styles = diagram.instance_variable_get(:@items).grep(Style)
        copy.instance_variable_set(:@items, [*styles, first, stack, last].compact)
        copy
      end

      def flatten_wide_sequences(items, context, budget)
        items.flat_map do |item|
          if item.is_a?(Sequence) && context.metrics(item).width > budget
            flatten_wide_sequences(item.child_nodes, context, budget)
          else
            [item]
          end
        end
      end

      def pack(items, context, budget)
        rows = [[]]
        width = 0
        items.each do |item|
          metrics = context.metrics(item)
          item_width = metrics.width + (metrics.needs_space ? 20 : 0)
          if !rows.last.empty? && width + item_width > budget
            rows << []
            width = 0
          end
          rows.last << item
          width += item_width
        end
        rows
      end
    end
  end
end
