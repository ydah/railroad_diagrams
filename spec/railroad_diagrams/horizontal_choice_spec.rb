require 'spec_helper'

RSpec.describe RailroadDiagrams::HorizontalChoice do
  describe '.new' do
    it 'returns Sequence for single item' do
      result = described_class.new('single')
      expect(result).to be_a(RailroadDiagrams::Sequence)
    end

    it 'returns HorizontalChoice for multiple items' do
      result = described_class.new('a', 'b')
      expect(result).to be_a(described_class)
    end
  end

  describe '#initialize' do
    it 'accepts multiple items' do
      hc = described_class.new('a', 'b', 'c')
      expect(hc.instance_variable_get(:@items).length).to eq(3)
    end

    it 'wraps string items in Terminal' do
      hc = described_class.new('test', 'other')
      items = hc.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'does not require space' do
      hc = described_class.new('a', 'b')
      expect(hc.needs_space).to be false
    end

    it 'calculates width from items' do
      hc = described_class.new('a', 'b', 'c')
      expect(hc.width).to be > 0
    end

    it 'sets height to 0' do
      hc = described_class.new('a', 'b')
      expect(hc.height).to eq(0)
    end

    it 'calculates upper_track' do
      hc = described_class.new('a', 'b', 'c')
      upper_track = hc.instance_variable_get(:@upper_track)
      expect(upper_track).to be >= RailroadDiagrams::AR * 2
    end

    it 'calculates lower_track' do
      hc = described_class.new('a', 'b', 'c')
      lower_track = hc.instance_variable_get(:@lower_track)
      expect(lower_track).to be >= RailroadDiagrams::VS
    end
  end

  describe '#format' do
    it 'returns self' do
      hc = described_class.new('a', 'b')
      result = hc.format(0, 0, hc.width)
      expect(result).to eq(hc)
    end

    it 'adds children' do
      hc = described_class.new('a', 'b')
      hc.format(0, 0, hc.width)
      expect(hc.children).not_to be_empty
    end

    it 'formats all items' do
      hc = described_class.new('a', 'b', 'c')
      hc.format(0, 0, hc.width)
      items = hc.instance_variable_get(:@items)
      items.each do |item|
        expect(hc.children).to include(item)
      end
    end

    it 'includes path elements for tracks' do
      hc = described_class.new('a', 'b')
      hc.format(0, 0, hc.width)
      has_paths = hc.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_paths).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      hc = described_class.new('A', 'B')
      td = hc.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes all items' do
      hc = described_class.new('FIRST', 'SECOND', 'THIRD')
      td = hc.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('FIRST')
      expect(text).to include('SECOND')
      expect(text).to include('THIRD')
    end

    it 'uses vertical lines for tracks' do
      hc = described_class.new('A', 'B')
      td = hc.text_diagram
      expect(td.lines.join("\n")).to include('│')
    end

    it 'uses corner characters' do
      hc = described_class.new('A', 'B')
      td = hc.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[╭╮╯╰]/)
    end
  end

  describe 'Context rendering' do
    it 'matches legacy SVG and text without mutating the choice or its children' do # rubocop:disable RSpec/ExampleLength
      [described_class.new('A', 'B'), described_class.new('A', 'BB', 'C'),
       described_class.new(RailroadDiagrams::Sequence.new('A', 'B'), 'C'),
       described_class.new(RailroadDiagrams::Stack.new('A', 'B'), 'C'),
       described_class.new('A', RailroadDiagrams::Stack.new('B', 'C')),
       described_class.new('A', RailroadDiagrams::Stack.new('B', 'C'), 'D')].each do |choice|
        context = RailroadDiagrams::Context.new
        width = context.metrics(choice).width + 13
        legacy = Marshal.load(Marshal.dump(choice))
        legacy.format(5, 50, width)
        expected_svg = +''
        legacy.write_svg(expected_svg)
        expected_text = legacy.text_diagram

        actual_svg = RailroadDiagrams::Svg::Serializer.call(choice.render_svg(context, 5, 50, width))
        actual_text = choice.render_text(context)

        expect(actual_svg).to eq(expected_svg)
        expect([actual_text.entry, actual_text.exit, actual_text.lines])
          .to eq([expected_text.entry, expected_text.exit, expected_text.lines])
        expect(choice.children).to be_empty
        expect(choice.child_nodes.map(&:children)).to all(be_empty)
        expect(RailroadDiagrams::Svg::Serializer.call(choice.render_svg(context, 5, 50, width))).to eq(actual_svg)
      end
    end

    it 'uses separate arc and spacing options in each Context' do
      choice = described_class.new('A', 'B')
      small = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 10))
      large_options = RailroadDiagrams.default_options.merge(arc_radius: 12, vertical_separation: 30)
      large = RailroadDiagrams::Context.new(large_options)

      expect([small.metrics(choice).width, small.metrics(choice).up, small.metrics(choice).down]).to eq([137.0, 20, 20])
      expect([large.metrics(choice).width, large.metrics(choice).up, large.metrics(choice).down]).to eq([145.0, 41, 41])
      svg = RailroadDiagrams::Svg::Serializer.call(choice.render_svg(large, 0, 50, large.metrics(choice).width))
      expect(svg).to include('a12 12')
      expect(choice.children).to be_empty
      expect(choice.child_nodes.length).to eq(2)
    end

    it 'uses ASCII parts without changing the global text format' do
      choice = described_class.new('A', 'B')
      context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))

      text = choice.render_text(context).lines.join("\n")

      expect(text).to include('/', '\\', '-')
      expect(text).not_to include('─')
      expect(RailroadDiagrams::TextDiagram.get_parts(['line'])).to eq(['─'])
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      hc = described_class.new('a', 'b')
      result = hc.to_s
      expect(result).to start_with('HorizontalChoice(')
      expect(result).to include('Terminal')
    end
  end
end
