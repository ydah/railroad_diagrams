# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::Group do
  it 'matches legacy SVG while leaving shared children untouched' do # rubocop:disable RSpec/ExampleLength
    node = described_class.new('a', label: 'g')
    context = RailroadDiagrams::Context.new
    metrics = context.metrics(node)
    expect([metrics.width, metrics.up, metrics.height, metrics.down, metrics.needs_space]).to eq([48.5, 35, 0, 19, true])
    svg = RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 100, metrics.width + 10))
    expect(node.children).to be_empty
    expect(node.child_nodes.flat_map(&:children)).to be_empty

    legacy = described_class.new('a', label: 'g')
    legacy.format(0, 100, legacy.width + 10)
    output = +''
    legacy.write_svg(output)
    expect(svg).to eq(output)
  end

  it 'uses per-render arc radius and vertical separation' do
    options = RailroadDiagrams.default_options.merge(arc_radius: 12, vertical_separation: 10)
    context = RailroadDiagrams::Context.new(options)
    node = described_class.new('a', label: 'g')
    expect([context.metrics(node).up, context.metrics(node).down]).to eq([37, 21])
    svg = RailroadDiagrams::Svg::Serializer.call(node.render_svg(context, 0, 100, context.metrics(node).width))
    expect(svg).to include('rx="12"', 'ry="12"', 'y="79"')
  end

  it 'keeps the label above the dashed border in text output' do
    node = described_class.new('a', label: 'g')
    expect(node.render_text(RailroadDiagrams::Context.new).lines).to eq(
      ['             ', '      g      ', ' ╭┄┄┄┄┄┄┄┄┄╮ ', ' ┆  ╭───╮  ┆ ',
       '─┼──│ a │──┼─', ' ┆  ╰───╯  ┆ ', ' ╰┄┄┄┄┄┄┄┄┄╯ ']
    )
  end
end
