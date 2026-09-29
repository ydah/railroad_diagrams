# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Text
    module Builder
      module_function

      def stack(diagrams, between_lines = [])
        width = diagrams.map(&:width).max || 0
        # @type var lines: Array[String]
        lines = []
        diagrams.each_with_index do |diagram, index|
          between_lines.each { |line| lines << TextDiagram.pad_r(line, width, ' ') } if index.positive?
          lines.concat(diagram.center(width).lines)
        end
        lines
      end

      def row(diagrams, separator)
        return TextDiagram.new(0, 0, []) if diagrams.empty?

        first_visible = diagrams.index { |diagram| diagram.height.positive? }
        return TextDiagram.new(0, 0, []) unless first_visible

        diagrams = diagrams[(first_visible - 1)..-1] if first_visible > 1

        tops = [0]
        diagrams.each_cons(2) do |left, right|
          tops << (tops.last + left.exit - right.entry)
        end
        first_row = tops.min
        tops.map! { |top| top - first_row }
        height = diagrams.each_with_index.map { |diagram, index| tops[index] + diagram.height }.max
        lines = Array.new(height) { String.new }
        separator_width = Unicode::DisplayWidth.of(separator)
        # @type var visible_joins: Array[bool]
        visible_joins = []
        prefix_bottom = tops.first + diagrams.first.height
        (0...(diagrams.length - 1)).each do |index|
          join_row = tops[index] + diagrams[index].exit
          prefix_bottom = [prefix_bottom, tops[index + 1] + diagrams[index + 1].height].max
          visible_joins << (prefix_bottom > join_row)
        end

        diagrams.each_with_index do |diagram, index|
          top = tops[index]
          height.times do |row_index|
            lines[row_index] << if row_index >= top && row_index < top + diagram.height
                                  diagram.lines[row_index - top]
                                else
                                  ' ' * diagram.width
                                end
            next if index == diagrams.length - 1

            lines[row_index] << (visible_joins[index] && row_index == top + diagram.exit ? separator : ' ' * separator_width)
          end
        end

        TextDiagram.new(tops.first + diagrams.first.entry, tops.last + diagrams.last.exit, lines)
      end
    end
  end
end
