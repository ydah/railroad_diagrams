require 'spec_helper'

RSpec.describe RailroadDiagrams::Stack do
  describe '#initialize' do
    it 'accepts multiple items' do
      stack = described_class.new('a', 'b', 'c')
      expect(stack.instance_variable_get(:@items).length).to eq(3)
    end

    it 'wraps string items in Terminal' do
      stack = described_class.new('test')
      items = stack.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'requires space when nested, like the upstream renderer' do
      expect(described_class.new('a', 'b').needs_space).to be true
    end

    it 'calculates width from widest item' do
      stack = described_class.new('a', 'longer')
      longer_terminal = RailroadDiagrams::Terminal.new('longer')
      expect(stack.width).to be >= longer_terminal.width
    end

    it 'sets up to first item up' do
      terminal = RailroadDiagrams::Terminal.new('test')
      stack = described_class.new(terminal, 'other')
      expect(stack.up).to eq(terminal.up)
    end

    it 'sets down to last item down' do
      stack = described_class.new('first', 'second')
      items = stack.instance_variable_get(:@items)
      expect(stack.down).to eq(items.last.down)
    end

    it 'calculates height from all items' do
      stack = described_class.new('a', 'b', 'c')
      expect(stack.height).to be > 0
    end

    it 'adds arc width for multiple items' do
      stack_single = described_class.new('a')
      stack_multiple = described_class.new('a', 'b')
      expect(stack_multiple.width).to be > stack_single.width
    end
  end

  describe '#format' do
    it 'returns self' do
      stack = described_class.new('a', 'b')
      result = stack.format(0, 0, stack.width)
      expect(result).to eq(stack)
    end

    it 'adds children' do
      stack = described_class.new('a', 'b')
      stack.format(0, 0, stack.width)
      expect(stack.children).not_to be_empty
    end

    it 'formats all items' do
      stack = described_class.new('a', 'b', 'c')
      stack.format(0, 0, stack.width)
      items = stack.instance_variable_get(:@items)
      items.each do |item|
        expect(stack.children).to include(item)
      end
    end

    it 'includes path elements for connections' do
      stack = described_class.new('a', 'b')
      stack.format(0, 0, stack.width)
      has_paths = stack.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_paths).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      stack = described_class.new('A', 'B')
      td = stack.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes all items vertically' do
      stack = described_class.new('A', 'B', 'C')
      td = stack.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('A')
      expect(text).to include('B')
      expect(text).to include('C')
    end

    it 'uses corner characters for connections' do
      stack = described_class.new('A', 'B')
      td = stack.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[┌└╭╮╯╰]/)
    end

    it 'uses vertical lines for connections' do
      stack = described_class.new('A', 'B')
      td = stack.text_diagram
      expect(td.lines.join("\n")).to include('│')
    end
  end

  describe 'Context rendering' do
    it 'measures children with the selected spacing and arc radius' do
      options = RailroadDiagrams.default_options.merge(char_width: 12, arc_radius: 15, vertical_separation: 10)
      context = RailroadDiagrams::Context.new(options)
      stack = described_class.new('a', 'bb')

      metrics = context.metrics(stack)

      expect([metrics.width, metrics.up, metrics.height, metrics.down, metrics.needs_space])
        .to eq([94, 11, 60, 11, true])
      expect(stack.child_nodes.length).to eq(2)
      expect(stack.width).to eq(77.0)
    end

    it 'matches legacy SVG and Unicode text without changing the stack or its children' do # rubocop:disable RSpec/ExampleLength
      [described_class.new('A'), described_class.new('A', 'BB', 'C'),
       described_class.new('A', described_class.new('B', 'C'))].each do |stack|
        context = RailroadDiagrams::Context.new
        width = context.metrics(stack).width + 13
        legacy = Marshal.load(Marshal.dump(stack))
        legacy.format(5, 30, width)
        expected_svg = +''
        legacy.write_svg(expected_svg)
        expected_text = legacy.text_diagram

        actual_svg = RailroadDiagrams::Svg::Serializer.call(stack.render_svg(context, 5, 30, width))
        actual_text = stack.render_text(context)

        expect(actual_svg).to eq(expected_svg)
        expect([actual_text.entry, actual_text.exit, actual_text.lines])
          .to eq([expected_text.entry, expected_text.exit, expected_text.lines])
        expect(stack.children).to be_empty
        expect(stack.child_nodes.map(&:children)).to all(be_empty)
        expect(RailroadDiagrams::Svg::Serializer.call(stack.render_svg(context, 5, 30, width))).to eq(actual_svg)
      end
    end

    it 'uses the Context character set without changing global text formatting' do
      ascii = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))
      stack = described_class.new('A', 'B')

      expect(stack.render_text(ascii).lines.join("\n")).to include('---| A |--\\', '\\--| B |---')
      expect(RailroadDiagrams::TextDiagram.get_parts(['line'])).to eq(['─'])
      expect(stack.children).to be_empty
    end

    it 'keeps measurements and paths separate across Context instances' do
      stack = described_class.new('A', 'B')
      small = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 10))
      large = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 12))

      expect([small.metrics(stack).width, small.metrics(stack).height]).to eq([68.5, 40])
      expect([large.metrics(stack).width, large.metrics(stack).height]).to eq([72.5, 48])
      small_svg = RailroadDiagrams::Svg::Serializer.call(stack.render_svg(small, 0, 20, small.metrics(stack).width))
      large_svg = RailroadDiagrams::Svg::Serializer.call(stack.render_svg(large, 0, 20, large.metrics(stack).width))
      expect(small_svg).to include('a10 10')
      expect(large_svg).to include('a12 12')
      expect(stack.children).to be_empty
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      stack = described_class.new('a', 'b')
      result = stack.to_s
      expect(result).to start_with('Stack(')
      expect(result).to include('Terminal')
    end
  end
end
