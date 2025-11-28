require 'spec_helper'

RSpec.describe 'Edge Cases' do
  describe 'AlternatingSequence' do
    it 'requires exactly two arguments' do
      expect {
        RailroadDiagrams::AlternatingSequence.new('a')
      }.to raise_error(RuntimeError, /exactly two arguments/)
    end

    it 'raises error with three arguments' do
      expect {
        RailroadDiagrams::AlternatingSequence.new('a', 'b', 'c')
      }.to raise_error(RuntimeError, /exactly two arguments/)
    end
  end

  describe 'MultipleChoice' do
    it 'requires valid type' do
      expect {
        RailroadDiagrams::MultipleChoice.new(0, 'invalid', 'a', 'b')
      }.to raise_error(ArgumentError, /must be 'any' or 'all'/)
    end

    it 'requires valid default index' do
      expect {
        RailroadDiagrams::MultipleChoice.new(5, 'any', 'a', 'b')
      }.to raise_error(ArgumentError, /default must be between/)
    end
  end

  describe 'HorizontalChoice' do
    it 'returns Sequence for single item' do
      result = RailroadDiagrams::HorizontalChoice.new('single')
      expect(result).to be_a(RailroadDiagrams::Sequence)
    end
  end

  describe 'OptionalSequence' do
    it 'returns Sequence for single item' do
      result = RailroadDiagrams::OptionalSequence.new('single')
      expect(result).to be_a(RailroadDiagrams::Sequence)
    end
  end

  describe 'Choice' do
    it 'raises error when default is out of range' do
      expect {
        RailroadDiagrams::Choice.new(5, 'a', 'b')
      }.to raise_error(ArgumentError, /default index out of range/)
    end

    it 'handles default at upper bound' do
      choice = RailroadDiagrams::Choice.new(2, 'a', 'b', 'c')
      expect(choice.instance_variable_get(:@default)).to eq(2)
    end

    it 'handles default at lower bound' do
      choice = RailroadDiagrams::Choice.new(0, 'a', 'b')
      expect(choice.instance_variable_get(:@default)).to eq(0)
    end
  end

  describe 'TextDiagram initialization' do
    it 'raises error when entry is out of bounds' do
      expect {
        RailroadDiagrams::TextDiagram.new(5, 0, ['A'])
      }.to raise_error(RuntimeError, /Entry is not within diagram/)
    end

    it 'raises error when exit is out of bounds' do
      expect {
        RailroadDiagrams::TextDiagram.new(0, 5, ['A'])
      }.to raise_error(RuntimeError, /Exit is not within diagram/)
    end

    it 'raises error when lines are not rectangular' do
      expect {
        RailroadDiagrams::TextDiagram.new(0, 0, ['A', 'AB'])
      }.to raise_error(RuntimeError, /not rectangular/)
    end
  end

  describe 'TextDiagram formatting' do
    it 'raises error when centering into smaller width' do
      td = RailroadDiagrams::TextDiagram.new(0, 0, ['ABC'])
      expect {
        td.center(2)
      }.to raise_error(StandardError)
    end

    it 'raises error when padding gap is not multiple of pad length' do
      expect {
        RailroadDiagrams::TextDiagram.pad_l('XX', 5, '--')
      }.to raise_error(RuntimeError, /must be a multiple/)
    end

    it 'raises error when enclose_lines arrays have different lengths' do
      expect {
        RailroadDiagrams::TextDiagram.enclose_lines(['A'], ['<', '<'], ['>'])
      }.to raise_error(RuntimeError, /same length/)
    end
  end

  describe 'TextDiagram.set_formatting' do
    it 'raises error for multi-character parts' do
      expect {
        RailroadDiagrams::TextDiagram.set_formatting({ 'bad' => 'XX' })
      }.to raise_error(ArgumentError, /more than 1 character/)
    end

    it 'does nothing when characters is nil' do
      original_parts = RailroadDiagrams::TextDiagram.parts.dup
      RailroadDiagrams::TextDiagram.set_formatting(nil)
      expect(RailroadDiagrams::TextDiagram.parts).to eq(original_parts)
    end
  end

  describe 'Empty sequences and containers' do
    it 'handles Sequence with at least one item' do
      seq = RailroadDiagrams::Sequence.new('item')
      expect(seq.width).to be > 0
      expect(seq.height).to be >= 0
    end

    it 'handles Diagram with no items explicitly passed' do
      diagram = RailroadDiagrams::Diagram.new('item')
      items = diagram.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Start)
      expect(items.last).to be_a(RailroadDiagrams::End)
    end

    it 'handles TextDiagram with empty lines' do
      td = RailroadDiagrams::TextDiagram.new(0, 0, [])
      expect(td.height).to eq(0)
      expect(td.width).to eq(0)
    end
  end

  describe 'String wrapping' do
    it 'wraps strings in Terminal for Sequence' do
      seq = RailroadDiagrams::Sequence.new('test')
      items = seq.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'wraps strings in Terminal for Choice' do
      choice = RailroadDiagrams::Choice.new(0, 'a', 'b')
      items = choice.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'wraps strings in Terminal for OneOrMore' do
      one_or_more = RailroadDiagrams::OneOrMore.new('test')
      item = one_or_more.instance_variable_get(:@item)
      expect(item).to be_a(RailroadDiagrams::Terminal)
    end
  end

  describe 'Special characters in text' do
    it 'escapes special characters in Terminal text' do
      terminal = RailroadDiagrams::Terminal.new('foo<bar&baz')
      terminal.format(0, 0, terminal.width)
      output = StringIO.new
      terminal.write_svg(output.method(:write))
      expect(output.string).to include('foo&lt;bar&amp;baz')
    end

    it 'escapes special characters in NonTerminal text' do
      non_terminal = RailroadDiagrams::NonTerminal.new('foo<bar&baz')
      non_terminal.format(0, 0, non_terminal.width)
      output = StringIO.new
      non_terminal.write_svg(output.method(:write))
      expect(output.string).to include('foo&lt;bar&amp;baz')
    end

    it 'escapes special characters in attributes' do
      item = RailroadDiagrams::DiagramItem.new('rect', attrs: { 'data' => 'foo&bar"baz' })
      output = StringIO.new
      item.write_svg(output.method(:write))
      expect(output.string).to include('foo&amp;bar&quot;baz')
    end
  end

  describe 'Width calculations' do
    it 'calculates Terminal width correctly for empty string' do
      terminal = RailroadDiagrams::Terminal.new('')
      expect(terminal.width).to eq(20)
    end

    it 'calculates NonTerminal width correctly for empty string' do
      non_terminal = RailroadDiagrams::NonTerminal.new('')
      expect(non_terminal.width).to eq(20)
    end

    it 'calculates Comment width correctly for empty string' do
      comment = RailroadDiagrams::Comment.new('')
      expect(comment.width).to eq(10)
    end
  end

  describe 'Optional and ZeroOrMore delegation' do
    it 'Optional delegates to Choice' do
      optional = RailroadDiagrams::Optional.new('item')
      expect(optional).to be_a(RailroadDiagrams::Choice)
    end

    it 'ZeroOrMore delegates to Optional and OneOrMore' do
      zero_or_more = RailroadDiagrams::ZeroOrMore.new('item')
      expect(zero_or_more).to be_a(RailroadDiagrams::Choice)
      items = zero_or_more.instance_variable_get(:@items)
      one_or_more = items.find { |i| i.is_a?(RailroadDiagrams::OneOrMore) }
      expect(one_or_more).not_to be_nil
    end
  end

  describe 'Formatting without prior formatting' do
    it 'Diagram formats automatically on write_svg' do
      diagram = RailroadDiagrams::Diagram.new('test')
      expect(diagram.instance_variable_get(:@formatted)).to be false
      output = StringIO.new
      diagram.write_svg(output.method(:write))
      expect(diagram.instance_variable_get(:@formatted)).to be true
    end

    it 'Diagram formats automatically on write_standalone' do
      diagram = RailroadDiagrams::Diagram.new('test')
      expect(diagram.instance_variable_get(:@formatted)).to be false
      output = StringIO.new
      diagram.write_standalone(output.method(:write))
      expect(diagram.instance_variable_get(:@formatted)).to be true
    end
  end

  describe 'Start and End types' do
    it 'Start uses type for both simple and complex' do
      simple_start = RailroadDiagrams::Start.new('simple')
      complex_start = RailroadDiagrams::Start.new('complex')
      expect(simple_start.instance_variable_get(:@type)).to eq('simple')
      expect(complex_start.instance_variable_get(:@type)).to eq('complex')
    end

    it 'End uses type for both simple and complex' do
      simple_end = RailroadDiagrams::End.new('simple')
      complex_end = RailroadDiagrams::End.new('complex')
      expect(simple_end.instance_variable_get(:@type)).to eq('simple')
      expect(complex_end.instance_variable_get(:@type)).to eq('complex')
    end

    it 'Diagram propagates type to Start and End' do
      diagram = RailroadDiagrams::Diagram.new('item', type: 'complex')
      items = diagram.instance_variable_get(:@items)
      start = items.first
      end_node = items.last
      expect(start.instance_variable_get(:@type)).to eq('complex')
      expect(end_node.instance_variable_get(:@type)).to eq('complex')
    end
  end
end
