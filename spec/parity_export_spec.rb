# frozen_string_literal: true

require 'spec_helper'
require_relative '../script/parity/export'

RSpec.describe ParityExport do
  it 'exports optional factories as their unchanged Choice layout' do
    optional = described_class.node(RailroadDiagrams::Optional.new('a'))
    repeated = described_class.node(RailroadDiagrams::ZeroOrMore.new('a'))
    expect(optional['class']).to eq('Choice')
    expect(repeated['class']).to eq('Choice')
    expect(repeated['args'][2]['class']).to eq('OneOrMore')
  end

  it 'keeps new-node examples out of the upstream comparison' do
    expect(described_class.examples.keys.grep(/\Anode-/)).to be_empty
    expect(described_class.examples).to have_key('simple')
  end
end
