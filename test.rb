# frozen_string_literal: true

add('test choice up',
    Diagram.new(
      Choice.new(
        2,
        Group.new(
          Choice.new(
            1,
            Skip.new,
            Group.new(
              Stack.new(Skip.new, Skip.new),
              'inner'
            )
          ),
          'top'
        ),
        Group.new(
          Choice.new(
            1,
            Skip.new,
            Group.new(
              Stack.new(Skip.new, Skip.new),
              'inner'
            )
          ),
          'top'
        ),
        Skip.new
      )
    ))

add('test choice down',
    Diagram.new(
      Choice.new(
        0,
        Group.new(
          Choice.new(
            0,
            Skip.new,
            Group.new(
              Stack.new(Terminal.new('abc'), Skip.new),
              'inner'
            )
          ),
          'top'
        ),
        Terminal.new('xyz')
      )
    ))

add('comment',
    Diagram.new(
      '/*',
      ZeroOrMore.new(
        NonTerminal.new('anything but * followed by /')
      ),
      '*/'
    ))

add('newline', Diagram.new(Choice.new(0, '\\n', '\\r\\n', '\\r', '\\f')))

add('whitespace', Diagram.new(Choice.new(
                                0, 'space', '\\t', NonTerminal.new('newline')
                              )))

add('hex digit', Diagram.new(NonTerminal.new('0-9 a-f or A-F')))

add('escape',
    Diagram.new(
      '\\',
      Choice.new(
        0,
        NonTerminal.new('not newline or hex digit'),
        Sequence.new(
          OneOrMore.new(NonTerminal.new('hex digit'), Comment.new('1-6 times')),
          Optional.new(NonTerminal.new('whitespace'), 'skip')
        )
      )
    ))

add('<whitespace-token>', Diagram.new(OneOrMore.new(NonTerminal.new('whitespace'))))

add('ws*', Diagram.new(ZeroOrMore.new(NonTerminal.new('<whitespace-token>'))))

add('<ident-token>',
    Diagram.new(
      Choice.new(0, Skip.new, '-'),
      Choice.new(0, NonTerminal.new('a-z A-Z _ or non-ASCII'), NonTerminal.new('escape')),
      ZeroOrMore.new(
        Choice.new(
          0,
          NonTerminal.new('a-z A-Z 0-9 _ - or non-ASCII'), NonTerminal.new('escape')
        )
      )
    ))

add('<function-token>',
    Diagram.new(
      NonTerminal.new('<ident-token>'), '('
    ))

add('<at-keyword-token>',
    Diagram.new(
      '@', NonTerminal.new('<ident-token>')
    ))

add('<hash-token>',
    Diagram.new(
      '#',
      OneOrMore.new(
        Choice.new(
          0,
          NonTerminal.new('a-z A-Z 0-9 _ - or non-ASCII'),
          NonTerminal.new('escape')
        )
      )
    ))

add('<string-token>',
    Diagram.new(
      Choice.new(
        0,
        Sequence.new(
          '"',
          ZeroOrMore.new(
            Choice.new(
              0,
              NonTerminal.new('not " \\ or newline'),
              NonTerminal.new('escape'),
              Sequence.new('\\', NonTerminal.new('newline'))
            )
          ),
          '"'
        ),
        Sequence.new(
          '\'',
          ZeroOrMore.new(
            Choice.new(
              0,
              NonTerminal.new("not ' \\ or newline"),
              NonTerminal.new('escape'),
              Sequence.new('\\', NonTerminal.new('newline'))
            )
          ),
          '\''
        )
      )
    ))

add('<url-token>',
    Diagram.new(
      NonTerminal.new('<ident-token "url">'),
      '(',
      NonTerminal.new('ws*'),
      Optional.new(
        Sequence.new(
          Choice.new(0, NonTerminal.new('url-unquoted'), NonTerminal.new('STRING')),
          NonTerminal.new('ws*')
        )
      ),
      ')'
    ))

add('url-unquoted',
    Diagram.new(
      OneOrMore.new(
        Choice.new(
          0,
          NonTerminal.new('not " \' ( ) \\ whitespace or non-printable'),
          NonTerminal.new('escape')
        )
      )
    ))

add('<number-token>',
    Diagram.new(
      Choice.new(1, '+', Skip.new, '-'),
      Choice.new(
        0,
        Sequence.new(
          OneOrMore.new(NonTerminal.new('digit')),
          '.',
          OneOrMore.new(NonTerminal.new('digit'))
        ),
        OneOrMore.new(NonTerminal.new('digit')),
        Sequence.new(
          '.',
          OneOrMore.new(NonTerminal.new('digit'))
        )
      ),
      Choice.new(
        0,
        Skip.new,
        Sequence.new(
          Choice.new(0, 'e', 'E'),
          Choice.new(1, '+', Skip.new, '-'),
          OneOrMore.new(NonTerminal.new('digit'))
        )
      )
    ))

add('<dimension-token>',
    Diagram.new(
      NonTerminal.new('<number-token>'), NonTerminal.new('<ident-token>')
    ))

