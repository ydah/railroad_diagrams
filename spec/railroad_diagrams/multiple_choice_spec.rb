require 'spec_helper'

RSpec.describe RailroadDiagrams::MultipleChoice do
  describe '#initialize' do
    it 'accepts default, type, and items' do
      mc = described_class.new(0, 'any', 'a', 'b')
      expect(mc.instance_variable_get(:@default)).to eq(0)
      expect(mc.instance_variable_get(:@type)).to eq('any')
      expect(mc.instance_variable_get(:@items).length).to eq(2)
    end

    it 'raises error when default is out of range' do
      expect {
        described_class.new(3, 'any', 'a', 'b')
      }.to raise_error(ArgumentError, /default must be between/)
    end

    it 'raises error when default is negative' do
      expect {
        described_class.new(-1, 'any', 'a', 'b')
      }.to raise_error(ArgumentError, /default must be between/)
    end

    it 'raises error when type is invalid' do
      expect {
        described_class.new(0, 'invalid', 'a', 'b')
      }.to raise_error(ArgumentError, /must be 'any' or 'all'/)
    end

    it 'accepts any type' do
      mc = described_class.new(0, 'any', 'a')
      expect(mc.instance_variable_get(:@type)).to eq('any')
    end

    it 'accepts all type' do
      mc = described_class.new(0, 'all', 'a')
      expect(mc.instance_variable_get(:@type)).to eq('all')
    end

    it 'wraps string items in Terminal' do
      mc = described_class.new(0, 'any', 'test')
      items = mc.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'requires space' do
      mc = described_class.new(0, 'any', 'a', 'b')
      expect(mc.needs_space).to be true
    end

    it 'calculates width from items' do
      mc = described_class.new(0, 'any', 'a', 'b')
      expect(mc.width).to be > 0
    end

    it 'calculates inner_width from widest item' do
      mc = described_class.new(0, 'any', 'short', 'longer')
      inner_width = mc.instance_variable_get(:@inner_width)
      items = mc.instance_variable_get(:@items)
      expect(inner_width).to eq(items.map(&:width).max)
    end

    it 'sets height to default item height' do
      terminal1 = RailroadDiagrams::Terminal.new('a')
      terminal2 = RailroadDiagrams::Terminal.new('b')
      mc = described_class.new(0, 'any', terminal1, terminal2)
      expect(mc.height).to eq(terminal1.height)
    end
  end

  describe '#format' do
    it 'returns self' do
      mc = described_class.new(1, 'any', 'a', 'b', 'c')
      result = mc.format(0, 0, mc.width)
      expect(result).to eq(mc)
    end

    it 'adds children' do
      mc = described_class.new(0, 'any', 'a', 'b')
      mc.format(0, 0, mc.width)
      expect(mc.children).not_to be_empty
    end

    it 'formats all items' do
      mc = described_class.new(1, 'any', 'a', 'b', 'c')
      mc.format(0, 0, mc.width)
      items = mc.instance_variable_get(:@items)
      items.each do |item|
        expect(mc.children).to include(item)
      end
    end

    it 'includes text elements for any type' do
      mc = described_class.new(0, 'any', 'a', 'b')
      mc.format(0, 0, mc.width)
      has_text = mc.children.any? do |child|
        next unless child.is_a?(RailroadDiagrams::DiagramItem)
        child.children.any? do |c|
          c.is_a?(RailroadDiagrams::DiagramItem) &&
          c.instance_variable_get(:@name) == 'text' &&
          c.children.include?('1+')
        end
      end
      expect(has_text).to be true
    end

    it 'includes text elements for all type' do
      mc = described_class.new(0, 'all', 'a', 'b')
      mc.format(0, 0, mc.width)
      has_text = mc.children.any? do |child|
        next unless child.is_a?(RailroadDiagrams::DiagramItem)
        child.children.any? do |c|
          c.is_a?(RailroadDiagrams::DiagramItem) &&
          c.instance_variable_get(:@name) == 'text' &&
          c.children.include?('all')
        end
      end
      expect(has_text).to be true
    end

    it 'includes repeat symbol' do
      mc = described_class.new(0, 'any', 'a', 'b')
      mc.format(0, 0, mc.width)
      has_repeat = mc.children.any? do |child|
        next unless child.is_a?(RailroadDiagrams::DiagramItem)
        child.children.any? do |c|
          c.is_a?(RailroadDiagrams::DiagramItem) &&
          c.instance_variable_get(:@name) == 'text' &&
          c.children.include?('↺')
        end
      end
      expect(has_repeat).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram for any type' do
      mc = described_class.new(0, 'any', 'a', 'b')
      td = mc.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'returns a TextDiagram for all type' do
      mc = described_class.new(0, 'all', 'a', 'b')
      td = mc.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes 1+ for any type' do
      mc = described_class.new(0, 'any', 'a', 'b')
      td = mc.text_diagram
      expect(td.lines.join("\n")).to include('1+')
    end

    it 'includes all for all type' do
      mc = described_class.new(0, 'all', 'a', 'b')
      td = mc.text_diagram
      expect(td.lines.join("\n")).to include('all')
    end

    it 'includes multi repeat symbol' do
      mc = described_class.new(0, 'any', 'a', 'b')
      td = mc.text_diagram
      expect(td.lines.join("\n")).to include('↺')
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      mc = described_class.new(1, 'any', 'a', 'b')
      result = mc.to_s
      expect(result).to start_with('MultipleChoice(1, any,')
    end

    it 'includes type in string' do
      mc = described_class.new(0, 'all', 'a', 'b')
      result = mc.to_s
      expect(result).to include('all')
    end
  end
end
