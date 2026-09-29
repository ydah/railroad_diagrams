# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module I18n
    # rubocop:disable-next Style/FormatStringToken
    MESSAGES = {
      en: {
        multiple_choice_any_tooltip: 'take one or more branches, once each, in any order',
        multiple_choice_all_tooltip: 'take all branches, once each, in any order',
        repeat_exact: '%{count} times',
        repeat_range: '%{min}–%{max} times',
        repeat_min: '%{min}+ times',
        describe_terminal: '“%{text}”',
        describe_non_terminal: 'nonterminal %{text}',
        describe_comment: '%{text}',
        describe_sequence: 'in sequence: %{items}',
        describe_choice: 'one of: %{items}',
        describe_optional: 'optional %{item}',
        describe_one_or_more: 'repeat %{item} one or more times',
        describe_zero_or_more: 'repeat %{item} zero or more times',
        describe_multiple_choice_any: 'one or more of: %{items}',
        describe_multiple_choice_all: 'all of: %{items}',
        describe_group: '%{label}: %{item}',
        describe_skip: 'skip',
        describe_start: 'start',
        describe_end: 'end',
        describe_separator: ', ',
        describe_truncated: '…'
      }.freeze,
      ja: {
        multiple_choice_any_tooltip: '1つ以上の分岐を、それぞれ1回ずつ、任意の順序で通る',
        multiple_choice_all_tooltip: 'すべての分岐を、それぞれ1回ずつ、任意の順序で通る',
        repeat_exact: '%{count}回',
        repeat_range: '%{min}〜%{max}回',
        repeat_min: '%{min}回以上',
        describe_terminal: '「%{text}」',
        describe_non_terminal: '非終端記号「%{text}」',
        describe_comment: '%{text}',
        describe_sequence: '順に: %{items}',
        describe_choice: 'いずれか: %{items}',
        describe_optional: '省略可能な%{item}',
        describe_one_or_more: '%{item}を1回以上繰り返す',
        describe_zero_or_more: '%{item}を0回以上繰り返す',
        describe_multiple_choice_any: '1つ以上選択: %{items}',
        describe_multiple_choice_all: 'すべて選択: %{items}',
        describe_group: '%{label}: %{item}',
        describe_skip: 'スキップ',
        describe_start: '開始',
        describe_end: '終了',
        describe_separator: '、',
        describe_truncated: '…'
      }.freeze
    }.freeze

    module_function

    # @rbs key: Symbol
    # @rbs locale: Symbol
    # @rbs **values: untyped
    # @rbs return: String
    def t(key, locale: :en, **values)
      messages = MESSAGES[locale]
      raise InvalidArgument, "unknown locale: #{locale.inspect}" unless messages

      template = messages[key]
      raise InvalidArgument, "unknown translation key: #{key.inspect}" unless template

      expected = template.scan(/%\{([a-z_]+)\}/).flatten.map(&:to_sym)
      raise InvalidArgument, "wrong interpolation keys: expected #{expected.inspect}" unless expected.sort == values.keys.sort

      Kernel.format(template, values)
    end
  end
end