add('<percentage-token>', Diagram.new(
                            NonTerminal.new('<number-token>'), '%'
                          ))

add(
  '<unicode-range-token>',
  Diagram.new(
    Choice.new(
      0,
      'U',
      'u'
    ),
    '+',
    Choice.new(
      0,
      Sequence.new(
        OneOrMore.new(
          NonTerminal.new('hex digit'),
          Comment.new('1-6 times')
        )
      ),
      Sequence.new(
        ZeroOrMore.new(NonTerminal.new('hex digit'), Comment.new('1-5 times')),
        OneOrMore.new('?', Comment.new('1 to (6 - digits) times'))
      ),
      Sequence.new(
        OneOrMore.new(NonTerminal.new('hex digit'), Comment.new('1-6 times')),
        '-',
        OneOrMore.new(NonTerminal.new('hex digit'), Comment.new('1-6 times'))
      )
    )
  )
)

add(
  'Stylesheet',
  Diagram.new(
    ZeroOrMore.new(
      Choice.new(
        3,
        NonTerminal.new('<CDO-token>'), NonTerminal.new('<CDC-token>'), NonTerminal.new('<whitespace-token>'),
        NonTerminal.new('Qualified rule'), NonTerminal.new('At-rule')
      )
    )
  )
)

add(
  'Rule list',
  Diagram.new(
    ZeroOrMore.new(
      Choice.new(
        1,
        NonTerminal.new('<whitespace-token>'), NonTerminal.new('Qualified rule'), NonTerminal.new('At-rule')
      )
    )
  )
)

add('At-rule',
    Diagram.new(
      NonTerminal.new('<at-keyword-token>'), ZeroOrMore.new(NonTerminal.new('Component value')),
      Choice.new(0, NonTerminal.new('{} block'), ';')
    ))

add('Qualified rule',
    Diagram.new(
      ZeroOrMore.new(NonTerminal.new('Component value')),
      NonTerminal.new('{} block')
    ))

add('Declaration list',
    Diagram.new(
      NonTerminal.new('ws*'),
      Choice.new(
        0,
        Sequence.new(
          Optional.new(NonTerminal.new('Declaration')),
          Optional.new(Sequence.new(';', NonTerminal.new('Declaration list')))
        ),
        Sequence.new(
          NonTerminal.new('At-rule'),
          NonTerminal.new('Declaration list')
        )
      )
    ))

add('Declaration',
    Diagram.new(
      NonTerminal.new('<ident-token>'), NonTerminal.new('ws*'), ':',
      ZeroOrMore.new(NonTerminal.new('Component value')), Optional.new(NonTerminal.new('!important'))
    ))

add('!important',
    Diagram.new(
      '!', NonTerminal.new('ws*'), NonTerminal.new('<ident-token "important">'), NonTerminal.new('ws*')
    ))

add('Component value',
    Diagram.new(
      Choice.new(
        0,
        NonTerminal.new('Preserved token'),
        NonTerminal.new('{} block'),
        NonTerminal.new('() block'),
        NonTerminal.new('[] block'),
        NonTerminal.new('Function block')
      )
    ))

add('{} block', Diagram.new('{', ZeroOrMore.new(NonTerminal.new('Component value')), '}'))
add('() block', Diagram.new('(', ZeroOrMore.new(NonTerminal.new('Component value')), ')'))
add('[] block', Diagram.new('[', ZeroOrMore.new(NonTerminal.new('Component value')), ']'))

add('Function block',
    Diagram.new(
      NonTerminal.new('<function-token>'),
      ZeroOrMore.new(NonTerminal.new('Component value')),
      ')'
    ))

add('glob pattern',
    Diagram.new(
      AlternatingSequence.new(
        NonTerminal.new('ident'),
        '*'
      )
    ))

add('SQL',
    Diagram.new(
      Stack.new(
        Sequence.new(
          'SELECT',
          Optional.new('DISTINCT', 'skip'),
          Choice.new(
            0,
            '*',
            OneOrMore.new(
              Sequence.new(
                NonTerminal.new('expression'),
                Optional.new(Sequence.new('AS', NonTerminal.new('output_name')))
              ),
              ','
            )
          ),
          'FROM',
          OneOrMore.new(NonTerminal.new('from_item'), ','),
          Optional.new(Sequence.new('WHERE', NonTerminal.new('condition')))
        ),
        Sequence.new(
          Optional.new(Sequence.new('GROUP BY', NonTerminal.new('expression'))),
          Optional.new(Sequence.new('HAVING', NonTerminal.new('condition'))),
          Optional.new(
            Sequence.new(
              Choice.new(0, 'UNION', 'INTERSECT', 'EXCEPT'),
              Optional.new('ALL'),
              NonTerminal.new('select')
            )
          )
        ),
        Sequence.new(
          Optional.new(
            Sequence.new(
              'ORDER BY',
              OneOrMore.new(Sequence.new(NonTerminal.new('expression'), Choice.new(0, Skip.new, 'ASC', 'DESC')),
                            ',')
            )
          ),
          Optional.new(
            Sequence.new(
              'LIMIT',
              Choice.new(0, NonTerminal.new('count'), 'ALL')
            )
          ),
          Optional.new(Sequence.new('OFFSET', NonTerminal.new('start'), Optional.new('ROWS')))
        )
      )
    ))

