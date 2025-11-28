require 'spec_helper'

RSpec.describe RailroadDiagrams::Terminal do
  describe '#initialize' do
    it 'calculates width based on text length' do
      terminal = described_class.new('hello')
      expected_width = (5 * RailroadDiagrams::CHAR_WIDTH) + 20
      expect(terminal.width).to eq(expected_width)
    end

    it 'sets up and down to 11' do
      terminal = described_class.new('test')
      expect(terminal.up).to eq(11)
      expect(terminal.down).to eq(11)
    end

    it 'requires space' do
      terminal = described_class.new('test')
      expect(terminal.needs_space).to be true
    end

    it 'sets default class' do
      terminal = described_class.new('test')
      expect(terminal.attrs['class']).to eq('terminal ')
    end

    it 'accepts custom class' do
      terminal = described_class.new('test', nil, nil, cls: 'blue')
      expect(terminal.attrs['class']).to eq('terminal blue')
    end

    it 'accepts href' do
      terminal = described_class.new('test', 'http://example.com')
      expect(terminal.instance_variable_get(:@href)).to eq('http://example.com')
    end

    it 'accepts title' do
      terminal = described_class.new('test', nil, 'Title Text')
      expect(terminal.instance_variable_get(:@title)).to eq('Title Text')
    end
  end

  describe '#format' do
    let(:terminal) { described_class.new('test') }

    it 'returns self' do
      result = terminal.format(0, 0, terminal.width)
      expect(result).to eq(terminal)
    end

    it 'adds children to self' do
      terminal.format(0, 0, terminal.width)
      expect(terminal.children).not_to be_empty
    end

    it 'creates rect element' do
      terminal.format(10, 20, terminal.width)
      rect = terminal.children.find { |c| c.is_a?(RailroadDiagrams::DiagramItem) && c.instance_variable_get(:@name) == 'rect' }
      expect(rect).not_to be_nil
      expect(rect.attrs['rx']).to eq(10)
      expect(rect.attrs['ry']).to eq(10)
    end

    it 'creates text element' do
      terminal.format(10, 20, terminal.width)
      has_text = terminal.children.any? do |child|
        if child.is_a?(RailroadDiagrams::DiagramItem)
          child.instance_variable_get(:@name) == 'text' ||
          child.children.any? { |c| c.is_a?(RailroadDiagrams::DiagramItem) && c.instance_variable_get(:@name) == 'text' }
        end
      end
      expect(has_text).to be true
    end

    it 'creates link when href is provided' do
      terminal_with_link = described_class.new('test', 'http://example.com')
      terminal_with_link.format(0, 0, terminal_with_link.width)
      has_link = terminal_with_link.children.any? do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) && child.instance_variable_get(:@name) == 'a'
      end
      expect(has_link).to be true
    end

    it 'creates title element when title is provided' do
      terminal_with_title = described_class.new('test', nil, 'Title')
      terminal_with_title.format(0, 0, terminal_with_title.width)
      has_title = terminal_with_title.children.any? do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) && child.instance_variable_get(:@name) == 'title'
      end
      expect(has_title).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      terminal = described_class.new('X')
      td = terminal.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'creates a rounded rectangle' do
      terminal = described_class.new('X')
      td = terminal.text_diagram
      expect(td.lines.first).to include('╭')
      expect(td.lines.last).to include('╯')
    end

    it 'contains the text' do
      terminal = described_class.new('ABC')
      td = terminal.text_diagram
      expect(td.lines.join("\n")).to include('ABC')
    end
  end

  describe '#to_s' do
    it 'returns debug string without optional parameters' do
      terminal = described_class.new('foo')
      expect(terminal.to_s).to eq('Terminal(foo, href=, title=, cls=)')
    end

    it 'returns debug string with all parameters' do
      terminal = described_class.new('foo', 'http://example.com', 'Title', cls: 'blue')
      expect(terminal.to_s).to eq('Terminal(foo, href=http://example.com, title=Title, cls=blue)')
    end
  end
end
