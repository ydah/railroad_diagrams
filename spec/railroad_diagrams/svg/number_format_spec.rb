# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::Svg::NumberFormat do
  it 'preserves legacy path and attribute precision independently' do
    value = 1.23456789
    expect(described_class.call(value, nil, kind: :path)).to eq(value.to_s)
    expect(described_class.call(value, nil, kind: :attr)).to eq('1.234568')
  end

  it 'rounds without exponent notation, trailing zeroes, or negative zero' do
    expect(described_class.call(1_234_567.899, 2)).to eq('1234567.9')
    expect(described_class.call(-0.004, 2)).to eq('0')
    expect(described_class.call(2.0, 2)).to eq('2')
  end
end
