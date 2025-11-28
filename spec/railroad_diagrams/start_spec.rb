require 'spec_helper'

RSpec.describe RailroadDiagrams::Start do
  describe '#initialize' do
    it 'defaults to simple type' do
      start = described_class.new
      expect(start.instance_variable_get(:@type)).to eq('simple')
    end

    it 'accepts complex type' do
      start = described_class.new('complex')
      expect(start.instance_variable_get(:@type)).to eq('complex')
    end

    it 'sets default width to 20' do
      start = described_class.new
      expect(start.width).to eq(20)
    end

    it 'calculates width based on label length' do
      start = described_class.new('simple', label: 'hello')
      expected_width = [20, (5 * RailroadDiagrams::CHAR_WIDTH) + 10].max
      expect(start.width).to eq(expected_width)
    end

    it 'uses minimum width of 20 for short labels' do
      start = described_class.new('simple', label: 'x')
      expect(start.width).to eq(20)
    end

    it 'sets up and down to 10' do
      start = described_class.new
      expect(start.up).to eq(10)
      expect(start.down).to eq(10)
    end

    it 'accepts label' do
      start = described_class.new('simple', label: 'Test Label')
      expect(start.instance_variable_get(:@label)).to eq('Test Label')
    end
  end

  describe '#format' do
    it 'returns self' do
      start = described_class.new
      result = start.format(0, 0, 100)
      expect(result).to eq(start)
    end

    it 'adds path child for simple type' do
      start = described_class.new('simple')
      start.format(0, 0, 100)
      has_path = start.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_path).to be true
    end

    it 'adds path child for complex type' do
      start = described_class.new('complex')
      start.format(0, 0, 100)
      has_path = start.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_path).to be true
    end

    it 'adds text element when label is provided' do
      start = described_class.new('simple', label: 'Label')
      start.format(0, 0, 100)
      has_text = start.children.any? do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) && child.instance_variable_get(:@name) == 'text'
      end
      expect(has_text).to be true
    end

    it 'does not add text element when label is not provided' do
      start = described_class.new('simple')
      start.format(0, 0, 100)
      has_text = start.children.any? do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) && child.instance_variable_get(:@name) == 'text'
      end
      expect(has_text).to be false
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram for simple type' do
      start = described_class.new('simple')
      td = start.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'returns a TextDiagram for complex type' do
      start = described_class.new('complex')
      td = start.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes tee and cross for simple type' do
      start = described_class.new('simple')
      td = start.text_diagram
      expect(td.lines.join("\n")).to include('├')
      expect(td.lines.join("\n")).to include('┼')
    end

    it 'includes tee and line for complex type' do
      start = described_class.new('complex')
      td = start.text_diagram
      expect(td.lines.join("\n")).to include('├')
      expect(td.lines.join("\n")).to include('─')
    end

    it 'includes label when provided' do
      start = described_class.new('simple', label: 'Test')
      td = start.text_diagram
      expect(td.lines.join("\n")).to include('Test')
    end
  end

  describe '#to_s' do
    it 'returns debug string without label' do
      start = described_class.new('simple')
      expect(start.to_s).to eq('Start(simple, label=)')
    end

    it 'returns debug string with label' do
      start = described_class.new('complex', label: 'Label')
      expect(start.to_s).to eq('Start(complex, label=Label)')
    end
  end
end
