# frozen_string_literal: true

add('short alternating branches', Diagram.new(AlternatingSequence.new(Skip.new, Skip.new)))
add('tall horizontal choice', Diagram.new(HorizontalChoice.new(Stack.new('a', 'b'), 'c')))
