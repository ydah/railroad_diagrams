# frozen_string_literal: true

add('i18n Japanese', Diagram.new('日本語', NonTerminal.new('項目')))
add('i18n Chinese', Diagram.new('中文', Comment.new('说明')))
add('i18n Korean', Diagram.new('한국어'))
add('i18n emoji', Diagram.new('🚀', '👨‍👩‍👧', '🇯🇵'))
add('i18n combining', Diagram.new("e\u0301", '○'))
add('i18n spaces', Diagram.new('a    b'))
