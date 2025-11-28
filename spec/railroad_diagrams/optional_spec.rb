require 'spec_helper'

RSpec.describe RailroadDiagrams::Optional do
  describe '.new' do
    it 'returns a Choice instance' do
      optional = described_class.new('item')
      expect(optional).to be_a(RailroadDiagrams::Choice)
    end

    it 'creates choice with Skip as first item by default' do
      optional = described_class.new('test')
      items = optional.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Skip)
    end

    it 'creates choice with item as second item by default' do
      optional = described_class.new('test')
      items = optional.instance_variable_get(:@items)
      expect(items.last).to be_a(RailroadDiagrams::Terminal)
    end

    it 'sets default to 1 when skip is false' do
      optional = described_class.new('test', false)
      expect(optional.instance_variable_get(:@default)).to eq(1)
    end

    it 'sets default to 0 when skip is true' do
      optional = described_class.new('test', true)
      expect(optional.instance_variable_get(:@default)).to eq(0)
    end

    it 'wraps string item in Terminal' do
      optional = described_class.new('test')
      items = optional.instance_variable_get(:@items)
      terminal = items.find { |i| i.is_a?(RailroadDiagrams::Terminal) }
      expect(terminal).not_to be_nil
    end

    it 'accepts DiagramItem' do
      terminal = RailroadDiagrams::Terminal.new('custom')
      optional = described_class.new(terminal)
      items = optional.instance_variable_get(:@items)
      expect(items).to include(terminal)
    end
  end

  describe 'formatting and rendering' do
    it 'can be formatted' do
      optional = described_class.new('test')
      result = optional.format(0, 0, optional.width)
      expect(result).to be_a(RailroadDiagrams::Choice)
    end

    it 'can generate text diagram' do
      optional = described_class.new('A')
      td = optional.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes the item in text diagram' do
      optional = described_class.new('TEST')
      td = optional.text_diagram
      expect(td.lines.join("\n")).to include('TEST')
    end
  end
end
