require 'spec_helper'

RSpec.describe RailroadDiagrams::Diagram do
  describe '#initialize' do
    it 'accepts items' do
      diagram = described_class.new('item')
      expect(diagram.instance_variable_get(:@items)).not_to be_empty
    end

    it 'automatically adds Start if not present' do
      diagram = described_class.new('item')
      items = diagram.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Start)
    end

    it 'automatically adds End if not present' do
      diagram = described_class.new('item')
      items = diagram.instance_variable_get(:@items)
      expect(items.last).to be_a(RailroadDiagrams::End)
    end

    it 'does not add Start if already present' do
      start = RailroadDiagrams::Start.new
      diagram = described_class.new(start, 'item')
      items = diagram.instance_variable_get(:@items)
      expect(items.count { |i| i.is_a?(RailroadDiagrams::Start) }).to eq(1)
    end

    it 'does not add End if already present' do
      end_node = RailroadDiagrams::End.new
      diagram = described_class.new('item', end_node)
      items = diagram.instance_variable_get(:@items)
      expect(items.count { |i| i.is_a?(RailroadDiagrams::End) }).to eq(1)
    end

    it 'accepts type option' do
      diagram = described_class.new('item', type: 'complex')
      expect(diagram.instance_variable_get(:@type)).to eq('complex')
    end

    it 'defaults to simple type' do
      diagram = described_class.new('item')
      expect(diagram.instance_variable_get(:@type)).to eq('simple')
    end

    it 'wraps string items in Terminal' do
      diagram = described_class.new('test')
      items = diagram.instance_variable_get(:@items)
      terminal = items.find { |i| i.is_a?(RailroadDiagrams::Terminal) }
      expect(terminal).not_to be_nil
    end

    it 'calculates width from items' do
      diagram = described_class.new('a', 'b')
      expect(diagram.width).to be > 0
    end

    it 'calculates height from items' do
      diagram = described_class.new('a', 'b')
      expect(diagram.height).to be >= 0
    end

    it 'is an svg element' do
      diagram = described_class.new('item')
      expect(diagram.instance_variable_get(:@name)).to eq('svg')
    end

    it 'has diagram class' do
      diagram = described_class.new('item')
      expect(diagram.attrs['class']).to eq('railroad-diagram')
    end
  end

  describe '#format' do
    it 'returns self' do
      diagram = described_class.new('item')
      result = diagram.format
      expect(result).to eq(diagram)
    end

    it 'sets formatted flag' do
      diagram = described_class.new('item')
      diagram.format
      expect(diagram.instance_variable_get(:@formatted)).to be true
    end

    it 'accepts padding parameters' do
      diagram = described_class.new('item')
      result = diagram.format(10, 20, 30, 40)
      expect(result).to be_a(described_class)
    end

    it 'sets width attribute' do
      diagram = described_class.new('item')
      diagram.format
      expect(diagram.attrs['width']).not_to be_nil
    end

    it 'sets height attribute' do
      diagram = described_class.new('item')
      diagram.format
      expect(diagram.attrs['height']).not_to be_nil
    end

    it 'sets viewBox attribute' do
      diagram = described_class.new('item')
      diagram.format
      expect(diagram.attrs['viewBox']).not_to be_nil
    end

    it 'adds g element as child' do
      diagram = described_class.new('item')
      diagram.format
      has_g = diagram.children.any? do |c|
        c.is_a?(RailroadDiagrams::DiagramItem) && c.instance_variable_get(:@name) == 'g'
      end
      expect(has_g).to be true
    end
  end

  describe '#write_svg' do
    it 'outputs valid SVG' do
      diagram = described_class.new('hello')
      output = StringIO.new
      diagram.write_svg(output.method(:write))
      svg = output.string

      expect(svg).to include('<svg')
      expect(svg).to include('</svg>')
      expect(svg).to include('railroad-diagram')
    end

    it 'formats diagram if not already formatted' do
      diagram = described_class.new('hello')
      expect(diagram.instance_variable_get(:@formatted)).to be false
      output = StringIO.new
      diagram.write_svg(output.method(:write))
      expect(diagram.instance_variable_get(:@formatted)).to be true
    end

    it 'includes items in output' do
      diagram = described_class.new('TEST')
      output = StringIO.new
      diagram.write_svg(output.method(:write))
      expect(output.string).to include('TEST')
    end
  end

  describe '#write_text' do
    it 'outputs text diagram' do
      diagram = described_class.new('A')
      output = StringIO.new
      diagram.write_text(output.method(:write))

      text = output.string
      expect(text).to include('A')
      expect(text).to end_with("\n")
    end

    it 'escapes special characters' do
      diagram = described_class.new('<test>')
      output = StringIO.new
      diagram.write_text(output.method(:write))

      text = output.string
      expect(text).to include('&lt;')
      expect(text).to include('&gt;')
    end
  end

  describe '#write_standalone' do
    it 'adds xmlns attributes' do
      diagram = described_class.new('item')
      output = StringIO.new
      diagram.write_standalone(output.method(:write), true)

      expect(output.string).to include('xmlns')
    end

    it 'formats diagram if not already formatted' do
      diagram = described_class.new('item')
      expect(diagram.instance_variable_get(:@formatted)).to be false
      output = StringIO.new
      diagram.write_standalone(output.method(:write))
      expect(diagram.instance_variable_get(:@formatted)).to be true
    end

    it 'adds default style when css is true' do
      diagram = described_class.new('item')
      output = StringIO.new
      diagram.write_standalone(output.method(:write), true)
      expect(output.string).to include('<style')
    end

    it 'cleans up xmlns attributes after writing' do
      diagram = described_class.new('item')
      output = StringIO.new
      diagram.write_standalone(output.method(:write))
      expect(diagram.attrs['xmlns']).to be_nil
      expect(diagram.attrs['xmlns:xlink']).to be_nil
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      diagram = described_class.new('A')
      td = diagram.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes all items' do
      diagram = described_class.new('A', 'B')
      td = diagram.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('A')
      expect(text).to include('B')
    end

    it 'includes start and end' do
      diagram = described_class.new('A')
      td = diagram.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('├')
      expect(text).to include('┤')
    end
  end

  describe '#to_s' do
    it 'has to_s method' do
      diagram = described_class.new('item')
      expect(diagram).to respond_to(:to_s)
    end
  end
end
