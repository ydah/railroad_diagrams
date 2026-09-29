# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::Svg::PathData do
  let(:legacy_format) { ->(value) { RailroadDiagrams::Svg::NumberFormat.call(value, nil, kind: :path) } }

  it 'matches the legacy path command spacing and arc coordinates' do
    old = RailroadDiagrams::Path.new(1.25, 2).h(3).v(-4).l(5, 6).m(-1, -2).arc('ne').arc_8('n', 'cw')
    fresh = described_class.new(1.25, 2).h(3).v(-4).l(5, 6).m(-1, -2).arc('ne').arc_8('n', 'cw')
    expect(fresh.to_s(legacy_format)).to eq(old.attrs['d'])
  end

  it 'removes zero movements and combines adjacent horizontal or vertical movements' do
    path = described_class.new(0, 0).h(0).h(3).h(-1).v(0).v(2).v(3).h(0)
    expect(path.optimize!.to_s(legacy_format)).to eq('M0 0h2v5')
  end

  it 'does not combine movements across an arc' do
    path = described_class.new(0, 0).h(2).arc('ne').h(3)
    expect(path.optimize!.to_s(legacy_format)).to eq('M0 0h2a10 10 0 0 1 10 10h3')
  end
end
