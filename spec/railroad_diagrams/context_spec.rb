# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::Context do
  it 'caches existing node dimensions by object identity' do
    context = described_class.new
    node = RailroadDiagrams::Terminal.new('ab')
    metrics = context.metrics(node)
    expect([metrics.width, metrics.up, metrics.height, metrics.down, metrics.needs_space])
      .to eq([37.0, 11, 0, 11, true])
    expect(context.metrics(node)).to equal(metrics)
  end

  it 'uses a node measure method when available' do
    node = Object.new
    def node.measure(_context)
      RailroadDiagrams::Metrics.new(width: 5, up: 1, height: 2, down: 3, needs_space: false)
    end
    expect(described_class.new.metrics(node).width).to eq(5)
  end

  it 'takes a snapshot of the selected text parts' do
    context = described_class.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))
    expect(context.parts['line']).to eq('-')
    RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_UNICODE)
    expect(described_class.legacy.parts['line']).to eq('─')
  end

  it 'accepts square Unicode corners' do
    context = described_class.new(RailroadDiagrams.default_options.merge(text_charset: :unicode_square))
    expect(context.parts['roundrect_top_left']).to eq('┌')
  end

  it 'places surplus width according to the selected alignment' do
    options = RailroadDiagrams.default_options
    expect(described_class.new(options).gaps(11, 8)).to eq([1.5, 1.5])
    expect(described_class.new(options.merge(internal_alignment: :left)).gaps(11, 8)).to eq([0, 3])
    expect(described_class.new(options.merge(internal_alignment: :right)).gaps(11, 8)).to eq([3, 0])
  end
end
