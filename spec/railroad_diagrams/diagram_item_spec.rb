require 'spec_helper'

RSpec.describe RailroadDiagrams::DiagramItem do
  describe '#initialize' do
    it 'initializes with name only' do
      item = described_class.new('g')
      expect(item.up).to eq(0)
      expect(item.down).to eq(0)
      expect(item.height).to eq(0)
      expect(item.width).to eq(0)
      expect(item.needs_space).to be false
      expect(item.attrs).to eq({})
      expect(item.children).to eq([])
    end

    it 'initializes with attrs' do
      item = described_class.new('g', attrs: { 'class' => 'test' })
      expect(item.attrs).to eq({ 'class' => 'test' })
    end

    it 'initializes with text' do
      item = described_class.new('text', text: 'hello')
      expect(item.children).to eq(['hello'])
    end

    it 'handles nil attrs' do
      item = described_class.new('g', attrs: nil)
      expect(item.attrs).to eq({})
    end
  end

  describe '#format' do
    it 'raises NotImplementedError' do
      item = described_class.new('g')
      expect { item.format(0, 0, 100) }.to raise_error(NotImplementedError)
    end
  end

  describe '#text_diagram' do
    it 'raises NotImplementedError' do
      item = described_class.new('g')
      expect { item.text_diagram }.to raise_error(NoMethodError)
    end
  end

  describe '#add' do
    it 'adds self to parent children' do
      parent = described_class.new('g')
      child = described_class.new('rect')

      result = child.add(parent)

      expect(parent.children).to include(child)
      expect(result).to eq(child)
    end
  end

  describe '#write_svg' do
    it 'writes basic element' do
      item = described_class.new('rect')
      output = StringIO.new

      item.write_svg(output.method(:write))

      expect(output.string).to eq('<rect></rect>')
    end

    it 'writes element with attributes' do
      item = described_class.new('rect', attrs: { 'x' => '10', 'y' => '20' })
      output = StringIO.new

      item.write_svg(output.method(:write))

      expect(output.string).to include('x="10"')
      expect(output.string).to include('y="20"')
    end

    it 'escapes attribute values' do
      item = described_class.new('text', attrs: { 'data' => 'foo&bar' })
      output = StringIO.new

      item.write_svg(output.method(:write))

      expect(output.string).to include('data="foo&amp;bar"')
    end

    it 'writes g element with newline' do
      item = described_class.new('g')
      output = StringIO.new

      item.write_svg(output.method(:write))

      expect(output.string).to eq("<g>\n</g>")
    end

    it 'writes svg element with newline' do
      item = described_class.new('svg')
      output = StringIO.new

      item.write_svg(output.method(:write))

      expect(output.string).to eq("<svg>\n</svg>")
    end

    it 'writes text children' do
      item = described_class.new('text', text: 'hello')
      output = StringIO.new

      item.write_svg(output.method(:write))

      expect(output.string).to eq('<text>hello</text>')
    end

    it 'escapes text children' do
      item = described_class.new('text', text: 'foo<bar&baz')
      output = StringIO.new

      item.write_svg(output.method(:write))

      expect(output.string).to eq('<text>foo&lt;bar&amp;baz</text>')
    end

    it 'writes nested DiagramItem children' do
      parent = described_class.new('g')
      child = described_class.new('rect')
      child.add(parent)
      output = StringIO.new

      parent.write_svg(output.method(:write))

      expect(output.string).to include('<rect></rect>')
    end

    it 'sorts attributes alphabetically' do
      item = described_class.new('rect', attrs: { 'z' => '1', 'a' => '2', 'm' => '3' })
      output = StringIO.new

      item.write_svg(output.method(:write))

      string = output.string
      a_pos = string.index('a="2"')
      m_pos = string.index('m="3"')
      z_pos = string.index('z="1"')

      expect(a_pos).to be < m_pos
      expect(m_pos).to be < z_pos
    end
  end

  describe '#to_str' do
    it 'returns debug string' do
      item = described_class.new('rect', attrs: { 'x' => '10' })
      result = item.to_str
      expect(result).to include('DiagramItem')
      expect(result).to include('rect')
      expect(result).to include('x')
      expect(result).to include('10')
    end
  end
end
