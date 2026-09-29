require 'spec_helper'
require 'railroad_diagrams/builder'

RSpec.describe RailroadDiagrams::Builder do
  it 'builds the documented diagram with the same SVG as direct constructors' do # rubocop:disable RSpec/ExampleLength
    actual = RailroadDiagrams.diagram(title: 'SELECT') do
      seq 'SELECT', opt('DISTINCT'), list(:column, sep: ','), 'FROM', :table, opt(seq('WHERE', :expr))
    end
    expected = RailroadDiagrams::Diagram.new(
      RailroadDiagrams::Sequence.new(
        'SELECT', RailroadDiagrams::Optional.new('DISTINCT'),
        RailroadDiagrams::SeparatedList.new(RailroadDiagrams::NonTerminal.new('column'), RailroadDiagrams::Terminal.new(',')),
        'FROM', RailroadDiagrams::NonTerminal.new('table'),
        RailroadDiagrams::Optional.new(RailroadDiagrams::Sequence.new('WHERE', RailroadDiagrams::NonTerminal.new('expr')))
      ), title: 'SELECT'
    )
    expect(actual).to eq(expected)
    expect(actual.to_svg).to eq(expected.to_svg)
  end

  it 'supports zero-argument and builder-argument blocks' do
    expect(RailroadDiagrams.build { seq('a', :b) }).to be_a(RailroadDiagrams::Sequence)
    caller_self = Object.new
    caller_self.define_singleton_method(:symbol) { :b }
    result = caller_self.instance_exec { RailroadDiagrams.build { |dsl| dsl.seq('a', symbol) } }
    expect(result.child_nodes.last).to be_a(RailroadDiagrams::NonTerminal)
    expect { RailroadDiagrams.build }.to raise_error(RailroadDiagrams::InvalidArgument, /block/)
  end

  it 'coerces values recursively only through the DSL' do
    result = RailroadDiagrams.build { seq('a', :b, nil, ['c', :d]) }
    classes = [RailroadDiagrams::Terminal, RailroadDiagrams::NonTerminal, RailroadDiagrams::Skip, RailroadDiagrams::Sequence]
    expect(result.child_nodes.map(&:class)).to eq(classes)
    expect(result.child_nodes.last.child_nodes.map(&:class)).to eq(classes.first(2))
    expect { RailroadDiagrams.build { 42 } }.to raise_error(RailroadDiagrams::InvalidArgument, /Integer/)
    expect(RailroadDiagrams::Sequence.new(:b).child_nodes.first).to be_a(RailroadDiagrams::Terminal)
  end

  it 'accepts a custom coercion callback' do
    rule = ->(value) { RailroadDiagrams::Terminal.new(value.to_s) if value.is_a?(Integer) }
    result = RailroadDiagrams.build(coerce: rule) { seq(1, [2, :name]) }
    expect(result.child_nodes.first).to be_a(RailroadDiagrams::Terminal)
    expect(result.child_nodes.last.child_nodes.first).to be_a(RailroadDiagrams::Terminal)
    expect(result.child_nodes.last.child_nodes.last).to be_a(RailroadDiagrams::NonTerminal)
  end

  it 'uses the configured coercion callback' do
    original = RailroadDiagrams.default_options
    RailroadDiagrams.configure { |values| values[:coerce] = ->(value) { RailroadDiagrams::Terminal.new('number') if value == 42 } }
    expect(RailroadDiagrams.build { 42 }).to be_a(RailroadDiagrams::Terminal)
  ensure
    RailroadDiagrams.configure { |values| values.replace(original.to_h) } if original
  end

  it 'maps core shorthand methods to the existing constructors' do # rubocop:disable RSpec/ExampleLength
    builder = described_class.new
    cases = [
      [builder.t('a'), RailroadDiagrams::Terminal.new('a')],
      [builder.terminal('a'), RailroadDiagrams::Terminal.new('a')],
      [builder.nt(:a), RailroadDiagrams::NonTerminal.new('a')],
      [builder.non_terminal(:a), RailroadDiagrams::NonTerminal.new('a')],
      [builder.comment('a'), RailroadDiagrams::Comment.new('a')],
      [builder.stack('a', :b), RailroadDiagrams::Stack.new('a', RailroadDiagrams::NonTerminal.new('b'))],
      [builder.choice('a', 'b', default: 1), RailroadDiagrams::Choice.new(1, 'a', 'b')],
      [builder.hchoice('a', 'b'), RailroadDiagrams::HorizontalChoice.new('a', 'b')],
      [builder.mchoice(:any, 'a', 'b', default: 1), RailroadDiagrams::MultipleChoice.new(1, 'any', 'a', 'b')],
      [builder.opt('a', skip: true), RailroadDiagrams::Optional.new('a', skip: true)],
      [builder.zero_or_more('a', ',', skip: true), RailroadDiagrams::ZeroOrMore.new('a', ',', skip: true)],
      [builder.one_or_more('a', ','), RailroadDiagrams::OneOrMore.new('a', ',')],
      [builder.oseq('a', 'b'), RailroadDiagrams::OptionalSequence.new('a', 'b')],
      [builder.alt('a', 'b'), RailroadDiagrams::AlternatingSequence.new('a', 'b')],
      [builder.group('a', 'label'), RailroadDiagrams::Group.new('a', label: 'label')],
      [builder.skip, RailroadDiagrams::Skip.new]
    ]
    cases.each do |actual, expected|
      expect(RailroadDiagrams::Diagram.new(actual).to_svg).to eq(RailroadDiagrams::Diagram.new(expected).to_svg)
    end
  end

  it 'maps new-node shorthands to their constructors' do # rubocop:disable RSpec/ExampleLength
    builder = described_class.new
    separator = RailroadDiagrams::Terminal.new(',')
    cases = [
      [builder.repeat('a', min: 2, max: 3, separator: ','),
       RailroadDiagrams::Repeat.new(RailroadDiagrams::Terminal.new('a'), separator: separator, min: 2, max: 3)],
      [builder.list('a', sep: ',', min: 0, trailing: true),
       RailroadDiagrams::SeparatedList.new(RailroadDiagrams::Terminal.new('a'), separator,
                                           min: 0, trailing: true)],
      [builder.except('a', 'b'), RailroadDiagrams::Except.new(RailroadDiagrams::Terminal.new('a'), 'b')],
      [builder.block(width: 40), RailroadDiagrams::Block.new(width: 40)],
      [builder.char_class('[a-z]'), RailroadDiagrams::CharClass.new('[a-z]')],
      [builder.special('any'), RailroadDiagrams::Special.new('any')]
    ]
    cases.each do |actual, expected|
      expect(RailroadDiagrams::Diagram.new(actual).to_svg).to eq(RailroadDiagrams::Diagram.new(expected).to_svg)
    end
  end
end
