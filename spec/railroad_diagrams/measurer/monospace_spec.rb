# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::Measurer::Monospace do
  it 'uses display columns and the width for each label role' do
    measurer = described_class.new(RailroadDiagrams.default_options)
    expect(measurer.width('日本語', :label)).to eq(51.0)
    expect(measurer.width('日本語', :comment)).to eq(42)
    expect(measurer.width('🚀', :label)).to eq(17.0)
    expect { measurer.width('x', :other) }.to raise_error(RailroadDiagrams::InvalidArgument)
  end

  it 'is selected by default and can be replaced per context' do
    custom = ->(text, role) { [text, role] }
    options = RailroadDiagrams.default_options.merge(measurer: custom)
    expect(RailroadDiagrams::Context.new.text_width('ab', :label)).to eq(17.0)
    expect(RailroadDiagrams::Context.new(options).text_width('ab', :label)).to eq(['ab', :label])
  end
end
