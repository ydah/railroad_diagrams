require 'spec_helper'

RSpec.describe RailroadDiagrams::Choice do
  describe '#initialize' do
    it 'accepts default index and items' do
      choice = described_class.new(0, 'a', 'b')
      expect(choice.instance_variable_get(:@default)).to eq(0)
      expect(choice.instance_variable_get(:@items).length).to eq(2)
    end

    it 'raises error when default is out of range' do
      expect {
        described_class.new(3, 'a', 'b')
      }.to raise_error(ArgumentError, /default index out of range/)
    end

    it 'wraps string items in Terminal' do
      choice = described_class.new(0, 'test')
      items = choice.instance_variable_get(:@items)
      expect(items.first).to be_a(RailroadDiagrams::Terminal)
    end

    it 'does not require space' do
      choice = described_class.new(0, 'a', 'b')
      expect(choice.needs_space).to be false
    end

    it 'calculates width including arcs' do
      choice = described_class.new(0, 'a', 'b')
      expect([choice.width, choice.up, choice.height, choice.down]).to eq([68.5, 11, 0, 41])
    end

    it 'calculates separators for items' do
      choice = described_class.new(0, 'a', 'b')
      separators = choice.instance_variable_get(:@separators)
      expect(separators).to be_a(Array)
      expect(separators.length).to eq(1)
    end

    it 'sets height to default item height' do
      terminal1 = RailroadDiagrams::Terminal.new('a')
      terminal2 = RailroadDiagrams::Terminal.new('b')
      choice = described_class.new(0, terminal1, terminal2)
      expect(choice.height).to eq(terminal1.height)
    end
  end

  describe '#format' do
    it 'returns self' do
      choice = described_class.new(1, 'first', 'second', 'third')
      result = choice.format(0, 50, choice.width)
      expect(result).to eq(choice)
    end

    it 'adds children' do
      choice = described_class.new(0, 'a', 'b')
      choice.format(0, 0, choice.width)
      expect(choice.children).not_to be_empty
    end

    it 'formats all items' do
      choice = described_class.new(1, 'a', 'b', 'c')
      choice.format(0, 0, choice.width)
      items = choice.instance_variable_get(:@items)
      items.each do |item|
        expect(choice.children).to include(item)
      end
    end

    it 'includes path elements for branching' do
      choice = described_class.new(0, 'a', 'b')
      choice.format(0, 0, choice.width)
      has_paths = choice.children.any? { |c| c.is_a?(RailroadDiagrams::Path) }
      expect(has_paths).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      choice = described_class.new(0, 'A', 'B')
      td = choice.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes all choice items' do
      choice = described_class.new(1, 'A', 'B', 'C')
      td = choice.text_diagram
      text = td.lines.join("\n")
      expect(text).to include('A')
      expect(text).to include('B')
      expect(text).to include('C')
    end

    it 'uses vertical lines for branches' do
      choice = described_class.new(0, 'A', 'B')
      td = choice.text_diagram
      expect(td.lines.join("\n")).to include('│')
    end

    it 'uses corner characters for branching' do
      choice = described_class.new(0, 'A', 'B')
      td = choice.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[╭╮╯╰]/)
    end
  end

  describe 'context rendering' do
    [0, 1, 2].each do |default|
      it "matches legacy SVG and text with default item #{default}" do
        context = RailroadDiagrams::Context.new
        choice = described_class.new(default, 'A', RailroadDiagrams::Skip.new, 'C')
        legacy = described_class.new(default, 'A', RailroadDiagrams::Skip.new, 'C')
        legacy.format(0, 100, legacy.width + 11)
        legacy_svg = +''
        legacy.write_svg(legacy_svg)

        svg = RailroadDiagrams::Svg::Serializer.call(choice.render_svg(context, 0, 100, context.metrics(choice).width + 11))
        expect(svg).to eq(legacy_svg)
        expect(choice.render_text(context).lines).to eq(choice.text_diagram.lines)
        expect(choice.children).to be_empty
      end
    end

    it 'measures and renders independently with a different arc radius' do
      choice = described_class.new(0, 'A', 'B')
      default = RailroadDiagrams::Context.new
      larger = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 12))

      expect([default.metrics(choice).width, larger.metrics(choice).width, choice.width]).to eq([68.5, 76.5, 68.5])
      larger_svg = RailroadDiagrams::Svg::Serializer.call(choice.render_svg(larger, 0, 100, larger.metrics(choice).width))
      default_svg = RailroadDiagrams::Svg::Serializer.call(choice.render_svg(default, 0, 100, default.metrics(choice).width))
      expect(larger_svg).to include('a12 12')
      expect(default_svg).to include('a10 10')
      expect(choice.children).to be_empty
    end

    it 'renders a shared child twice without moving it' do
      child = RailroadDiagrams::Terminal.new('A')
      choice = described_class.new(0, child, child)
      context = RailroadDiagrams::Context.new
      group = choice.render_svg(context, 0, 100, context.metrics(choice).width)
      child_groups = group.children.select { |element| element.name == 'g' }

      expect(choice.child_nodes).to eq([child, child])
      expect(child_groups.map { |item| item.children.find { |element| element.name == 'rect' }.attrs['y'] }).to eq([89, 119])
      expect(child.children).to be_empty
    end

    it 'uses the selected character set through nested branches' do
      context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))
      choice = described_class.new(0, RailroadDiagrams::Sequence.new('A', 'B'), 'C')
      expect(choice.render_text(context).lines.join).to match(/\A[\x00-\x7F]*\z/)
    end
  end

  describe '#to_s' do
    it 'returns debug string with default index' do
      choice = described_class.new(1, 'a', 'b')
      result = choice.to_s
      expect(result).to start_with('Choice(1,')
    end

    it 'includes all items' do
      choice = described_class.new(0, 'a', 'b', 'c')
      result = choice.to_s
      expect(result).to include('Terminal')
    end
  end
end
