require 'spec_helper'

RSpec.describe RailroadDiagrams::Choice do
  describe '#initialize' do
    it 'accepts default index and items' do
      choice = described_class.new(0, 'a', 'b')
      expect(choice.instance_variable_get(:@default)).to eq(0)
      expect(choice.instance_variable_get(:@items).length).to eq(2)
    end

    it 'raises error when default is out of range' do
      expect {
        described_class.new(3, 'a', 'b')
      }.to raise_error(ArgumentError, /default index out of range/)
    end

    it 'wraps string items in Terminal' do
      choice = described_class.new(0, 'test')
      items = choice.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'does not require space' do
      choice = described_class.new(0, 'a', 'b')
      expect(choice.needs_space).to be false
    end

    it 'calculates width including arcs' do
      choice = described_class.new(0, 'a', 'b')
      expect(choice.width).to be > 0
    end

    it 'calculates separators for items' do
      choice = described_class.new(0, 'a', 'b')
      separators = choice.instance_variable_get(:@separators)
      expect(separators).to be_a(Array)
      expect(separators.length).to eq(1)
    end

    it 'sets height to default item height' do
      terminal1 = RailroadDiagrams::Terminal.new('a')
      terminal2 = RailroadDiagrams::Terminal.new('b')
      choice = described_class.new(0, terminal1, terminal2)
      expect(choice.height).to eq(terminal1.height)
    end
  end

  describe '#format' do
    it 'returns self' do
      choice = described_class.new(1, 'first', 'second', 'third')
      result = choice.format(0, 50, choice.width)
      expect(result).to eq(choice)
    end

    it 'adds children' do
      choice = described_class.new(0, 'a', 'b')
      choice.format(0, 0, choice.width)
      expect(choice.children).not_to be_empty
    end

    it 'formats all items' do
      choice = described_class.new(1, 'a', 'b', 'c')
      choice.format(0, 0, choice.width)
      items = choice.instance_variable_get(:@items)
      items.each do |item|
        expect(choice.children).to include(item)
      end
    end

    it 'includes path elements for branching' do
      choice = described_class.new(0, 'a', 'b')
      choice.format(0, 0, choice.width)
      has_paths = choice.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_paths).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      choice = described_class.new(0, 'A', 'B')
      td = choice.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes all choice items' do
      choice = described_class.new(1, 'A', 'B', 'C')
      td = choice.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('A')
      expect(text).to include('B')
      expect(text).to include('C')
    end

    it 'uses vertical lines for branches' do
      choice = described_class.new(0, 'A', 'B')
      td = choice.text_diagram
      expect(td.lines.join("\n")).to include('│')
    end

    it 'uses corner characters for branching' do
      choice = described_class.new(0, 'A', 'B')
      td = choice.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[╭╮╯╰]/)
    end
  end

  describe '#to_s' do
    it 'returns debug string with default index' do
      choice = described_class.new(1, 'a', 'b')
      result = choice.to_s
      expect(result).to start_with('Choice(1,')
    end

    it 'includes all items' do
      choice = described_class.new(0, 'a', 'b', 'c')
      result = choice.to_s
      expect(result).to include('Terminal')
    end
  end
end
