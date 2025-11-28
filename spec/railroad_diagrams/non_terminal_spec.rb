require 'spec_helper'

RSpec.describe RailroadDiagrams::NonTerminal do
  describe '#initialize' do
    it 'calculates width based on text length' do
      non_terminal = described_class.new('hello')
      expected_width = (5 * RailroadDiagrams::CHAR_WIDTH) + 20
      expect(non_terminal.width).to eq(expected_width)
    end

    it 'sets up and down to 11' do
      non_terminal = described_class.new('test')
      expect(non_terminal.up).to eq(11)
      expect(non_terminal.down).to eq(11)
    end

    it 'requires space' do
      non_terminal = described_class.new('test')
      expect(non_terminal.needs_space).to be true
    end

    it 'sets default class' do
      non_terminal = described_class.new('test')
      expect(non_terminal.attrs['class']).to eq('non-terminal ')
    end

    it 'accepts custom class' do
      non_terminal = described_class.new('test', nil, nil, cls: 'blue')
      expect(non_terminal.attrs['class']).to eq('non-terminal blue')
    end

    it 'accepts href' do
      non_terminal = described_class.new('test', 'http://example.com')
      expect(non_terminal.instance_variable_get(:@href)).to eq('http://example.com')
    end

    it 'accepts title' do
      non_terminal = described_class.new('test', nil, 'Title Text')
      expect(non_terminal.instance_variable_get(:@title)).to eq('Title Text')
    end
  end

  describe '#format' do
    let(:non_terminal) { described_class.new('test') }

    it 'returns self' do
      result = non_terminal.format(0, 0, non_terminal.width)
      expect(result).to eq(non_terminal)
    end

    it 'adds children to self' do
      non_terminal.format(0, 0, non_terminal.width)
      expect(non_terminal.children).not_to be_empty
    end

    it 'creates rect element without rounded corners' do
      non_terminal.format(10, 20, non_terminal.width)
      rect = non_terminal.children.find { |c| c.is_a?(RailroadDiagrams::DiagramItem) && c.instance_variable_get(:@name) == 'rect' }
      expect(rect).not_to be_nil
      expect(rect.attrs['rx']).to be_nil
      expect(rect.attrs['ry']).to be_nil
    end

    it 'creates text element' do
      non_terminal.format(10, 20, non_terminal.width)
      has_text = non_terminal.children.any? do |child|
        if child.is_a?(RailroadDiagrams::DiagramItem)
          child.instance_variable_get(:@name) == 'text' ||
          child.children.any? { |c| c.is_a?(RailroadDiagrams::DiagramItem) && c.instance_variable_get(:@name) == 'text' }
        end
      end
      expect(has_text).to be true
    end

    it 'creates link when href is provided' do
      non_terminal_with_link = described_class.new('test', 'http://example.com')
      non_terminal_with_link.format(0, 0, non_terminal_with_link.width)
      has_link = non_terminal_with_link.children.any? do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) && child.instance_variable_get(:@name) == 'a'
      end
      expect(has_link).to be true
    end

    it 'creates title element when title is provided' do
      non_terminal_with_title = described_class.new('test', nil, 'Title')
      non_terminal_with_title.format(0, 0, non_terminal_with_title.width)
      has_title = non_terminal_with_title.children.any? do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) && child.instance_variable_get(:@name) == 'title'
      end
      expect(has_title).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      non_terminal = described_class.new('X')
      td = non_terminal.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'creates a rectangle' do
      non_terminal = described_class.new('X')
      td = non_terminal.text_diagram
      expect(td.lines.first).to include('┌')
      expect(td.lines.last).to include('└')
    end

    it 'contains the text' do
      non_terminal = described_class.new('ABC')
      td = non_terminal.text_diagram
      expect(td.lines.join("\n")).to include('ABC')
    end
  end

  describe '#to_s' do
    it 'returns debug string without optional parameters' do
      non_terminal = described_class.new('foo')
      expect(non_terminal.to_s).to eq('NonTerminal(foo, href=, title=, cls=)')
    end

    it 'returns debug string with all parameters' do
      non_terminal = described_class.new('foo', 'http://example.com', 'Title', cls: 'blue')
      expect(non_terminal.to_s).to eq('NonTerminal(foo, href=http://example.com, title=Title, cls=blue)')
    end
  end
end
