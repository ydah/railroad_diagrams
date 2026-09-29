# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Svg
    module NumberFormat
      module_function

      def call(value, precision, kind: :attr)
        return value.to_s if value.is_a?(Integer)
        return legacy(value, kind) if precision.nil?

        rounded = value.round(precision)
        rounded = 0.0 if rounded.zero?
        return rounded.to_i.to_s if rounded == rounded.to_i

        Kernel.format("%.#{precision}f", rounded).sub(/0+\z/, '')
      end

      def legacy(value, kind)
        kind == :path ? value.to_s : RailroadDiagrams.format_number(value)
      end
    end
  end
end
