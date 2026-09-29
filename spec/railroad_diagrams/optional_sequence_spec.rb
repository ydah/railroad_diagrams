require 'spec_helper'

RSpec.describe RailroadDiagrams::OptionalSequence do
  describe '.new' do
    it 'returns Sequence for single item' do
      result = described_class.new('single')
      expect(result).to be_a(RailroadDiagrams::Sequence)
    end

    it 'returns OptionalSequence for multiple items' do
      result = described_class.new('a', 'b')
      expect(result).to be_a(described_class)
    end
  end

  describe '#initialize' do
    it 'accepts multiple items' do
      opt_seq = described_class.new('a', 'b', 'c')
      expect(opt_seq.instance_variable_get(:@items).length).to eq(3)
    end

    it 'wraps string items in Terminal' do
      opt_seq = described_class.new('test', 'other')
      items = opt_seq.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'does not require space' do
      opt_seq = described_class.new('a', 'b')
      expect(opt_seq.needs_space).to be false
    end

    it 'calculates width from items' do
      opt_seq = described_class.new('a', 'b', 'c')
      expect([opt_seq.width, opt_seq.up, opt_seq.height, opt_seq.down]).to eq([185.5, 20.0, 0, 20.0])
    end

    it 'calculates height from all items' do
      opt_seq = described_class.new('a', 'b', 'c')
      items = opt_seq.instance_variable_get(:@items)
      expected_height = items.sum(&:height)
      expect(opt_seq.height).to eq(expected_height)
    end

    it 'calculates down value' do
      terminal1 = RailroadDiagrams::Terminal.new('first')
      terminal2 = RailroadDiagrams::Terminal.new('second')
      opt_seq = described_class.new(terminal1, terminal2)
      expect([opt_seq.down, terminal1.down]).to eq([20.0, 11])
    end

    it 'calculates up' do
      opt_seq = described_class.new('a', 'b')
      expect(opt_seq.up).to eq(20.0)
    end
  end

  describe '#format' do
    it 'returns self' do
      opt_seq = described_class.new('a', 'b')
      result = opt_seq.format(0, 0, opt_seq.width)
      expect(result).to eq(opt_seq)
    end

    it 'adds children' do
      opt_seq = described_class.new('a', 'b')
      opt_seq.format(0, 0, opt_seq.width)
      expect(opt_seq.children).not_to be_empty
    end

    it 'formats all items' do
      opt_seq = described_class.new('a', 'b', 'c')
      opt_seq.format(0, 0, opt_seq.width)
      items = opt_seq.instance_variable_get(:@items)
      items.each do |item|
        expect(opt_seq.children).to include(item)
      end
    end

    it 'includes path elements for skip lines' do
      opt_seq = described_class.new('a', 'b')
      opt_seq.format(0, 0, opt_seq.width)
      has_paths = opt_seq.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_paths).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      opt_seq = described_class.new('A', 'B')
      td = opt_seq.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes all items' do
      opt_seq = described_class.new('FIRST', 'SECOND', 'THIRD')
      td = opt_seq.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('FIRST')
      expect(text).to include('SECOND')
      expect(text).to include('THIRD')
    end

    it 'uses vertical lines for skip paths' do
      opt_seq = described_class.new('A', 'B')
      td = opt_seq.text_diagram
      expect(td.lines.join("\n")).to include('│')
    end

    it 'uses corner characters' do
      opt_seq = described_class.new('A', 'B')
      td = opt_seq.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[╭╮╯╰]/)
    end

    it 'shows skip-over line at top' do
      opt_seq = described_class.new('A', 'B', 'C')
      td = opt_seq.text_diagram
      expect(td.lines.first).to include('─')
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      opt_seq = described_class.new('a', 'b')
      result = opt_seq.to_s
      expect(result).to start_with('OptionalSequence(')
      expect(result).to include('Terminal')
    end
  end

  describe 'context rendering' do
    let(:node) { described_class.new('A', RailroadDiagrams::Choice.new(0, 'B', 'C'), 'D') }
    let(:legacy_svg) do
      copy = described_class.new('A', RailroadDiagrams::Choice.new(0, 'B', 'C'), 'D')
      copy.format(0, 100, copy.width)
      output = +''
      copy.write_svg(output)
      output
    end

    it 'keeps the upper bypass separate from a deep final branch' do
      node = described_class.new('a', RailroadDiagrams::Choice.new(1, 'x', 'y'))
      lines = node.render_text(RailroadDiagrams::Context.new).lines.map(&:rstrip)
      expect(lines).to eq([
                            '', '                 ╭───╮', '              ╭──│ x │──╮',
                            '              │  ╰───╯  │', '╭───────────╮ │         │',
                            '│  ╭───╮    │ │  ╭───╮  │', '╯──│ a │──╮─╰─╯──│ y │──╰─╭',
                            '   ╰───╯  │      ╰───╯    │', '          ╰───────────────╯'
                          ])
    end

    it 'preserves legacy SVG and text output without mutating children' do
      context = RailroadDiagrams::Context.new
      expected_text = node.text_diagram.lines
      children = node.children.dup

      expect(RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 100, context.metrics(node).width))).to eq(legacy_svg)
      expect(node.render_text(context).lines).to eq(expected_text)
      expect(node.children).to eq(children)
      expect(node.child_nodes.length).to eq(3)
    end

    it 'uses the supplied arc radius independently' do
      small = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 10))
      large = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 12))
      expect(large.metrics(node).width).to be > small.metrics(node).width
      expect(RailroadDiagrams::Svg::Serializer.call(node.render_svg(small, 0, 100, small.metrics(node).width))).to include('a10 10')
      expect(RailroadDiagrams::Svg::Serializer.call(node.render_svg(large, 0, 100, large.metrics(node).width))).to include('a12 12')
    end
  end
end
