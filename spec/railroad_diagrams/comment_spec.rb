require 'spec_helper'

RSpec.describe RailroadDiagrams::Comment do
  describe '#initialize' do
    it 'calculates width based on text length with COMMENT_CHAR_WIDTH' do
      comment = described_class.new('hello')
      expected_width = (5 * RailroadDiagrams::COMMENT_CHAR_WIDTH) + 10
      expect(comment.width).to eq(expected_width)
    end

    it 'sets up and down to 8' do
      comment = described_class.new('test')
      expect(comment.up).to eq(8)
      expect(comment.down).to eq(8)
    end

    it 'requires space' do
      comment = described_class.new('test')
      expect(comment.needs_space).to be true
    end

    it 'sets default class' do
      comment = described_class.new('test')
      expect(comment.attrs['class']).to eq('non-terminal ')
    end

    it 'accepts custom class' do
      comment = described_class.new('test', nil, nil, cls: 'blue')
      expect(comment.attrs['class']).to eq('non-terminal blue')
    end

    it 'accepts href' do
      comment = described_class.new('test', 'http://example.com')
      expect(comment.instance_variable_get(:@href)).to eq('http://example.com')
    end

    it 'accepts title' do
      comment = described_class.new('test', nil, 'Title Text')
      expect(comment.instance_variable_get(:@title)).to eq('Title Text')
    end
  end

  describe '#format' do
    let(:comment) { described_class.new('test') }

    it 'returns self' do
      result = comment.format(0, 0, comment.width)
      expect(result).to eq(comment)
    end

    it 'adds children to self' do
      comment.format(0, 0, comment.width)
      expect(comment.children).not_to be_empty
    end

    it 'creates text element with comment class' do
      comment.format(10, 20, comment.width)
      text = comment.children.find do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) &&
        child.instance_variable_get(:@name) == 'text' &&
        child.attrs['class'] == 'comment'
      end
      expect(text).not_to be_nil
    end

    it 'creates link when href is provided' do
      comment_with_link = described_class.new('test', 'http://example.com')
      comment_with_link.format(0, 0, comment_with_link.width)
      has_link = comment_with_link.children.any? do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) && child.instance_variable_get(:@name) == 'a'
      end
      expect(has_link).to be true
    end

    it 'creates title element when title is provided' do
      comment_with_title = described_class.new('test', nil, 'Title')
      comment_with_title.format(0, 0, comment_with_title.width)
      has_title = comment_with_title.children.any? do |child|
        child.is_a?(RailroadDiagrams::DiagramItem) && child.instance_variable_get(:@name) == 'title'
      end
      expect(has_title).to be true
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      comment = described_class.new('X')
      td = comment.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'contains the text without box' do
      comment = described_class.new('ABC')
      td = comment.text_diagram
      expect(td.lines.join("\n")).to eq('ABC')
    end

    it 'has single line' do
      comment = described_class.new('test')
      td = comment.text_diagram
      expect(td.lines.length).to eq(1)
    end

    it 'has entry and exit at 0' do
      comment = described_class.new('test')
      td = comment.text_diagram
      expect(td.entry).to eq(0)
      expect(td.exit).to eq(0)
    end
  end

  describe '#to_s' do
    it 'returns debug string without optional parameters' do
      comment = described_class.new('foo')
      expect(comment.to_s).to eq('Comment(foo, href=, title=, cls=)')
    end

    it 'returns debug string with all parameters' do
      comment = described_class.new('foo', 'http://example.com', 'Title', cls: 'blue')
      expect(comment.to_s).to eq('Comment(foo, href=http://example.com, title=Title, cls=blue)')
    end
  end
end
