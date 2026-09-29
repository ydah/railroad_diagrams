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

  describe 'Context rendering' do
    it 'measures from Context options without changing legacy dimensions' do
      node = described_class.new(1, 'any', 'a', 'longer', 'c')
      normal = RailroadDiagrams::Context.new
      wide = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 12))
      measured = normal.metrics(node)

      expect([measured.width, measured.up, measured.height, measured.down, measured.needs_space])
        .to eq([node.width, node.up, node.height, node.down, true])
      expect(wide.metrics(node).width).to eq(measured.width + 4)
      expect(normal.metrics(node)).to equal(measured)
      expect(node.width).to eq(measured.width)
    end

    it 'matches legacy SVG bytes for branches above, on, and below the default' do # rubocop:disable RSpec/ExampleLength
      [0, 1, 2].product(%w[any all]).each do |default, type|
        node = described_class.new(default, type, 'a', 'b', 'c')
        context = RailroadDiagrams::Context.new
        actual = RailroadDiagrams::Svg::Serializer.call(
          node.render_svg(context, 0, 100, context.metrics(node).width + 10)
        )
        expect(node.children).to be_empty
        expect(node.child_nodes.flat_map(&:children)).to be_empty

        legacy = described_class.new(default, type, 'a', 'b', 'c')
        legacy.format(0, 100, legacy.width + 10)
        expected = +''
        legacy.write_svg(expected)
        expect(actual).to eq(expected)
      end
    end

    it 'uses the configured arc radius in SVG without changing the node' do
      node = described_class.new(1, 'all', 'a', 'b', 'c')
      normal = RailroadDiagrams::Context.new
      context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 12))
      first = RailroadDiagrams::Svg::Serializer.call(node.render_svg(normal, 0, 100, normal.metrics(node).width))
      svg = RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 100, context.metrics(node).width))

      expect(svg).to include('a12 12')
      expect(svg).to include('take all branches, once each, in any order')
      expect(svg).not_to eq(first)
      expect(RailroadDiagrams::Svg::Serializer.call(node.render_svg(normal, 0, 100, normal.metrics(node).width))).to eq(first)
      expect(node.children).to be_empty
    end

    it 'preserves SVG geometry for children with nonzero height' do
      items = [RailroadDiagrams::Stack.new('a', 'b'), 'middle', RailroadDiagrams::Stack.new('c', 'd')]
      node = described_class.new(1, 'any', *items)
      context = RailroadDiagrams::Context.new
      actual = RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 100, context.metrics(node).width))

      legacy_items = [RailroadDiagrams::Stack.new('a', 'b'), 'middle', RailroadDiagrams::Stack.new('c', 'd')]
      legacy = described_class.new(1, 'any', *legacy_items)
      legacy.format(0, 100, legacy.width)
      expected = +''
      legacy.write_svg(expected)
      expect(actual).to eq(expected)
    end

    it 'matches legacy text for both branch modes' do
      unicode = RailroadDiagrams::Context.new
      %w[any all].each do |type|
        node = described_class.new(1, type, 'a', 'b', 'c')
        rendered = node.render_text(unicode)
        legacy = node.text_diagram
        expect([rendered.entry, rendered.exit, rendered.lines]).to eq([legacy.entry, legacy.exit, legacy.lines])
      end
    end

    it 'uses the Context character set without changing the node' do
      node = described_class.new(1, 'any', 'a', 'b', 'c')
      ascii = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))
      unicode = RailroadDiagrams::Context.new
      ascii_text = node.render_text(ascii).lines.join("\n")
      expect(ascii_text).to include('&')
      expect(ascii_text.ascii_only?).to be true
      expect(node.render_text(unicode).lines.join("\n")).to include('↺')
      expect(node.children).to be_empty
    end

    it 'exposes child nodes in order without exposing the internal array' do
      node = described_class.new(0, 'any', 'a', 'b')
      children = node.child_nodes
      expect(children.map { |child| child.instance_variable_get(:@text) }).to eq(%w[a b])
      children.clear
      expect(node.child_nodes.length).to eq(2)
    end
  end
end
