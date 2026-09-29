# frozen_string_literal: true

require 'spec_helper'
require 'railroad_diagrams/transform/lint'

RSpec.describe RailroadDiagrams::Transform::Lint do
  let(:rd) { RailroadDiagrams }

  # rubocop:disable-next RSpec/ExampleLength
  it 'reports undefined references, unused rules, and duplicate definitions' do
    rules = [
      ['start', rd::Sequence.new(rd::NonTerminal.new('item'), rd::NonTerminal.new('missing'))],
      ['item', rd::Terminal.new('a')],
      ['unused', rd::Terminal.new('b')],
      ['item', rd::Terminal.new('c')]
    ]
    warnings = described_class.call(rules)
    expect(warnings.map(&:kind)).to contain_exactly(:undefined_reference, :unreferenced_rule, :duplicate_definition)
    expect(warnings.find { |warning| warning.kind == :undefined_reference }.name).to eq('missing')
    expect(warnings.find { |warning| warning.kind == :unreferenced_rule }.rule).to eq('unused')
    expect(warnings.find { |warning| warning.kind == :duplicate_definition }.name).to eq('item')
    expect(warnings).to all(be_a(described_class::Warning))
  end

  it 'reports duplicate choice branches as unreachable' do
    choice = rd::Choice.new(0, 'a', 'b', 'a')
    warning = described_class.call([['start', choice]]).find { |entry| entry.kind == :unreachable_branch }
    expect(warning.rule).to eq('start')
    expect(warning.message).to include('3')
  end

  it 'reports empty choices in malformed imported nodes' do
    choice = rd::Choice.new(0, 'a')
    choice.instance_variable_set(:@items, [])
    warnings = described_class.call([['start', choice]])
    expect(warnings.map(&:kind)).to include(:empty_choice)
  end

  it 'accepts a referenced grammar without warnings' do
    rules = [['start', rd::NonTerminal.new('item')], ['item', rd::Terminal.new('a')]]
    expect(described_class.call(rules)).to eq([])
  end
end
