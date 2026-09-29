# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Unicode display width' do
  it 'measures Latin, East Asian, combining and emoji clusters' do
    cases = { 'abc' => 3, '日本語' => 6, 'ｱｲｳ' => 3, 'Ａ' => 2,
              "e\u0301" => 1, '🚀' => 2, '👨‍👩‍👧' => 2, '🇯🇵' => 2, "\u200B" => 0 }
    cases.each { |string, width| expect(RailroadDiagrams::Unicode::DisplayWidth.of(string)).to eq(width) }
    expect(RailroadDiagrams::Unicode::DisplayWidth.of('○')).to eq(1)
    expect(RailroadDiagrams::Unicode::DisplayWidth.of('○', ambiguous: 2)).to eq(2)
  end

  it 'sizes SVG labels and keeps text diagrams rectangular' do
    terminal = RailroadDiagrams::Terminal.new('日本語')
    expect(terminal.width).to eq(6 * RailroadDiagrams::CHAR_WIDTH + 20)
    td = RailroadDiagrams::Diagram.new('日本語', 'abc').text_diagram
    expect(td.lines.map { |line| RailroadDiagrams::Unicode::DisplayWidth.of(line) }.uniq).to eq([td.width])
  end
end
