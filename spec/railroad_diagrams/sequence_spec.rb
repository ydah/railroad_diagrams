require 'spec_helper'

RSpec.describe RailroadDiagrams::Sequence do
  describe '#initialize' do
    it 'accepts multiple items' do
      seq = described_class.new('a', 'b', 'c')
      expect(seq.instance_variable_get(:@items).length).to eq(3)
    end

    it 'wraps string items in Terminal' do
      seq = described_class.new('test')
      items = seq.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'requires space when nested, like the upstream renderer' do
      seq = described_class.new('a', 'b')
      expect(seq.needs_space).to be true
    end

    it 'calculates width from items' do
      terminal1 = RailroadDiagrams::Terminal.new('a')
      terminal2 = RailroadDiagrams::Terminal.new('b')
      seq = described_class.new(terminal1, terminal2)

      expected_width = terminal1.width + 20 + terminal2.width + 20 - 10 - 10
      expect(seq.width).to eq(expected_width)
    end

    it 'calculates up from maximum item up' do
      seq = described_class.new('a', 'b')
      expect(seq.up).to eq(11)
    end

    it 'calculates down from maximum item down' do
      seq = described_class.new('a', 'b')
      expect(seq.down).to eq(11)
    end

    it 'handles items without space' do
      skip_item = RailroadDiagrams::Skip.new
      seq = described_class.new(skip_item)
      expect(seq.width).to eq(skip_item.width)
    end
  end

  describe '#format' do
    it 'returns self' do
      seq = described_class.new('a', 'b')
      result = seq.format(0, 0, seq.width)
      expect(result).to eq(seq)
    end

    it 'adds children' do
      seq = described_class.new('a', 'b')
      seq.format(0, 0, seq.width)
      expect(seq.children).not_to be_empty
    end

    it 'formats all items' do
      seq = described_class.new('a', 'b', 'c')
      seq.format(0, 0, seq.width)
      items = seq.instance_variable_get(:@items)
      items.each do |item|
        expect(seq.children).to include(item)
      end
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      seq = described_class.new('a', 'b')
      td = seq.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'joins items horizontally' do
      seq = described_class.new('A', 'B')
      td = seq.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('A')
      expect(text).to include('B')
    end

    it 'uses separator between items' do
      seq = described_class.new('A', 'B')
      td = seq.text_diagram
      expect(td.lines.join("\n")).to include('─')
    end
  end

  describe 'context rendering' do
    it 'measures its children with context options and exposes them in order' do
      sequence = described_class.new('日本', RailroadDiagrams::Skip.new, 'B')
      context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(char_width: 10))

      expect(sequence.child_nodes).to eq(sequence.instance_variable_get(:@items))
      expect([context.metrics(sequence).width, context.metrics(sequence).up,
              context.metrics(sequence).height, context.metrics(sequence).down]).to eq([110, 11, 0, 11])
      expect(sequence.width).to eq(102.5)
    end

    it 'renders the same SVG and text as the legacy path without changing the node' do
      sequence = described_class.new('A', RailroadDiagrams::Skip.new, 'B')
      context = RailroadDiagrams::Context.new
      expected_svg_node = described_class.new('A', RailroadDiagrams::Skip.new, 'B')
      expected_svg_node.format(0, 100, expected_svg_node.width + 11)
      expected_svg = +''
      expected_svg_node.write_svg(expected_svg)
      rendered = RailroadDiagrams::Svg::Serializer.call(sequence.render_svg(context, 0, 100, context.metrics(sequence).width + 11))
      expect(rendered).to eq(expected_svg)
      expect(sequence.render_text(context).lines).to eq(sequence.text_diagram.lines)
      expect(sequence.children).to be_empty
      expect(sequence.child_nodes.map(&:children)).to all(be_empty)
    end

    it 'uses the configured text character set for spacing' do
      context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))
      sequence = described_class.new('A', 'B')
      expect(sequence.render_text(context).lines).to eq(['   /---\\     /---\\  ',
                                                         '---| A |-----| B |--',
                                                         '   \\---/     \\---/  '])
    end

    it 'keeps the legacy output for nested sequences' do
      context = RailroadDiagrams::Context.new
      sequence = described_class.new('A', described_class.new('B', 'C'))
      expected = described_class.new('A', described_class.new('B', 'C'))
      expected.format(0, 100, expected.width)
      legacy_svg = +''
      expected.write_svg(legacy_svg)

      svg = RailroadDiagrams::Svg::Serializer.call(sequence.render_svg(context, 0, 100, context.metrics(sequence).width))
      expect(svg).to eq(legacy_svg)
      expect(sequence.render_text(context).lines).to eq(sequence.text_diagram.lines)
      expect(sequence.child_nodes.last.children).to be_empty
    end

    it 'renders a shared child at each occurrence without moving the child' do
      child = RailroadDiagrams::Terminal.new('A')
      sequence = described_class.new(child, child)
      context = RailroadDiagrams::Context.new
      group = sequence.render_svg(context, 0, 100, context.metrics(sequence).width)
      child_groups = group.children.select { |element| element.name == 'g' }

      expect(child_groups.map { |item| item.children.find { |element| element.name == 'rect' }.attrs['x'] }).to eq([0.0, 48.5])
      expect(child.children).to be_empty
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      seq = described_class.new('a', 'b')
      result = seq.to_s
      expect(result).to start_with('Sequence(')
      expect(result).to include('Terminal')
    end
  end
end
