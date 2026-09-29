require 'spec_helper'
require 'railroad_diagrams/text/parts'

RSpec.describe RailroadDiagrams::Text::Parts do
  it 'provides immutable parts matching the legacy Unicode and ASCII sets' do
    expect(described_class::UNICODE).to eq(RailroadDiagrams::TextDiagram::PARTS_UNICODE)
    expect(described_class::ASCII).to eq(RailroadDiagrams::TextDiagram::PARTS_ASCII)

    [described_class::UNICODE, described_class::UNICODE_SQUARE, described_class::ASCII].each do |parts|
      expect(parts).to be_frozen
      expect(parts.values).to all(be_frozen)
    end
  end

  it 'replaces all rounded Unicode corners with square corners' do
    square = described_class::UNICODE_SQUARE
    expect(square['roundrect_top_left']).to eq('┌')
    expect(square['repeat_bot_right']).to eq('┘')
    expect(square['line']).to eq('─')
    expect(square.keys).to eq(described_class::UNICODE.keys)
  end
end
