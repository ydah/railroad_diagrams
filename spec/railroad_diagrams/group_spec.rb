require 'spec_helper'

RSpec.describe RailroadDiagrams::Group do
  describe '#initialize' do
    it 'accepts item only' do
      group = described_class.new('item')
      expect(group.instance_variable_get(:@item)).to be_a(RailroadDiagrams::Terminal)
    end

    it 'accepts item and label' do
      group = described_class.new('item', 'label')
      expect(group.instance_variable_get(:@label)).not_to be_nil
    end

    it 'wraps string item in Terminal' do
      group = described_class.new('test')
      expect(group.instance_variable_get(:@item)).to be_a(RailroadDiagrams::Terminal)
    end

    it 'wraps string label in Comment' do
      group = described_class.new('item', 'label')
      expect(group.instance_variable_get(:@label)).to be_a(RailroadDiagrams::Comment)
    end

    it 'accepts DiagramItem as label' do
      comment = RailroadDiagrams::Comment.new('custom')
      group = described_class.new('item', comment)
      expect(group.instance_variable_get(:@label)).to eq(comment)
    end

    it 'requires space' do
      group = described_class.new('item')
      expect(group.needs_space).to be true
    end

    it 'calculates width including label' do
      group = described_class.new('short', 'very long label')
      expect(group.width).to be > 0
    end

    it 'sets height to item height' do
      terminal = RailroadDiagrams::Terminal.new('test')
      group = described_class.new(terminal)
      expect(group.height).to eq(terminal.height)
    end

    it 'calculates up including label when present' do
      group_without_label = described_class.new('test')
      group_with_label = described_class.new('test', 'label')
      expect(group_with_label.up).to be > group_without_label.up
    end

    it 'calculates box_up' do
      group = described_class.new('test')
      box_up = group.instance_variable_get(:@box_up)
      expect(box_up).to be >= RailroadDiagrams::AR
    end
  end

  describe '#format' do
    it 'returns self' do
      group = described_class.new('test')
      result = group.format(0, 0, group.width)
      expect(result).to eq(group)
    end

    it 'adds children' do
      group = described_class.new('test')
      group.format(0, 0, group.width)
      expect(group.children).not_to be_empty
    end

    it 'creates rect element with group-box class' do
      group = described_class.new('test')
      group.format(0, 0, group.width)
      rect = group.children.find do |c|
        c.is_a?(RailroadDiagrams::DiagramItem) &&
        c.instance_variable_get(:@name) == 'rect' &&
        c.attrs['class'] == 'group-box'
      end
      expect(rect).not_to be_nil
    end

    it 'formats item' do
      group = described_class.new('test')
      group.format(0, 0, group.width)
      item = group.instance_variable_get(:@item)
      expect(group.children).to include(item)
    end

    it 'formats label when present' do
      group = described_class.new('test', 'label')
      group.format(0, 0, group.width)
      label = group.instance_variable_get(:@label)
      expect(group.children).to include(label)
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram' do
      group = described_class.new('A')
      td = group.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'creates dashed rounded rectangle' do
      group = described_class.new('A')
      td = group.text_diagram
      text = td.lines.join("\n")
      expect(text).to match(/[╭╮╯╰]/)
      expect(text).to include('┄')
    end

    it 'includes the item' do
      group = described_class.new('TEST')
      td = group.text_diagram
      expect(td.lines.join("\n")).to include('TEST')
    end

    it 'includes the label when present' do
      group = described_class.new('item', 'LABEL')
      td = group.text_diagram
      expect(td.lines.join("\n")).to include('LABEL')
    end

    it 'positions label above item' do
      group = described_class.new('A', 'L')
      td = group.text_diagram
      lines_text = td.lines.join("\n")
      label_pos = lines_text.index('L')
      item_pos = lines_text.index('A')
      expect(label_pos).to be < item_pos
    end
  end

  describe '#to_s' do
    it 'returns debug string without label' do
      group = described_class.new('item')
      result = group.to_s
      expect(result).to start_with('Group(')
      expect(result).to include('label=')
    end

    it 'returns debug string with label' do
      group = described_class.new('item', 'label')
      result = group.to_s
      expect(result).to include('Comment')
    end
  end
end
