# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Svg
    class PathData
      def initialize(x, y, arc_radius: AR)
        @arc_radius = arc_radius
        @commands = [[:M, x, y]]
      end

      def h(value)
        @commands << [:h, value]
        self
      end

      def v(value)
        @commands << [:v, value]
        self
      end

      def l(x, y)
        @commands << [:l, x, y]
        self
      end

      def m(x, y)
        @commands << [:m, x, y]
        self
      end

      def arc(sweep)
        x = @arc_radius
        y = @arc_radius
        x *= -1 if sweep[0] == 'e' || sweep[1] == 'w'
        y *= -1 if sweep[0] == 's' || sweep[1] == 'n'
        clockwise = %w[ne es sw wn].include?(sweep) ? 1 : 0
        @commands << [:a, @arc_radius, @arc_radius, 0, 0, clockwise, x, y]
        self
      end

      def arc_8(start, dir) # rubocop:disable Naming/VariableNumber
        half_diagonal = 1 / Math.sqrt(2) * @arc_radius
        complement = @arc_radius - half_diagonal
        a = half_diagonal
        b = complement
        # Preserve the legacy direction table and its exact floating-point arithmetic.
        # rubocop:disable-next Lint/DuplicateBranch
        offset = case start + dir
                 when 'ncw' then [a, b]
                 when 'necw' then [b, a]
                 when 'ecw' then [-b, a]
                 when 'secw' then [-a, b]
                 when 'scw' then [-a, -b]
                 when 'swcw' then [-b, -a]
                 when 'wcw' then [b, -a]
                 when 'nwcw' then [a, -b]
                 when 'nccw' then [-a, b]
                 when 'nwccw' then [-b, a]
                 when 'wccw' then [b, a]
                 when 'swccw' then [a, b]
                 when 'sccw' then [a, -b]
                 when 'seccw' then [b, -a]
                 when 'eccw' then [-b, -a]
                 when 'neccw' then [-a, -b]
                 end
        raise ArgumentError, 'invalid arc direction' unless offset

        clockwise = dir == 'cw' ? 1 : 0
        @commands << [:a8, @arc_radius, @arc_radius, 0, 0, clockwise, *offset]
        self
      end

      def optimize!
        # @type var optimized: Array[untyped]
        optimized = []
        @commands.each do |command|
          type, value = command
          movement = %i[h v].include?(type)
          if movement && value.zero?
            next
          elsif movement && optimized.last && optimized.last.first == type
            combined = optimized.pop[1] + value
            optimized << [type, combined] unless combined.zero?
          else
            optimized << command
          end
        end
        @commands = optimized
        self
      end

      def to_s(number_format = nil)
        format_number = number_format || ->(value) { NumberFormat.call(value, nil, kind: :path) }
        @commands.map do |type, *values|
          separator = type == :a8 ? ' ' : ''
          letter = type == :a8 ? 'a' : type.to_s
          "#{letter}#{separator}#{values.map { |value| format_number.call(value) }.join(' ')}"
        end.join
      end
    end
  end
end
