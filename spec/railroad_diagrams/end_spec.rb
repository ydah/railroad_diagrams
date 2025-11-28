require 'spec_helper'

RSpec.describe RailroadDiagrams::End do
  describe '#initialize' do
    it 'defaults to simple type' do
      end_node = described_class.new
      expect(end_node.instance_variable_get(:@type)).to eq('simple')
    end

    it 'accepts complex type' do
      end_node = described_class.new('complex')
      expect(end_node.instance_variable_get(:@type)).to eq('complex')
    end

    it 'sets width to 20' do
      end_node = described_class.new
      expect(end_node.width).to eq(20)
    end

    it 'sets up and down to 10' do
      end_node = described_class.new
      expect(end_node.up).to eq(10)
      expect(end_node.down).to eq(10)
    end

    it 'is a path element' do
      end_node = described_class.new
      expect(end_node.instance_variable_get(:@name)).to eq('path')
    end
  end

  describe '#format' do
    it 'returns self' do
      end_node = described_class.new
      result = end_node.format(0, 0, 100)
      expect(result).to eq(end_node)
    end

    it 'sets d attribute for simple type' do
      end_node = described_class.new('simple')
      end_node.format(10, 20, 100)
      expect(end_node.attrs['d']).to eq('M 10 20 h 20 m -10 -10 v 20 m 10 -20 v 20')
    end

    it 'sets d attribute for complex type' do
      end_node = described_class.new('complex')
      end_node.format(10, 20, 100)
      expect(end_node.attrs['d']).to eq('M 10 20 h 20 m 0 -10 v 20')
    end

    it 'uses correct x position' do
      end_node = described_class.new('simple')
      end_node.format(50, 60, 100)
      expect(end_node.attrs['d']).to start_with('M 50 60')
    end

    it 'uses correct y position' do
      end_node = described_class.new('simple')
      end_node.format(10, 100, 100)
      expect(end_node.attrs['d']).to start_with('M 10 100')
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram for simple type' do
      end_node = described_class.new('simple')
      td = end_node.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'returns a TextDiagram for complex type' do
      end_node = described_class.new('complex')
      td = end_node.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes cross and tee for simple type' do
      end_node = described_class.new('simple')
      td = end_node.text_diagram
      expect(td.lines.join("\n")).to include('┼')
      expect(td.lines.join("\n")).to include('┤')
    end

    it 'includes line and tee for complex type' do
      end_node = described_class.new('complex')
      td = end_node.text_diagram
      expect(td.lines.join("\n")).to include('─')
      expect(td.lines.join("\n")).to include('┤')
    end

    it 'has single line' do
      end_node = described_class.new('simple')
      td = end_node.text_diagram
      expect(td.lines.length).to eq(1)
    end
  end

  describe '#to_s' do
    it 'returns debug string for simple type' do
      end_node = described_class.new('simple')
      expect(end_node.to_s).to eq('End(type=simple)')
    end

    it 'returns debug string for complex type' do
      end_node = described_class.new('complex')
      expect(end_node.to_s).to eq('End(type=complex)')
    end
  end
end
