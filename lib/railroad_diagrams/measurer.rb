# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Measurer
    class Monospace
      def initialize(options)
        @options = options
      end

      def width(text, role = :label)
        unit = case role
               when :label then @options.char_width
               when :comment then @options.comment_char_width
               else raise InvalidArgument, "unknown text role: #{role.inspect}"
               end
        Unicode::DisplayWidth.of(text, ambiguous: @options.ambiguous_width) * unit
      end
    end
  end
end
