# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

RSpec.describe RailroadDiagrams::Svg::Serializer do
  it 'matches the existing element writer for sorted attributes and escaped text' do
    old = RailroadDiagrams::DiagramItem.new('g', attrs: { 'b' => '&<', 'a' => 1 }, text: '<&')
    output = +''
    old.write_svg(output.method(:<<))
    element = RailroadDiagrams::Svg::Element.new('g', { 'b' => '&<', 'a' => 1 })
    element << RailroadDiagrams::Svg::TextNode.new('<&')
    expect(described_class.call(element)).to eq(output)
  end

  it 'matches the legacy self-closing path format' do
    element = RailroadDiagrams::Svg::Element.new('path', { 'd' => 'M0 0h5' }, self_closing: true)
    expect(described_class.call(element)).to eq('<path d="M0 0h5" />')
  end

  it 'keeps legacy container newlines and the End path closing tag' do
    legacy = RailroadDiagrams::DiagramItem.new('svg')
    group = RailroadDiagrams::DiagramItem.new('g')
    group.add(legacy)
    RailroadDiagrams::End.new.format(10, 20, 20).add(group)
    expected = +''
    legacy.write_svg(expected.method(:<<))

    svg = RailroadDiagrams::Svg::Element.new('svg')
    child = RailroadDiagrams::Svg::Element.new('g')
    child << RailroadDiagrams::Svg::Element.new('path', { 'd' => 'M 10 20 h 20 m -10 -10 v 20 m 10 -20 v 20' })
    svg << child

    expect(described_class.call(svg)).to eq(expected)
  end

  it 'formats numeric attributes without exponent notation' do
    element = RailroadDiagrams::Svg::Element.new('rect', { 'width' => 1_234_567.5, 'x' => -0.0 })
    expect(described_class.call(element)).to eq('<rect width="1234567.5" x="0"></rect>')
  end

  it 'uses precision and path optimization only when requested' do
    path = RailroadDiagrams::Svg::PathData.new(1.234, 2).h(0).h(2.345).h(3)
    element = RailroadDiagrams::Svg::Element.new('path', { 'd' => path }, self_closing: true)
    expect(described_class.call(element)).to eq('<path d="M1.234 2h0h2.345h3" />')
    expect(described_class.call(element, precision: 2, optimize_paths: true)).to eq('<path d="M1.23 2h5.35" />')
    expect(described_class.call(element)).to eq('<path d="M1.234 2h0h2.345h3" />')
  end

  it 'keeps CSS with CDATA terminators safe in SVG and HTML' do
    element = RailroadDiagrams::Svg::Element.new('style')
    element << RailroadDiagrams::Svg::CData.new('a { content: "]]></style"; }')
    output = described_class.call(element)
    expect(output).to include(']]]]><![CDATA[>', '<\\/style')
    expect(REXML::Document.new(output).root.name).to eq('style')
  end
end
