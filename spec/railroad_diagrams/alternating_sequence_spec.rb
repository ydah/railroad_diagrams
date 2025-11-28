require 'spec_helper'

RSpec.describe RailroadDiagrams::AlternatingSequence do
  describe '.new' do
    it 'requires exactly two arguments' do
      expect {
        described_class.new('a')
      }.to raise_error(RuntimeError, /exactly two arguments/)
    end

    it 'raises error with three arguments' do
      expect {
        described_class.new('a', 'b', 'c')
      }.to raise_error(RuntimeError, /exactly two arguments/)
    end

    it 'accepts exactly two arguments' do
      expect {
        described_class.new('a', 'b')
      }.not_to raise_error
    end
  end

  describe '#initialize' do
    it 'wraps string items in Terminal' do
      alt_seq = described_class.new('test1', 'test2')
      items = alt_seq.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
      expect(items.last).to be_a(RailroadDiagrams::Terminal)
    end

    it 'does not require space' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.needs_space).to be false
    end

    it 'calculates width from items' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.width).to be > 0
    end

    it 'calculates up including first item' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.up).to be > 0
    end

    it 'calculates down including second item' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.down).to be > 0
    end

    it 'sets height to 0' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.height).to eq(0)
    end

    it 'accepts DiagramItem arguments' do
      terminal1 = RailroadDiagrams::Terminal.new('first')
      terminal2 = RailroadDiagrams::Terminal.new('second')
      alt_seq = described_class.new(terminal1, terminal2)
      items = alt_seq.instance_variable_get(:@items)
      expect(items).to include(terminal1)
      expect(items).to include(terminal2)
    end
  end

  describe '#format' do
    it 'returns self' do
      alt_seq = described_class.new('a', 'b')
      result = alt_seq.format(0, 0, alt_seq.width)
      expect(result).to eq(alt_seq)
    end

    it 'adds children' do
      alt_seq = described_class.new('a', 'b')
      alt_seq.format(0, 0, alt_seq.width)
      expect(alt_seq.children).not_to be_empty
    end

    it 'formats both items' do
      alt_seq = described_class.new('a', 'b')
      alt_seq.format(0, 0, alt_seq.width)
      items = alt_seq.instance_variable_get(:@items)
      items.each do |item|
        expect(alt_seq.children).to include(item)
      end
    end

    it 'includes path elements for crossover' do
      alt_seq = described_class.new('a', 'b')
      alt_seq.format(0, 0, alt_seq.width)
      has_paths = alt_seq.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_paths).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      alt_seq = described_class.new('A', 'B')
      td = alt_seq.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes both items' do
      alt_seq = described_class.new('FIRST', 'SECOND')
      td = alt_seq.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('FIRST')
      expect(text).to include('SECOND')
    end

    it 'uses cross diagonal for crossover' do
      alt_seq = described_class.new('A', 'B')
      td = alt_seq.text_diagram
      expect(td.lines.join("\n")).to include('╳')
    end

    it 'uses corner characters' do
      alt_seq = described_class.new('A', 'B')
      td = alt_seq.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[╭╮╯╰]/)
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      alt_seq = described_class.new('a', 'b')
      result = alt_seq.to_s
      expect(result).to start_with('AlternatingSequence(')
      expect(result).to include('Terminal')
    end
  end
end
