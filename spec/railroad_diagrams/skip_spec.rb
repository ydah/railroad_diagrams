require 'spec_helper'

RSpec.describe RailroadDiagrams::Skip do
  describe '#initialize' do
    it 'sets width to 0' do
      skip = described_class.new
      expect(skip.width).to eq(0)
    end

    it 'sets up to 0' do
      skip = described_class.new
      expect(skip.up).to eq(0)
    end

    it 'sets down to 0' do
      skip = described_class.new
      expect(skip.down).to eq(0)
    end

    it 'is a g element' do
      skip = described_class.new
      expect(skip.instance_variable_get(:@name)).to eq('g')
    end
  end

  describe '#format' do
    it 'returns self' do
      skip = described_class.new
      result = skip.format(0, 0, 100)
      expect(result).to eq(skip)
    end

    it 'adds path child' do
      skip = described_class.new
      skip.format(0, 0, 100)
      has_path = skip.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_path).to be true
    end

    it 'creates horizontal line with specified width' do
      skip = described_class.new
      skip.format(10, 20, 50)
      path = skip.children.find { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(path.attrs['d']).to include('h50')
    end

    it 'starts at correct position' do
      skip = described_class.new
      skip.format(10, 20, 50)
      path = skip.children.find { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(path.x).to eq(10)
      expect(path.y).to eq(20)
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      skip = described_class.new
      td = skip.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'contains a line character' do
      skip = described_class.new
      td = skip.text_diagram
      expect(td.lines.join("\n")).to include('─')
    end

    it 'has single line' do
      skip = described_class.new
      td = skip.text_diagram
      expect(td.lines.length).to eq(1)
    end

    it 'has entry and exit at 0' do
      skip = described_class.new
      td = skip.text_diagram
      expect(td.entry).to eq(0)
      expect(td.exit).to eq(0)
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      skip = described_class.new
      expect(skip.to_s).to eq('Skip()')
    end
  end
end
