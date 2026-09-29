# frozen_string_literal: true

# Loaded only by the DSL parity spec; the regular examples collector ignores it.
if respond_to?(:add_dsl)
  extend RailroadDiagrams::DSL # rubocop:disable Style/MixinUsage

  add_dsl('test choice up',
          diagram(
            choice(
              group(
                choice(
                  skip,
                  group(
                    stack(skip, skip),
                    label: 'inner'
                  ), default: 1
                ),
                label: 'top'
              ),
              group(
                choice(
                  skip,
                  group(
                    stack(skip, skip),
                    label: 'inner'
                  ), default: 1
                ),
                label: 'top'
              ),
              skip, default: 2
            )
          ))

  add_dsl('test choice down',
          diagram(
            choice(
              group(
                choice(
                  skip,
                  group(
                    stack(t('abc'), skip),
                    label: 'inner'
                  ), default: 0
                ),
                label: 'top'
              ),
              t('xyz'), default: 0
            )
          ))

  add_dsl('comment',
          diagram(
            '/*',
            zero_or_more(
              nt('anything but * followed by /')
            ),
            '*/'
          ))

  add_dsl('newline', diagram(choice('\\n', '\\r\\n', '\\r', '\\f', default: 0)))

  add_dsl('whitespace', diagram(choice('space', '\\t', nt('newline'), default: 0)))

  add_dsl('hex digit', diagram(nt('0-9 a-f or A-F')))

  add_dsl('escape',
          diagram(
            '\\',
            choice(
              nt('not newline or hex digit'),
              seq(
                one_or_more(nt('hex digit'), comment('1-6 times')),
                opt(nt('whitespace'), skip: 'skip')
              ), default: 0
            )
          ))

  add_dsl('<whitespace-token>', diagram(one_or_more(nt('whitespace'))))

  add_dsl('ws*', diagram(zero_or_more(nt('<whitespace-token>'))))

  add_dsl('<ident-token>',
          diagram(
            choice(skip, '-', default: 0),
            choice(nt('a-z A-Z _ or non-ASCII'), nt('escape'), default: 0),
            zero_or_more(
              choice(
                nt('a-z A-Z 0-9 _ - or non-ASCII'), nt('escape'), default: 0
              )
            )
          ))

  add_dsl('<function-token>',
          diagram(
            nt('<ident-token>'), '('
          ))

  add_dsl('<at-keyword-token>',
          diagram(
            '@', nt('<ident-token>')
          ))

  add_dsl('<hash-token>',
          diagram(
            '#',
            one_or_more(
              choice(
                nt('a-z A-Z 0-9 _ - or non-ASCII'),
                nt('escape'), default: 0
              )
            )
          ))

  add_dsl('<string-token>',
          diagram(
            choice(
              seq(
                '"',
                zero_or_more(
                  choice(
                    nt('not " \\ or newline'),
                    nt('escape'),
                    seq('\\', nt('newline')), default: 0
                  )
                ),
                '"'
              ),
              seq(
                '\'',
                zero_or_more(
                  choice(
                    nt("not ' \\ or newline"),
                    nt('escape'),
                    seq('\\', nt('newline')), default: 0
                  )
                ),
                '\''
              ), default: 0
            )
          ))

  add_dsl('<url-token>',
          diagram(
            nt('<ident-token "url">'),
            '(',
            nt('ws*'),
            opt(
              seq(
                choice(nt('url-unquoted'), nt('STRING'), default: 0),
                nt('ws*')
              )
            ),
            ')'
          ))

  add_dsl('url-unquoted',
          diagram(
            one_or_more(
              choice(
                nt('not " \' ( ) \\ whitespace or non-printable'),
                nt('escape'), default: 0
              )
            )
          ))

  add_dsl('<number-token>',
          diagram(
            choice('+', skip, '-', default: 1),
            choice(
              seq(
                one_or_more(nt('digit')),
                '.',
                one_or_more(nt('digit'))
              ),
              one_or_more(nt('digit')),
              seq(
                '.',
                one_or_more(nt('digit'))
              ), default: 0
            ),
            choice(
              skip,
              seq(
                choice('e', 'E', default: 0),
                choice('+', skip, '-', default: 1),
                one_or_more(nt('digit'))
              ), default: 0
            )
          ))

  add_dsl('<dimension-token>',
          diagram(
            nt('<number-token>'), nt('<ident-token>')
          ))

  add_dsl('<percentage-token>', diagram(
                                  nt('<number-token>'), '%'
                                ))

  add_dsl(
    '<unicode-range-token>',
    diagram(
      choice(
        'U',
        'u', default: 0
      ),
      '+',
      choice(
        seq(
          one_or_more(
            nt('hex digit'),
            comment('1-6 times')
          )
        ),
        seq(
          zero_or_more(nt('hex digit'), comment('1-5 times')),
          one_or_more('?', comment('1 to (6 - digits) times'))
        ),
        seq(
          one_or_more(nt('hex digit'), comment('1-6 times')),
          '-',
          one_or_more(nt('hex digit'), comment('1-6 times'))
        ), default: 0
      )
    )
  )

  add_dsl(
    'Stylesheet',
    diagram(
      zero_or_more(
        choice(
          nt('<CDO-token>'), nt('<CDC-token>'), nt('<whitespace-token>'),
          nt('Qualified rule'), nt('At-rule'), default: 3
        )
      )
    )
  )

  add_dsl(
    'Rule list',
    diagram(
      zero_or_more(
        choice(
          nt('<whitespace-token>'), nt('Qualified rule'), nt('At-rule'), default: 1
        )
      )
    )
  )

  add_dsl('At-rule',
          diagram(
            nt('<at-keyword-token>'), zero_or_more(nt('Component value')),
            choice(nt('{} block'), ';', default: 0)
          ))

  add_dsl('Qualified rule',
          diagram(
            zero_or_more(nt('Component value')),
            nt('{} block')
          ))

  add_dsl('Declaration list',
          diagram(
            nt('ws*'),
            choice(
              seq(
                opt(nt('Declaration')),
                opt(seq(';', nt('Declaration list')))
              ),
              seq(
                nt('At-rule'),
                nt('Declaration list')
              ), default: 0
            )
          ))

  add_dsl('Declaration',
          diagram(
            nt('<ident-token>'), nt('ws*'), ':',
            zero_or_more(nt('Component value')), opt(nt('!important'))
          ))

  add_dsl('!important',
          diagram(
            '!', nt('ws*'), nt('<ident-token "important">'), nt('ws*')
          ))

  add_dsl('Component value',
          diagram(
            choice(
              nt('Preserved token'),
              nt('{} block'),
              nt('() block'),
              nt('[] block'),
              nt('Function block'), default: 0
            )
          ))

  add_dsl('{} block', diagram('{', zero_or_more(nt('Component value')), '}'))
  add_dsl('() block', diagram('(', zero_or_more(nt('Component value')), ')'))
  add_dsl('[] block', diagram('[', zero_or_more(nt('Component value')), ']'))

  add_dsl('Function block',
          diagram(
            nt('<function-token>'),
            zero_or_more(nt('Component value')),
            ')'
          ))

  add_dsl('glob pattern',
          diagram(
            alt(
              nt('ident'),
              '*'
            )
          ))

  add_dsl('SQL',
          diagram(
            stack(
              seq(
                'SELECT',
                opt('DISTINCT', skip: 'skip'),
                choice(
                  '*',
                  one_or_more(
                    seq(
                      nt('expression'),
                      opt(seq('AS', nt('output_name')))
                    ),
                    ','
                  ), default: 0
                ),
                'FROM',
                one_or_more(nt('from_item'), ','),
                opt(seq('WHERE', nt('condition')))
              ),
              seq(
                opt(seq('GROUP BY', nt('expression'))),
                opt(seq('HAVING', nt('condition'))),
                opt(
                  seq(
                    choice('UNION', 'INTERSECT', 'EXCEPT', default: 0),
                    opt('ALL'),
                    nt('select')
                  )
                )
              ),
              seq(
                opt(
                  seq(
                    'ORDER BY',
                    one_or_more(seq(nt('expression'), choice(skip, 'ASC', 'DESC', default: 0)),
                                ',')
                  )
                ),
                opt(
                  seq(
                    'LIMIT',
                    choice(nt('count'), 'ALL', default: 0)
                  )
                ),
                opt(seq('OFFSET', nt('start'), opt('ROWS')))
              )
            )
          ))

  add_dsl('Group example',
          diagram(
            'foo',
            zero_or_more(
              group(
                stack('foo', 'bar'),
                label: 'label'
              )
            ),
            'bar'
          ))

  add_dsl('Class example',
          diagram(
            'foo',
            t('blue', cls: 'blue'),
            nt('blue', cls: 'blue'),
            comment('blue', cls: 'blue')
          ))

  add_dsl('rr-alternatingsequence',
          diagram(
            alt(
              'foo',
              'bar'
            )
          ))

  add_dsl('rr-choice',
          diagram(
            choice('1', '2', '3', default: 1)
          ))

  add_dsl('rr-group',
          diagram(
            t('foo'),
            group(
              choice(nt('option 1'), nt('or two'), default: 0)
            ),
            t('bar')
          ))

  add_dsl('rr-horizontalchoice',
          diagram(
            hchoice(
              choice('0', '1', '2', '3', '4', default: 2),
              choice('5', '6', '7', '8', '9', default: 2),
              choice('a', 'b', 'c', 'd', 'e', default: 2)
            )
          ))

  add_dsl('rr-multchoice',
          diagram(
            mchoice('all', '1', '2', '3', default: 1)
          ))

  add_dsl('rr-oneormore',
          diagram(
            one_or_more('foo', 'bar')
          ))

  add_dsl('rr-optional',
          diagram(
            opt('foo'),
            opt('bar', skip: true)
          ))

  add_dsl('rr-optionalsequence',
          diagram(
            oseq('1', '2', '3')
          ))

  add_dsl('rr-sequence',
          diagram(
            seq('1', '2', '3')
          ))

  add_dsl('rr-stack',
          diagram(
            stack(
              '1',
              '2',
              '3'
            )
          ))

  add_dsl('rr-title',
          diagram(
            stack(
              t('Generate'),
              t('some')
            ),
            one_or_more(nt('railroad diagrams'), comment('and more'))
          ))

  add_dsl('rr-zeroormore-1',
          diagram(
            zero_or_more('foo', comment('bar'))
          ))

  add_dsl('rr-zeroormore-2',
          diagram(
            zero_or_more('foo', comment('bar')),
            zero_or_more('foo', comment('bar'), skip: true)
          ))

  add_dsl('complicated-horizontalchoice-1',
          diagram(
            hchoice(
              choice('1', '2', '3', '4', '5', default: 0),
              choice('1', '2', '3', '4', '5', default: 4),
              choice('1', '2', '3', '4', '5', default: 2),
              choice('1', '2', '3', '4', '5', default: 3),
              choice('1', '2', '3', '4', '5', default: 1)
            ),
            hchoice('1', '2', '3', '4', '5')
          ))

  add_dsl('complicated-horizontalchoice-2',
          diagram(
            hchoice(
              choice('1', '2', '3', '4', default: 0),
              '4',
              choice('1', '2', '3', '4', default: 3)
            )
          ))

  add_dsl('complicated-horizontalchoice-3',
          diagram(
            hchoice(
              choice('1', '2', '3', '4', default: 0),
              stack('1', '2', '3'),
              choice('1', '2', '3', '4', default: 3)
            )
          ))

  add_dsl('complicated-horizontalchoice-4',
          diagram(
            hchoice(
              choice('1', '2', '3', '4', default: 0),
              choice('1', '2', '3', '4', default: 3),
              stack('1', '2', '3')
            )
          ))

  add_dsl('complicated-horizontalchoice-5',
          diagram(
            hchoice(
              stack('1', '2', '3'),
              choice('1', '2', '3', '4', default: 0),
              choice('1', '2', '3', '4', default: 3)
            )
          ))

  add_dsl('single-stack',
          diagram(
            stack('1')
          ))

  add_dsl('complicated-optionalsequence-1',
          diagram(
            oseq('1', choice('2', '3', '4', '5', default: 2), stack('6', '7', '8', '9', '10'), '11')
          ))

  add_dsl('labeled-start',
          diagram(
            Start.new(label: 'Labeled Start'),
            seq('1', '2', '3')
          ))

  add_dsl('complex',
          diagram(
            seq('1', '2', '3'),
            type: 'complex'
          ))

  add_dsl('simple',
          diagram(
            seq('1', '2', '3'),
            type: 'simple'
          ))

end
