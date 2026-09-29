# rbs_inline: enabled
# frozen_string_literal: true

require_relative 'tables'

module RailroadDiagrams
  module Unicode
    module DisplayWidth
      module_function

      def of(string, ambiguous: 1)
        raise InvalidArgument, 'ambiguous width must be 1 or 2' unless [1, 2].include?(ambiguous)

        return string.length if string.is_a?(String) && string.ascii_only? && !string.match?(/[[:cntrl:]]/)

        width = 0
        string.to_s.each_grapheme_cluster do |cluster|
          codepoints = cluster.codepoints
          first = codepoints.first
          next if first.nil? || first < 0x20 || (0x7F..0x9F).cover?(first)

          if emoji_cluster?(codepoints)
            width += 2
          elsif lookup(Tables::ZERO_WIDTH, first)
            next
          else
            value = lookup(Tables::EAST_ASIAN_WIDTH, first)
            width += value == 3 ? ambiguous : (value || 1)
          end
        end
        width
      end

      def lookup(ranges, codepoint)
        entry = ranges.bsearch { |range| range[1] >= codepoint }
        entry && entry[0] <= codepoint ? entry[2] : nil
      end

      def emoji_cluster?(codepoints)
        first = codepoints.first
        return true if codepoints.size == 2 && codepoints.all? { |cp| (0x1F1E6..0x1F1FF).cover?(cp) }
        return true if codepoints.include?(0xFE0F)
        return true if codepoints.include?(0x200D) && codepoints.any? { |cp| lookup(Tables::EXTENDED_PICTOGRAPHIC, cp) }

        lookup(Tables::EMOJI_PRESENTATION, first)
      end
    end
  end
end
