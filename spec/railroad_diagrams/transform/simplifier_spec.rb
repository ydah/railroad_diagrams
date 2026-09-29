# frozen_string_literal: true

require 'spec_helper'
require 'railroad_diagrams/transform/simplifier'

RSpec.describe RailroadDiagrams::Transform::Simplifier do
  let(:rd) { RailroadDiagrams }

  def only(rule)
    { except: (1..8).map { |number| :"s#{number}" } - [rule] }
  end

  def simplified(node, rule, **options)
    described_class.call(node, **only(rule), **options).to_h
  end

  it 'flattens nested sequences' do
    input = rd::Sequence.new('a', rd::Sequence.new('b', 'c'))
    expect(simplified(input, :s1)).to eq(rd::Sequence.new('a', 'b', 'c').to_h)
  end

  it 'removes single-item sequences and choices' do
    expect(simplified(rd::Sequence.new('a'), :s2)).to eq(rd::Terminal.new('a').to_h)
    expect(simplified(rd::Choice.new(0, 'a'), :s2)).to eq(rd::Terminal.new('a').to_h)
  end

  it 'removes duplicate alternatives and retains the selected default' do
    input = rd::Choice.new(2, 'a', 'b', 'a')
    expect(simplified(input, :s3)).to eq(rd::Choice.new(0, 'a', 'b').to_h)
  end

  it 'turns a skip alternative into an optional node' do
    input = rd::Choice.new(0, 'a', rd::Skip.new)
    expect(simplified(input, :s4)).to eq(rd::Optional.new('a', skip: false).to_h)
  end

  it 'turns a repeated separated sequence into one-or-more' do
    item = rd::Terminal.new('a')
    separator = rd::Terminal.new(',')
    input = rd::Sequence.new(item, rd::ZeroOrMore.new(rd::Sequence.new(separator, item)))
    expect(simplified(input, :s5)).to eq(rd::OneOrMore.new(item, separator).to_h)
  end

  it 'recognizes a separated sequence when the repeated item is itself a sequence' do
    item = rd::Sequence.new('a', 'b')
    input = rd::Sequence.new(item, rd::ZeroOrMore.new(rd::Sequence.new(',', item)))
    expect(simplified(input, :s5)).to eq(rd::OneOrMore.new(item, ',').to_h)
    expect(described_class.call(input)).to be_a(rd::OneOrMore)
  end

  it 'eliminates direct left recursion at a rule root' do
    input = rd::Choice.new(0, rd::Sequence.new(rd::NonTerminal.new('A'), 'b'), 'a')
    expected = rd::Sequence.new('a', rd::ZeroOrMore.new('b'))
    expect(simplified(input, :s6, rule_name: 'A')).to eq(expected.to_h)
    expect(described_class.call(input, **only(:s6))).to eq(input)
  end

  it 'eliminates left recursion with a compound suffix' do
    input = rd::Choice.new(0, rd::Sequence.new(rd::NonTerminal.new('A'), rd::Sequence.new('b', 'c')), 'a')
    expected = rd::Sequence.new('a', rd::ZeroOrMore.new(rd::Sequence.new('b', 'c')))
    expect(simplified(input, :s6, rule_name: 'A')).to eq(expected.to_h)
    expect(described_class.call(input, rule_name: 'A').to_h['type']).to eq('sequence')
  end

  it 'does not eliminate left recursion without a non-recursive base' do
    branch = rd::Sequence.new(rd::NonTerminal.new('A'), 'b')
    input = rd::Choice.new(0, branch, branch)
    expect { described_class.call(input, rule_name: 'A') }.not_to raise_error
  end

  it 'factors a common prefix' do
    input = rd::Choice.new(1, rd::Sequence.new('a', 'b'), rd::Sequence.new('a', 'c'))
    expected = rd::Sequence.new('a', rd::Choice.new(1, 'b', 'c'))
    expect(simplified(input, :s7)).to eq(expected.to_h)
  end

  it 'factors a compound common prefix' do
    prefix = rd::Sequence.new('a', 'b')
    input = rd::Choice.new(0, rd::Sequence.new(prefix, 'c'), rd::Sequence.new(prefix, 'd'))
    expected = rd::Sequence.new(prefix, rd::Choice.new(0, 'c', 'd'))
    expect(simplified(input, :s7)).to eq(expected.to_h)
    expect(described_class.call(input).to_h['type']).to eq('sequence')
  end

  it 'collapses nested optional nodes' do
    input = rd::Optional.new(rd::Optional.new('a'))
    expect(simplified(input, :s8)).to eq(rd::Optional.new('a').to_h)
  end

  it 'preserves user attributes and leaves decorated wrappers in place' do
    input = rd::Sequence.new('a', rd::Sequence.new('b', id: 'nested'), id: 'outer')
    expect(described_class.call(input).to_h).to eq(input.to_h)
  end

  it 'honors excluded rules and leaves the input unchanged' do
    input = rd::Sequence.new('a')
    expect(described_class.call(input, except: [:s2])).to eq(input)
    expect(input.to_h).to eq(rd::Sequence.new('a').to_h)
  end

  # Languages are finite here because strings longer than four characters are discarded.
  def words(node, references = {}, limit = 4)
    case node
    when rd::Terminal
      [node.to_h.fetch('text')]
    when rd::NonTerminal
      references.fetch(node.to_h.fetch('text'), [])
    when rd::Skip
      ['']
    when rd::Sequence
      node.child_nodes.reduce(['']) { |prefixes, child| product(prefixes, words(child, references, limit), limit) }
    when rd::ZeroOrMore
      repeated = node.child_nodes[1]
      star(words(repeated.child_nodes[0], references, limit),
           words(repeated.child_nodes[1], references, limit), limit)
    when rd::Optional
      ([''] + words(node.child_nodes[1], references, limit)).uniq
    when rd::Choice
      node.child_nodes.flat_map { |child| words(child, references, limit) }.uniq
    when rd::OneOrMore
      item, separator = node.child_nodes
      repeated = star(words(item, references, limit), words(separator, references, limit), limit)
      product(words(item, references, limit), repeated, limit)
    else
      raise "unsupported test node: #{node.class}"
    end
  end

  def product(left, right, limit)
    left.product(right).map { |a, b| a + b }.select { |value| value.length <= limit }.uniq
  end

  def star(item_words, separator_words, limit)
    result = ['']
    loop do
      extended = (result + product(result, product(separator_words, item_words, limit), limit)).uniq
      return result if extended == result

      result = extended
    end
  end

  def recursive_words(node, name)
    values = []
    loop do
      next_values = words(node, { name => values }).sort
      return values if next_values == values

      values = next_values
    end
  end

  # rubocop:disable-next RSpec/ExampleLength
  it 'preserves all accepted words of length at most four across the eight rewrites' do
    a = rd::Terminal.new('a')
    b = rd::Terminal.new('b')
    c = rd::Terminal.new('c')
    samples = [
      [rd::Sequence.new(a, rd::Sequence.new(b, c)), nil],
      [rd::Sequence.new(a), nil],
      [rd::Choice.new(0, a), nil],
      [rd::Choice.new(2, a, b, a), nil],
      [rd::Choice.new(0, rd::Skip.new, a), nil],
      [rd::Sequence.new(a, rd::ZeroOrMore.new(rd::Sequence.new(b, a))), nil],
      [rd::Choice.new(0, rd::Sequence.new(rd::NonTerminal.new('A'), b), a), 'A'],
      [rd::Choice.new(0, rd::Sequence.new(a, b), rd::Sequence.new(a, c)), nil],
      [rd::Optional.new(rd::Optional.new(a)), nil]
    ]
    samples.each do |input, name|
      output = described_class.call(input, rule_name: name)
      before = name ? recursive_words(input, name) : words(input).sort
      after = name ? recursive_words(output, name) : words(output).sort
      expect(after).to eq(before)
    end
  end
end
