require 'spec_helper'

RSpec.describe RailroadDiagrams::TextDiagram do
  describe 'Constants' do
    it 'has PARTS_UNICODE constant' do
      expect(described_class::PARTS_UNICODE).to be_a(Hash)
      expect(described_class::PARTS_UNICODE['line']).to eq('─')
    end

    it 'has PARTS_ASCII constant' do
      expect(described_class::PARTS_ASCII).to be_a(Hash)
      expect(described_class::PARTS_ASCII['line']).to eq('-')
    end
  end

  describe '.set_formatting' do
    it 'sets parts from characters' do
      described_class.set_formatting({ 'custom' => 'X' })
      expect(described_class.parts['custom']).to eq('X')
    end

    it 'merges with defaults when provided' do
      described_class.set_formatting({ 'line' => 'X' }, { 'cross' => '+' })
      expect(described_class.parts['line']).to eq('X')
      expect(described_class.parts['cross']).to eq('+')
    end

    it 'raises error for multi-character parts' do
      expect {
        described_class.set_formatting({ 'bad' => 'XX' })
      }.to raise_error(ArgumentError, /more than 1 character/)
    end

    it 'does nothing when characters is nil' do
      original_parts = described_class.parts.dup
      described_class.set_formatting(nil)
      expect(described_class.parts).to eq(original_parts)
    end
  end

  describe '.rect' do
    it 'creates a rectangle around text' do
      td = described_class.rect('ABC')
      expect(td.lines.first).to include('┌')
      expect(td.lines.last).to include('└')
      expect(td.lines.join("\n")).to include('ABC')
    end

    it 'creates dashed rectangle' do
      td = described_class.rect('X', dashed: true)
      expect(td.lines.join("\n")).to include('┄')
    end

    it 'accepts TextDiagram as input' do
      inner = described_class.new(0, 0, ['A'])
      td = described_class.rect(inner)
      expect(td).to be_a(described_class)
    end
  end

  describe '.round_rect' do
    it 'creates a rounded rectangle' do
      td = described_class.round_rect('X')
      expect(td.lines.first).to include('╭')
      expect(td.lines.last).to include('╯')
    end

    it 'creates dashed rounded rectangle' do
      td = described_class.round_rect('X', dashed: true)
      expect(td.lines.join("\n")).to include('┄')
    end

    it 'accepts TextDiagram as input' do
      inner = described_class.new(0, 0, ['A'])
      td = described_class.round_rect(inner)
      expect(td).to be_a(described_class)
    end
  end

  describe '.max_width' do
    it 'returns max width from strings' do
      expect(described_class.max_width('a', 'abc', 'ab')).to eq(3)
    end

    it 'returns max width from TextDiagrams' do
      td1 = described_class.new(0, 0, ['12'])
      td2 = described_class.new(0, 0, ['12345'])
      expect(described_class.max_width(td1, td2)).to eq(5)
    end

    it 'returns max width from arrays' do
      expect(described_class.max_width(['a', 'abc'], ['ab'])).to eq(3)
    end

    it 'returns max width from numbers' do
      expect(described_class.max_width(42, 999)).to eq(3)
    end

    it 'handles mixed types' do
      td = described_class.new(0, 0, ['1234'])
      expect(described_class.max_width('ab', td, 999)).to eq(4)
    end

    it 'returns 0 for empty arguments' do
      expect(described_class.max_width).to eq(0)
    end
  end

  describe '.pad_l' do
    it 'pads left with character' do
      expect(described_class.pad_l('X', 5, '-')).to eq('----X')
    end

    it 'handles multi-character pad' do
      expect(described_class.pad_l('X', 5, '--')).to eq('----X')
    end

    it 'raises error when gap is not multiple of pad length' do
      expect {
        described_class.pad_l('XX', 5, '--')
      }.to raise_error(RuntimeError, /must be a multiple/)
    end

    it 'returns string unchanged when width matches' do
      expect(described_class.pad_l('XXX', 3, '-')).to eq('XXX')
    end
  end

  describe '.pad_r' do
    it 'pads right with character' do
      expect(described_class.pad_r('X', 5, '-')).to eq('X----')
    end

    it 'handles multi-character pad' do
      expect(described_class.pad_r('X', 5, '--')).to eq('X----')
    end

    it 'raises error when gap is not multiple of pad length' do
      expect {
        described_class.pad_r('XX', 5, '--')
      }.to raise_error(RuntimeError, /must be a multiple/)
    end

    it 'returns string unchanged when width matches' do
      expect(described_class.pad_r('XXX', 3, '-')).to eq('XXX')
    end
  end

  describe '.get_parts' do
    it 'returns requested parts' do
      parts = described_class.get_parts(['line', 'cross'])
      expect(parts).to eq(['─', '┼'])
    end

    it 'returns nil for unknown parts' do
      parts = described_class.get_parts(['unknown'])
      expect(parts).to eq([nil])
    end
  end

  describe '.enclose_lines' do
    it 'encloses lines between left and right strings' do
      lines = ['A', 'B']
      lefts = ['<', '<']
      rights = ['>', '>']
      result = described_class.enclose_lines(lines, lefts, rights)
      expect(result).to eq(['<A>', '<B>'])
    end

    it 'raises error when lengths do not match' do
      expect {
        described_class.enclose_lines(['A'], ['<', '<'], ['>'])
      }.to raise_error(RuntimeError, /same length/)
    end
  end

  describe '.gaps' do
    it 'returns centered gaps when alignment is center' do
      left, right = described_class.gaps(10, 4)
      expect(left).to eq(3)
      expect(right).to eq(3)
    end

    it 'handles odd difference' do
      left, right = described_class.gaps(10, 5)
      expect(left).to eq(2)
      expect(right).to eq(3)
    end
  end

  describe '#initialize' do
    it 'sets entry, exit, and lines' do
      td = described_class.new(1, 2, ['line1', 'line2', 'line3'])
      expect(td.entry).to eq(1)
      expect(td.exit).to eq(2)
      expect(td.lines).to eq(['line1', 'line2', 'line3'])
    end

    it 'calculates height and width' do
      td = described_class.new(0, 0, ['12', '34'])
      expect(td.height).to eq(2)
      expect(td.width).to eq(2)
    end

    it 'handles empty lines' do
      td = described_class.new(0, 0, [])
      expect(td.height).to eq(0)
      expect(td.width).to eq(0)
    end

    it 'duplicates lines array' do
      original_lines = ['A']
      td = described_class.new(0, 0, original_lines)
      td.lines[0] = 'B'
      expect(original_lines[0]).to eq('A')
    end

    it 'raises error when entry is out of bounds' do
      expect {
        described_class.new(5, 0, ['A'])
      }.to raise_error(RuntimeError, /Entry is not within diagram/)
    end

    it 'raises error when exit is out of bounds' do
      expect {
        described_class.new(0, 5, ['A'])
      }.to raise_error(RuntimeError, /Exit is not within diagram/)
    end

    it 'raises error when lines are not rectangular' do
      expect {
        described_class.new(0, 0, ['A', 'AB'])
      }.to raise_error(RuntimeError, /not rectangular/)
    end
  end

  describe '#alter' do
    it 'creates new instance with different entry' do
      td = described_class.new(0, 0, ['A'])
      altered = td.alter(new_entry: 1)
      expect(altered.entry).to eq(1)
      expect(td.entry).to eq(0)
    end

    it 'creates new instance with different exit' do
      td = described_class.new(0, 0, ['A'])
      altered = td.alter(new_exit: 1)
      expect(altered.exit).to eq(1)
      expect(td.exit).to eq(0)
    end

    it 'creates new instance with different lines' do
      td = described_class.new(0, 0, ['A'])
      altered = td.alter(new_lines: ['B'])
      expect(altered.lines).to eq(['B'])
      expect(td.lines).to eq(['A'])
    end
  end

  describe '#append_below' do
    it 'joins two diagrams vertically' do
      top = described_class.new(0, 0, ['A'])
      bottom = described_class.new(0, 0, ['B'])
      joined = top.append_below(bottom, [])

      expect(joined.lines).to eq(['A', 'B'])
      expect(joined.entry).to eq(0)
      expect(joined.exit).to eq(0)
    end

    it 'adds lines between diagrams' do
      top = described_class.new(0, 0, ['A'])
      bottom = described_class.new(0, 0, ['B'])
      joined = top.append_below(bottom, ['-'])

      expect(joined.lines).to eq(['A', '-', 'B'])
    end

    it 'moves entry when requested' do
      top = described_class.new(0, 0, ['A'])
      bottom = described_class.new(1, 1, ['B', 'C'])
      joined = top.append_below(bottom, [], move_entry: true)

      expect(joined.entry).to eq(2)
    end

    it 'moves exit when requested' do
      top = described_class.new(0, 0, ['A'])
      bottom = described_class.new(1, 1, ['B', 'C'])
      joined = top.append_below(bottom, [], move_exit: true)

      expect(joined.exit).to eq(2)
    end

    it 'centers narrower diagram' do
      top = described_class.new(0, 0, ['A'])
      bottom = described_class.new(0, 0, ['BBBB'])
      joined = top.append_below(bottom, [])

      expect(joined.lines[0].length).to eq(4)
    end
  end

  describe '#append_right' do
    it 'joins two diagrams horizontally' do
      left = described_class.new(0, 0, ['A'])
      right = described_class.new(0, 0, ['B'])
      joined = left.append_right(right, '-')

      expect(joined.lines.first).to eq('A-B')
    end

    it 'handles different heights' do
      left = described_class.new(0, 0, ['A'])
      right = described_class.new(1, 1, ['B', 'C'])
      joined = left.append_right(right, '-')

      expect(joined.height).to be >= 2
    end

    it 'aligns on join line' do
      left = described_class.new(1, 1, ['A', 'B'])
      right = described_class.new(0, 0, ['C'])
      joined = left.append_right(right, '-')

      expect(joined.lines.join("\n")).to include('-')
    end
  end

  describe '#center' do
    it 'centers diagram in wider space' do
      td = described_class.new(0, 0, ['A'])
      centered = td.center(5)

      expect(centered.width).to eq(5)
      expect(centered.lines.first).to match(/\sA\s/)
    end

    it 'uses custom padding character' do
      td = described_class.new(0, 0, ['A'])
      centered = td.center(5, '-')

      expect(centered.lines.first).to include('-')
    end

    it 'raises error when centering into smaller width' do
      td = described_class.new(0, 0, ['ABC'])
      expect {
        td.center(2)
      }.to raise_error(StandardError)
    end

    it 'returns copy when width matches' do
      td = described_class.new(0, 0, ['A'])
      centered = td.center(1)

      expect(centered.width).to eq(1)
      expect(centered.lines).to eq(['A'])
    end
  end

  describe '#copy' do
    it 'creates independent copy' do
      original = described_class.new(0, 0, ['A'])
      copy = original.copy

      expect(copy.entry).to eq(original.entry)
      expect(copy.exit).to eq(original.exit)
      expect(copy.lines).to eq(original.lines)
      expect(copy).not_to eq(original)
    end
  end

  describe '#expand' do
    it 'adds padding on all sides' do
      td = described_class.new(0, 0, ['X'])
      expanded = td.expand(2, 2, 1, 1)

      expect(expanded.width).to eq(5)
      expect(expanded.height).to eq(3)
    end

    it 'adds line character on entry row' do
      td = described_class.new(0, 0, ['X'])
      expanded = td.expand(2, 0, 0, 0)

      expect(expanded.lines.first).to start_with('─')
    end

    it 'adds line character on exit row' do
      td = described_class.new(0, 0, ['X'])
      expanded = td.expand(0, 2, 0, 0)

      expect(expanded.lines.first).to end_with('─')
    end

    it 'returns copy when all padding is zero' do
      td = described_class.new(0, 0, ['X'])
      expanded = td.expand(0, 0, 0, 0)

      expect(expanded.width).to eq(1)
      expect(expanded.lines).to eq(['X'])
    end

    it 'updates entry and exit positions' do
      td = described_class.new(0, 0, ['X'])
      expanded = td.expand(0, 0, 2, 1)

      expect(expanded.entry).to eq(2)
      expect(expanded.exit).to eq(2)
    end
  end

  describe '#dump' do
    it 'returns debug string without showing' do
      td = described_class.new(1, 1, ['A', 'B'])
      result = td.dump(false)

      expect(result).to include('height=2')
      expect(result).to include('entry')
      expect(result).to include('exit')
    end
  end
end
