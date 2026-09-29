# frozen_string_literal: true

add('node-complex', ComplexDiagram.new('item'))
add('node-block', Diagram.new(Block.new))
add('node-repeat', Diagram.new(Repeat.new('item', min: 2, max: 4, separator: ',')))
add('node-list', Diagram.new(SeparatedList.new('item', ',')))
add('node-except', Diagram.new(Except.new('letter', CharClass.new('[0-9]'))))
add('node-char-class', Diagram.new(CharClass.new('[a-z]')))
add('node-special', Diagram.new(Special.new('any character')))
