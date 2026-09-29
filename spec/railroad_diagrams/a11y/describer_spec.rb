# frozen_string_literal: true

require 'spec_helper'
require 'railroad_diagrams/a11y/describer'

RSpec.describe RailroadDiagrams::A11y::Describer do
  let(:rd) { RailroadDiagrams }

  it 'describes a diagram in English and Japanese without its automatic endpoints' do
    diagram = rd::Diagram.new('SELECT', rd::Optional.new('DISTINCT'), rd::NonTerminal.new('table'))

    expect(described_class.call(diagram))
      .to eq('in sequence: “SELECT”, optional “DISTINCT”, nonterminal table')
    expect(described_class.call(diagram, locale: :ja))
      .to eq('順に: 「SELECT」、省略可能な「DISTINCT」、非終端記号「table」')
  end

  it 'describes repetition and branch choices' do
    expect(described_class.call(rd::OneOrMore.new('A'))).to eq('repeat “A” one or more times')
    expect(described_class.call(rd::ZeroOrMore.new('A'))).to eq('repeat “A” zero or more times')
    expect(described_class.call(rd::MultipleChoice.new(0, 'any', 'A', 'B'))).to eq('one or more of: “A”, “B”')
    expect(described_class.call(rd::MultipleChoice.new(0, 'all', 'A', 'B'))).to eq('all of: “A”, “B”')
    expect(described_class.call(rd::HorizontalChoice.new('A', 'B'))).to eq('one of: “A”, “B”')
    expect(described_class.call(rd::Choice.new(0, 'A', rd::Skip.new))).to eq('optional “A”')
  end

  it 'describes groups and vertical order' do
    expect(described_class.call(rd::Group.new('A', 'label'))).to eq('label: “A”')
    expect(described_class.call(rd::Stack.new('A', 'B'))).to eq('in sequence: “A”, “B”')
    expect(described_class.call(rd::OptionalSequence.new('A', 'B')))
      .to eq('in sequence: optional “A”, optional “B”')
  end

  it 'handles leaves, an empty diagram, and repeated calls deterministically' do
    expect(described_class.call(rd::Start.new)).to eq('start')
    expect(described_class.call(rd::End.new)).to eq('end')
    expect(described_class.call(rd::Skip.new)).to eq('skip')
    expect(described_class.call(rd::Diagram.new)).to eq('')

    first = rd::Diagram.new('A', rd::Choice.new(0, 'B', 'C'))
    second = rd::Diagram.new('A', rd::Choice.new(0, 'B', 'C'))
    description = described_class.call(first)
    expect(description).to eq(described_class.call(second))
    expect(description).to eq(described_class.call(first))
  end

  it 'truncates by grapheme without splitting emoji and respects the exact limit' do
    diagram = rd::Terminal.new('👩‍💻' * 5)

    expect(described_class.call(diagram, max_length: 5)).to eq('“👩‍💻👩‍💻👩‍💻…')
    expect(described_class.call(diagram, max_length: 1)).to eq('…')
    expect(described_class.call(rd::Terminal.new('A'), max_length: 20)).to eq('“A”')
  end

  it 'rejects unsupported locales and invalid length limits' do
    expect { described_class.call(rd::Terminal.new('A'), locale: :fr) }.to raise_error(rd::InvalidArgument)
    expect { described_class.call(rd::Terminal.new('A'), max_length: 0) }.to raise_error(rd::InvalidArgument)
  end
end
