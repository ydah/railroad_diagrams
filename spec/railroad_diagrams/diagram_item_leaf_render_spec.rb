# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::DiagramItem do
  %w[Terminal NonTerminal Comment].each do |name|
    it "renders #{name} through a Context without mutating the node" do
      node = RailroadDiagrams.const_get(name).new('<&')
      context = RailroadDiagrams::Context.new
      metrics = context.metrics(node)
      svg = RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 20, metrics.width + 10))
      expect(node.children).to be_empty

      legacy = RailroadDiagrams.const_get(name).new('<&')
      legacy.format(0, 20, legacy.width + 10)
      output = +''
      legacy.write_svg(output)
      expect(svg).to eq(output)
      expect(node.child_nodes).to eq([])
    end
  end

  it 'measures label and comment widths from separate Context options' do
    context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(char_width: 9, comment_char_width: 8))
    expect(context.metrics(RailroadDiagrams::Terminal.new('日本語')).width).to eq(74)
    expect(context.metrics(RailroadDiagrams::NonTerminal.new('日本語')).width).to eq(74)
    expect(context.metrics(RailroadDiagrams::Comment.new('日本語')).width).to eq(58)
  end

  it 'renders text with the selected character set' do
    ascii = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))
    expect(RailroadDiagrams::Terminal.new('A').render_text(ascii).lines).to eq([' /---\\ ', '-| A |-', ' \\---/ '])
    expect(RailroadDiagrams::NonTerminal.new('A').render_text(ascii).lines).to eq([' +---+ ', '-| A |-', ' +---+ '])
    expect(RailroadDiagrams::Comment.new('A').render_text(ascii).lines).to eq(['A'])
  end

  it 'renders labeled starts and ends without changing the original nodes' do # rubocop:disable RSpec/ExampleLength
    context = RailroadDiagrams::Context.new
    [RailroadDiagrams::Start.new('simple', label: 'S'), RailroadDiagrams::End.new].each do |node|
      original = node.attrs.dup
      svg = RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 10, 20, context.metrics(node).width))
      expect(node.attrs).to eq(original)
      expect(node.children).to be_empty

      node.format(10, 20, node.width)
      legacy = +''
      node.write_svg(legacy)
      expect(svg).to eq(legacy)
      expect(node.child_nodes).to eq([])
    end
  end

  it 'measures a Start label with context character width' do
    context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(char_width: 12))
    expect(context.metrics(RailroadDiagrams::Start.new(label: '日本')).width).to eq(58)
  end
end
