# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::Options do
  after(:each) do
    RailroadDiagrams.instance_variable_set(:@default_options, nil)
  end

  it 'provides frozen drawing defaults' do
    options = RailroadDiagrams.default_options
    expect(options).to be_frozen
    expect(options.arc_radius).to eq(10)
    expect(options.vertical_separation).to eq(8)
    expect(options.text_charset).to eq(:unicode)
  end

  it 'returns a frozen copy when merging and rejects unknown names' do
    original = RailroadDiagrams.default_options
    changed = original.merge(arc_radius: 12)
    expect([original.arc_radius, changed.arc_radius]).to eq([10, 12])
    expect(changed).to be_frozen
    expect { original.merge(bogus: 1) }.to raise_error(RailroadDiagrams::InvalidArgument, /bogus/)
  end

  it 'replaces configured defaults after the block completes' do
    before = RailroadDiagrams.default_options
    RailroadDiagrams.configure do |values|
      expect(RailroadDiagrams.default_options).to equal(before)
      values[:arc_radius] = 14
    end
    expect(RailroadDiagrams.default_options.arc_radius).to eq(14)
    expect(before.arc_radius).to eq(10)
  end
end
