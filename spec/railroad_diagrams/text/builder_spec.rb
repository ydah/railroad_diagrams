require 'spec_helper'
require 'railroad_diagrams/text/builder'

RSpec.describe RailroadDiagrams::Text::Builder do
  let(:diagram) { RailroadDiagrams::TextDiagram }

  it 'stacks diagrams at display width and inserts separators between them' do
    top = diagram.new(0, 0, ['猫'])
    bottom = diagram.new(0, 0, ['x'])

    expect(described_class.stack([top, bottom], ['--'])).to eq(['猫', '--', 'x '])
    expect(top.lines).to eq(['猫'])
    expect(bottom.lines).to eq(['x'])
  end

  it 'returns no lines for an empty stack' do
    expect(described_class.stack([])).to eq([])
  end

  it 'aligns each row segment at its connection and pads other rows' do
    left = diagram.new(0, 1, ['A', 'a'])
    right = diagram.new(1, 0, ['b', 'B'])

    result = described_class.row([left, right], '-')

    expect(result.lines).to eq(['A b', 'a-B'])
    expect([result.entry, result.exit, result.width]).to eq([0, 0, 3])
  end

  it 'matches existing pairwise composition for varying heights and Unicode widths' do
    tds = [
      diagram.new(1, 0, ['猫', '犬']),
      diagram.new(0, 1, ['x', 'y']),
      diagram.new(1, 1, ['AB', 'CD'])
    ]
    expected = tds.drop(1).reduce(tds.first) { |joined, td| joined.append_right(td, '─') }

    actual = described_class.row(tds, '─')

    expect([actual.entry, actual.exit, actual.lines]).to eq([expected.entry, expected.exit, expected.lines])
  end

  it 'returns an empty diagram for an empty row' do
    result = described_class.row([], '-')
    expect([result.entry, result.exit, result.lines]).to eq([0, 0, []])
  end

  it 'omits a separator at a connection below both adjacent diagrams' do
    first = diagram.new(1, 1, ['A'])
    second = diagram.new(1, 1, ['B'])
    third = diagram.new(0, 0, ['C'])

    expect(described_class.row([first, second, third], '-').lines).to eq(['A B  ', '   -C'])
  end

  it 'collapses leading empty diagrams as pairwise composition does' do
    empty = diagram.new(0, 0, [])
    visible = diagram.new(0, 0, ['C'])

    expect(described_class.row([empty, empty, visible], '-').lines).to eq(['-C'])
  end
end
