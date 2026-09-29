require 'spec_helper'

RSpec.describe RailroadDiagrams::AlternatingSequence do
  describe '.new' do
    it 'requires exactly two arguments' do
      expect {
        described_class.new('a')
      }.to raise_error(ArgumentError, /exactly two arguments/)
    end

    it 'raises error with three arguments' do
      expect {
        described_class.new('a', 'b', 'c')
      }.to raise_error(ArgumentError, /exactly two arguments/)
    end

    it 'accepts exactly two arguments' do
      expect {
        described_class.new('a', 'b')
      }.not_to raise_error
    end
  end

  describe '#initialize' do
    it 'wraps string items in Terminal' do
      alt_seq = described_class.new('test1', 'test2')
      items = alt_seq.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
      expect(items.last).to be_a(RailroadDiagrams::Terminal)
    end

    it 'does not require space' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.needs_space).to be false
    end

    it 'calculates width from items' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.width).to be > 0
    end

    it 'calculates up including first item' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.up).to be > 0
    end

    it 'calculates down including second item' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.down).to be > 0
    end

    it 'sets height to 0' do
      alt_seq = described_class.new('a', 'b')
      expect(alt_seq.height).to eq(0)
    end

    it 'accepts DiagramItem arguments' do
      terminal1 = RailroadDiagrams::Terminal.new('first')
      terminal2 = RailroadDiagrams::Terminal.new('second')
      alt_seq = described_class.new(terminal1, terminal2)
      items = alt_seq.instance_variable_get(:@items)
      expect(items).to include(terminal1)
      expect(items).to include(terminal2)
    end
  end

  describe '#format' do
    it 'returns self' do
      alt_seq = described_class.new('a', 'b')
      result = alt_seq.format(0, 0, alt_seq.width)
      expect(result).to eq(alt_seq)
    end

    it 'adds children' do
      alt_seq = described_class.new('a', 'b')
      alt_seq.format(0, 0, alt_seq.width)
      expect(alt_seq.children).not_to be_empty
    end

    it 'formats both items' do
      alt_seq = described_class.new('a', 'b')
      alt_seq.format(0, 0, alt_seq.width)
      items = alt_seq.instance_variable_get(:@items)
      items.each do |item|
        expect(alt_seq.children).to include(item)
      end
    end

    it 'includes path elements for crossover' do
      alt_seq = described_class.new('a', 'b')
      alt_seq.format(0, 0, alt_seq.width)
      has_paths = alt_seq.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_paths).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      alt_seq = described_class.new('A', 'B')
      td = alt_seq.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes both items' do
      alt_seq = described_class.new('FIRST', 'SECOND')
      td = alt_seq.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('FIRST')
      expect(text).to include('SECOND')
    end

    it 'uses cross diagonal for crossover' do
      alt_seq = described_class.new('A', 'B')
      td = alt_seq.text_diagram
      expect(td.lines.join("\n")).to include('╳')
    end

    it 'uses corner characters' do
      alt_seq = described_class.new('A', 'B')
      td = alt_seq.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[╭╮╯╰]/)
    end
  end

  describe 'context rendering' do
    it 'matches legacy dimensions, SVG bytes, and text lines for nested children' do
      build = -> { described_class.new(RailroadDiagrams::Stack.new('A', 'B'), RailroadDiagrams::Sequence.new('C', 'D')) }
      node = build.call
      legacy = build.call
      context = RailroadDiagrams::Context.new
      metrics = context.metrics(node)
      legacy.format(0, 100, legacy.width + 11)
      legacy_svg = +''
      legacy.write_svg(legacy_svg)

      expect([metrics.width, metrics.up, metrics.height, metrics.down]).to eq([node.width, node.up, node.height, node.down])
      expect(RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 100, metrics.width + 11))).to eq(legacy_svg)
      expect(node.render_text(context).lines).to eq(node.text_diagram.lines)
    end

    it 'keeps arc radius and vertical separation local to each context' do
      node = described_class.new('A', 'B')
      normal = RailroadDiagrams::Context.new
      wider_arcs = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 12))
      more_space = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(vertical_separation: 14))

      expect([normal.metrics(node).width, normal.metrics(node).up]).to eq([88.5, 36])
      expect([wider_arcs.metrics(node).width, wider_arcs.metrics(node).up]).to eq([96.5, 41])
      expect([more_space.metrics(node).width, more_space.metrics(node).up]).to eq([88.5, 43])
      expect(RailroadDiagrams::Svg::Serializer.call(node.render_svg(wider_arcs, 0, 100, wider_arcs.metrics(node).width))).to include('a12 12')
      expect(RailroadDiagrams::Svg::Serializer.call(node.render_svg(normal, 0, 100, normal.metrics(node).width))).to include('a10 10')
      expect(node.width).to eq(88.5)
    end

    it 'renders a shared child twice without changing it' do
      child = RailroadDiagrams::Terminal.new('A')
      node = described_class.new(child, child)
      context = RailroadDiagrams::Context.new
      svg = node.render_svg(context, 0, 100, context.metrics(node).width)
      groups = svg.children.select { |element| element.name == 'g' }

      expect(node.child_nodes).to eq([child, child])
      expect(groups.map { |group| group.children.find { |element| element.name == 'rect' }.attrs['y'] }).to eq([64, 114])
      expect(node.children).to be_empty
      expect(child.children).to be_empty
    end

    it 'uses ASCII text parts for nested children' do
      node = described_class.new(RailroadDiagrams::Sequence.new('A', 'B'), 'C')
      context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))
      expect(node.render_text(context).lines.join).to match(/\A[\x00-\x7F]*\z/)
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      alt_seq = described_class.new('a', 'b')
      result = alt_seq.to_s
      expect(result).to start_with('AlternatingSequence(')
      expect(result).to include('Terminal')
    end
  end
end
