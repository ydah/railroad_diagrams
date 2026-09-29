# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::OneOrMore do
  it 'measures and renders independently of the legacy child arrays' do # rubocop:disable RSpec/ExampleLength
    node = described_class.new('a', ',')
    context = RailroadDiagrams::Context.new
    metrics = context.metrics(node)
    expect([metrics.width, metrics.up, metrics.height, metrics.down, metrics.needs_space]).to eq([48.5, 11, 0, 41, true])
    svg = RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 100, metrics.width + 10))
    expect(node.children).to be_empty
    expect(node.child_nodes.flat_map(&:children)).to be_empty

    legacy = described_class.new('a', ',')
    legacy.format(0, 100, legacy.width + 10)
    output = +''
    legacy.write_svg(output)
    expect(svg).to eq(output)
  end

  it 'uses the arc radius for measurement and new paths' do
    context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(arc_radius: 12))
    node = described_class.new('a', ',')
    expect(context.metrics(node).width).to eq(52.5)
    svg = RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 100, context.metrics(node).width))
    expect(svg).to include('a12 12')
  end

  it 'renders the repeat track with Context text parts' do
    node = described_class.new('a', ',')
    context = RailroadDiagrams::Context.new
    expect(node.render_text(context).lines).to eq(
      ['   ╭───╮   ', '╭──│ a │──╮', '│  ╰───╯  │',
       '│  ╭───╮  │', '╰──│ , │──╯', '   ╰───╯   ']
    )
  end
end
