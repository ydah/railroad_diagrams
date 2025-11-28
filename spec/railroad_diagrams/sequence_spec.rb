require 'spec_helper'

RSpec.describe RailroadDiagrams::Sequence do
  describe '#initialize' do
    it 'accepts multiple items' do
      seq = described_class.new('a', 'b', 'c')
      expect(seq.instance_variable_get(:@items).length).to eq(3)
    end

    it 'wraps string items in Terminal' do
      seq = described_class.new('test')
      items = seq.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'does not require space' do
      seq = described_class.new('a', 'b')
      expect(seq.needs_space).to be false
    end

    it 'calculates width from items' do
      terminal1 = RailroadDiagrams::Terminal.new('a')
      terminal2 = RailroadDiagrams::Terminal.new('b')
      seq = described_class.new(terminal1, terminal2)

      expected_width = terminal1.width + 20 + terminal2.width + 20 - 10 - 10
      expect(seq.width).to eq(expected_width)
    end

    it 'calculates up from maximum item up' do
      seq = described_class.new('a', 'b')
      expect(seq.up).to be >= 0
    end

    it 'calculates down from maximum item down' do
      seq = described_class.new('a', 'b')
      expect(seq.down).to be >= 0
    end

    it 'handles items without space' do
      skip_item = RailroadDiagrams::Skip.new
      seq = described_class.new(skip_item)
      expect(seq.width).to eq(skip_item.width)
    end
  end

  describe '#format' do
    it 'returns self' do
      seq = described_class.new('a', 'b')
      result = seq.format(0, 0, seq.width)
      expect(result).to eq(seq)
    end

    it 'adds children' do
      seq = described_class.new('a', 'b')
      seq.format(0, 0, seq.width)
      expect(seq.children).not_to be_empty
    end

    it 'formats all items' do
      seq = described_class.new('a', 'b', 'c')
      seq.format(0, 0, seq.width)
      items = seq.instance_variable_get(:@items)
      items.each do |item|
        expect(seq.children).to include(item)
      end
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      seq = described_class.new('a', 'b')
      td = seq.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'joins items horizontally' do
      seq = described_class.new('A', 'B')
      td = seq.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('A')
      expect(text).to include('B')
    end

    it 'uses separator between items' do
      seq = described_class.new('A', 'B')
      td = seq.text_diagram
      expect(td.lines.join("\n")).to include('─')
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      seq = described_class.new('a', 'b')
      result = seq.to_s
      expect(result).to start_with('Sequence(')
      expect(result).to include('Terminal')
    end
  end
end
