# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Text
    module Parts
      UNICODE = {
        'cross_diag' => '╳',
        'corner_bot_left' => '└',
        'corner_bot_right' => '┘',
        'corner_top_left' => '┌',
        'corner_top_right' => '┐',
        'cross' => '┼',
        'left' => '│',
        'line' => '─',
        'line_vertical' => '│',
        'multi_repeat' => '↺',
        'rect_bot' => '─',
        'rect_bot_dashed' => '┄',
        'rect_bot_left' => '└',
        'rect_bot_right' => '┘',
        'rect_left' => '│',
        'rect_left_dashed' => '┆',
        'rect_right' => '│',
        'rect_right_dashed' => '┆',
        'rect_top' => '─',
        'rect_top_dashed' => '┄',
        'rect_top_left' => '┌',
        'rect_top_right' => '┐',
        'repeat_bot_left' => '╰',
        'repeat_bot_right' => '╯',
        'repeat_left' => '│',
        'repeat_right' => '│',
        'repeat_top_left' => '╭',
        'repeat_top_right' => '╮',
        'right' => '│',
        'roundcorner_bot_left' => '╰',
        'roundcorner_bot_right' => '╯',
        'roundcorner_top_left' => '╭',
        'roundcorner_top_right' => '╮',
        'roundrect_bot' => '─',
        'roundrect_bot_dashed' => '┄',
        'roundrect_bot_left' => '╰',
        'roundrect_bot_right' => '╯',
        'roundrect_left' => '│',
        'roundrect_left_dashed' => '┆',
        'roundrect_right' => '│',
        'roundrect_right_dashed' => '┆',
        'roundrect_top' => '─',
        'roundrect_top_dashed' => '┄',
        'roundrect_top_left' => '╭',
        'roundrect_top_right' => '╮',
        'separator' => '─',
        'tee_left' => '┤',
        'tee_right' => '├'
      }.freeze

      UNICODE_SQUARE = UNICODE.transform_values { |value| value.tr('╭╮╰╯', '┌┐└┘').freeze }.freeze

      ASCII = {
        'cross_diag' => 'X',
        'corner_bot_left' => '\\',
        'corner_bot_right' => '/',
        'corner_top_left' => '/',
        'corner_top_right' => '\\',
        'cross' => '+',
        'left' => '|',
        'line' => '-',
        'line_vertical' => '|',
        'multi_repeat' => '&',
        'rect_bot' => '-',
        'rect_bot_dashed' => '-',
        'rect_bot_left' => '+',
        'rect_bot_right' => '+',
        'rect_left' => '|',
        'rect_left_dashed' => '|',
        'rect_right' => '|',
        'rect_right_dashed' => '|',
        'rect_top' => '-',
        'rect_top_dashed' => '-',
        'rect_top_left' => '+',
        'rect_top_right' => '+',
        'repeat_bot_left' => '\\',
        'repeat_bot_right' => '/',
        'repeat_left' => '|',
        'repeat_right' => '|',
        'repeat_top_left' => '/',
        'repeat_top_right' => '\\',
        'right' => '|',
        'roundcorner_bot_left' => '\\',
        'roundcorner_bot_right' => '/',
        'roundcorner_top_left' => '/',
        'roundcorner_top_right' => '\\',
        'roundrect_bot' => '-',
        'roundrect_bot_dashed' => '-',
        'roundrect_bot_left' => '\\',
        'roundrect_bot_right' => '/',
        'roundrect_left' => '|',
        'roundrect_left_dashed' => '|',
        'roundrect_right' => '|',
        'roundrect_right_dashed' => '|',
        'roundrect_top' => '-',
        'roundrect_top_dashed' => '-',
        'roundrect_top_left' => '/',
        'roundrect_top_right' => '\\',
        'separator' => '-',
        'tee_left' => '|',
        'tee_right' => '|'
      }.freeze

      module_function

      def for(charset)
        case charset
        when :unicode then UNICODE
        when :unicode_square then UNICODE_SQUARE
        when :ascii then ASCII
        else raise InvalidArgument, "unknown text charset: #{charset.inspect}"
        end
      end
    end
  end
end