add('Group example',
    Diagram.new(
      'foo',
      ZeroOrMore.new(
        Group.new(
          Stack.new('foo', 'bar'),
          'label'
        )
      ),
      'bar'
    ))

add('Class example',
    Diagram.new(
      'foo',
      Terminal.new('blue', cls: 'blue'),
      NonTerminal.new('blue', cls: 'blue'),
      Comment.new('blue', cls: 'blue')
    ))

add('rr-alternatingsequence',
    Diagram.new(
      AlternatingSequence.new(
        'foo',
        'bar'
      )
    ))

add('rr-choice',
    Diagram.new(
      Choice.new(
        1, '1', '2', '3'
      )
    ))

add('rr-group',
    Diagram.new(
      Terminal.new('foo'),
      Group.new(
        Choice.new(
          0, NonTerminal.new('option 1'), NonTerminal.new('or two')
        )
      ),
      Terminal.new('bar')
    ))

add('rr-horizontalchoice',
    Diagram.new(
      HorizontalChoice.new(
        Choice.new(2, '0', '1', '2', '3', '4'),
        Choice.new(2, '5', '6', '7', '8', '9'),
        Choice.new(2, 'a', 'b', 'c', 'd', 'e')
      )
    ))

add('rr-multchoice',
    Diagram.new(
      MultipleChoice.new(1, 'all', '1', '2', '3')
    ))

add('rr-oneormore',
    Diagram.new(
      OneOrMore.new('foo', 'bar')
    ))

add('rr-optional',
    Diagram.new(
      Optional.new('foo'),
      Optional.new('bar', true)
    ))

add('rr-optionalsequence',
    Diagram.new(
      OptionalSequence.new('1', '2', '3')
    ))

add('rr-sequence',
    Diagram.new(
      Sequence.new('1', '2', '3')
    ))

add('rr-stack',
    Diagram.new(
      Stack.new(
        '1',
        '2',
        '3'
      )
    ))

add('rr-title',
    Diagram.new(
      Stack.new(
        Terminal.new('Generate'),
        Terminal.new('some')
      ),
      OneOrMore.new(NonTerminal.new('railroad diagrams'), Comment.new('and more'))
    ))

add('rr-zeroormore-1',
    Diagram.new(
      ZeroOrMore.new('foo', Comment.new('bar'))
    ))

add('rr-zeroormore-2',
    Diagram.new(
      ZeroOrMore.new('foo', Comment.new('bar')),
      ZeroOrMore.new('foo', Comment.new('bar'), true)
    ))

add('complicated-horizontalchoice-1',
    Diagram.new(
      HorizontalChoice.new(
        Choice.new(0, '1', '2', '3', '4', '5'),
        Choice.new(4, '1', '2', '3', '4', '5'),
        Choice.new(2, '1', '2', '3', '4', '5'),
        Choice.new(3, '1', '2', '3', '4', '5'),
        Choice.new(1, '1', '2', '3', '4', '5')
      ),
      HorizontalChoice.new('1', '2', '3', '4', '5')
    ))

add('complicated-horizontalchoice-2',
    Diagram.new(
      HorizontalChoice.new(
        Choice.new(0, '1', '2', '3', '4'),
        '4',
        Choice.new(3, '1', '2', '3', '4')
      )
    ))

add('complicated-horizontalchoice-3',
    Diagram.new(
      HorizontalChoice.new(
        Choice.new(0, '1', '2', '3', '4'),
        Stack.new('1', '2', '3'),
        Choice.new(3, '1', '2', '3', '4')
      )
    ))

add('complicated-horizontalchoice-4',
    Diagram.new(
      HorizontalChoice.new(
        Choice.new(0, '1', '2', '3', '4'),
        Choice.new(3, '1', '2', '3', '4'),
        Stack.new('1', '2', '3')
      )
    ))

add('complicated-horizontalchoice-5',
    Diagram.new(
      HorizontalChoice.new(
        Stack.new('1', '2', '3'),
        Choice.new(0, '1', '2', '3', '4'),
        Choice.new(3, '1', '2', '3', '4')
      )
    ))

add('single-stack',
    Diagram.new(
      Stack.new('1')
    ))

add('complicated-optionalsequence-1',
    Diagram.new(
      OptionalSequence.new('1', Choice.new(2, '2', '3', '4', '5'), Stack.new('6', '7', '8', '9', '10'), '11')
    ))

add('labeled-start',
    Diagram.new(
      Start.new(label: 'Labeled Start'),
      Sequence.new('1', '2', '3')
    ))

add('complex',
    Diagram.new(
      Sequence.new('1', '2', '3'),
      type: 'complex'
    ))

add('simple',
    Diagram.new(
      Sequence.new('1', '2', '3'),
      type: 'simple'
    ))
