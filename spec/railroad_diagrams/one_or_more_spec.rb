require 'spec_helper'

RSpec.describe RailroadDiagrams::OneOrMore do
  describe '#initialize' do
    it 'accepts item only' do
      one_or_more = described_class.new('item')
      expect(one_or_more.instance_variable_get(:@item)).to be_a(RailroadDiagrams::Terminal)
    end

    it 'accepts item and repeat' do
      one_or_more = described_class.new('item', 'sep')
      expect(one_or_more.instance_variable_get(:@rep)).to be_a(RailroadDiagrams::Terminal)
    end

    it 'uses Skip as default repeat' do
      one_or_more = described_class.new('item')
      expect(one_or_more.instance_variable_get(:@rep)).to be_a(RailroadDiagrams::Skip)
    end

    it 'wraps string item in Terminal' do
      one_or_more = described_class.new('test')
      expect(one_or_more.instance_variable_get(:@item)).to be_a(RailroadDiagrams::Terminal)
    end

    it 'wraps string repeat in Terminal' do
      one_or_more = described_class.new('item', 'sep')
      expect(one_or_more.instance_variable_get(:@rep)).to be_a(RailroadDiagrams::Terminal)
    end

    it 'requires space' do
      one_or_more = described_class.new('item')
      expect(one_or_more.needs_space).to be true
    end

    it 'calculates width including arcs' do
      one_or_more = described_class.new('test')
      item = one_or_more.instance_variable_get(:@item)
      expect(one_or_more.width).to be >= item.width
    end

    it 'sets height to item height' do
      terminal = RailroadDiagrams::Terminal.new('test')
      one_or_more = described_class.new(terminal)
      expect(one_or_more.height).to eq(terminal.height)
    end

    it 'sets up to item up' do
      terminal = RailroadDiagrams::Terminal.new('test')
      one_or_more = described_class.new(terminal)
      expect(one_or_more.up).to eq(terminal.up)
    end

    it 'calculates down including repeat path' do
      one_or_more = described_class.new('test')
      expect(one_or_more.down).to be >= RailroadDiagrams::AR * 2
    end
  end

  describe '#format' do
    it 'returns self' do
      one_or_more = described_class.new('test')
      result = one_or_more.format(0, 0, one_or_more.width)
      expect(result).to eq(one_or_more)
    end

    it 'adds children' do
      one_or_more = described_class.new('test')
      one_or_more.format(0, 0, one_or_more.width)
      expect(one_or_more.children).not_to be_empty
    end

    it 'formats item' do
      one_or_more = described_class.new('test')
      one_or_more.format(0, 0, one_or_more.width)
      item = one_or_more.instance_variable_get(:@item)
      expect(one_or_more.children).to include(item)
    end

    it 'formats repeat' do
      one_or_more = described_class.new('test')
      one_or_more.format(0, 0, one_or_more.width)
      rep = one_or_more.instance_variable_get(:@rep)
      expect(one_or_more.children).to include(rep)
    end

    it 'includes path elements' do
      one_or_more = described_class.new('test')
      one_or_more.format(0, 0, one_or_more.width)
      has_paths = one_or_more.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_paths).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      one_or_more = described_class.new('A')
      td = one_or_more.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes the item' do
      one_or_more = described_class.new('TEST')
      td = one_or_more.text_diagram
      expect(td.lines.join("\n")).to include('TEST')
    end

    it 'uses repeat characters' do
      one_or_more = described_class.new('A')
      td = one_or_more.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[╭╮╯╰]/)
    end

    it 'shows repeat path below item' do
      one_or_more = described_class.new('A')
      td = one_or_more.text_diagram
      expect(td.height).to be > 1
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      one_or_more = described_class.new('test')
      result = one_or_more.to_s
      expect(result).to start_with('OneOrMore(')
      expect(result).to include('repeat=')
    end

    it 'includes repeat information' do
      one_or_more = described_class.new('item', 'sep')
      result = one_or_more.to_s
      expect(result).to include('Terminal')
    end
  end

  describe '#walk' do
    it 'has walk method' do
      one_or_more = described_class.new('test')
      expect(one_or_more).to respond_to(:walk)
    end
  end
end
