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

  describe '#to_s' do
    it 'returns debug string' do
      stack = described_class.new('a', 'b')
      result = stack.to_s
      expect(result).to start_with('Stack(')
      expect(result).to include('Terminal')
    end
  end
end
