require 'spec_helper'

RSpec.describe RailroadDiagrams::ZeroOrMore do
  describe '.new' do
    it 'returns a Choice instance' do
      zero_or_more = described_class.new('item')
      expect(zero_or_more).to be_a(RailroadDiagrams::Choice)
    end

    it 'wraps OneOrMore in Optional' do
      zero_or_more = described_class.new('test')
      items = zero_or_more.instance_variable_get(:@items)
      one_or_more = items.find { |i| i.is_a?(RailroadDiagrams::OneOrMore) }
      expect(one_or_more).not_to be_nil
    end

    it 'includes Skip in items' do
      zero_or_more = described_class.new('test')
      items = zero_or_more.instance_variable_get(:@items)
      skip = items.find { |i| i.is_a?(RailroadDiagrams::Skip) }
      expect(skip).not_to be_nil
    end

    it 'accepts repeat parameter' do
      zero_or_more = described_class.new('item', 'sep')
      items = zero_or_more.instance_variable_get(:@items)
      one_or_more = items.find { |i| i.is_a?(RailroadDiagrams::OneOrMore) }
      rep = one_or_more.instance_variable_get(:@rep)
      expect(rep).to be_a(RailroadDiagrams::Terminal)
    end

    it 'accepts skip parameter false' do
      zero_or_more = described_class.new('item', nil, false)
      expect(zero_or_more.instance_variable_get(:@default)).to eq(1)
    end

    it 'accepts skip parameter true' do
      zero_or_more = described_class.new('item', nil, true)
      expect(zero_or_more.instance_variable_get(:@default)).to eq(0)
    end

    it 'wraps string item in Terminal' do
      zero_or_more = described_class.new('test')
      items = zero_or_more.instance_variable_get(:@items)
      one_or_more = items.find { |i| i.is_a?(RailroadDiagrams::OneOrMore) }
      item = one_or_more.instance_variable_get(:@item)
      expect(item).to be_a(RailroadDiagrams::Terminal)
    end
  end

  describe 'formatting and rendering' do
    it 'can be formatted' do
      zero_or_more = described_class.new('test')
      result = zero_or_more.format(0, 0, zero_or_more.width)
      expect(result).to be_a(RailroadDiagrams::Choice)
    end

    it 'can generate text diagram' do
      zero_or_more = described_class.new('A')
      td = zero_or_more.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes the item in text diagram' do
      zero_or_more = described_class.new('TEST')
      td = zero_or_more.text_diagram
      expect(td.lines.join("\n")).to include('TEST')
    end

    it 'shows optional and repeat structure' do
      zero_or_more = described_class.new('A')
      td = zero_or_more.text_diagram
      expect(td.height).to be > 1
    end
  end
end
