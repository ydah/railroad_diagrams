# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

RSpec.describe 'Lrama-facing API' do # rubocop:disable RSpec/DescribeClass
  let(:rule) do
    RailroadDiagrams::Sequence.new(
      RailroadDiagrams::Terminal.new('token'),
      RailroadDiagrams::NonTerminal.new('expr'),
      RailroadDiagrams::Skip.new
    )
  end

  it 'accepts the constructors and writer shape used by Lrama' do
    RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_UNICODE)
    diagram = RailroadDiagrams::Diagram.new(RailroadDiagrams::Choice.new(0, rule))
    output = +''
    diagram.write_svg(output.method(:<<))

    expect(REXML::Document.new(output).root.name).to eq('svg')
    expect(output).to include('token', 'expr')
    expect(RailroadDiagrams::Style.default_style).to include('svg.railroad-diagram')
    expect(RailroadDiagrams.escape_html('<rule>')).to eq('&lt;rule&gt;')
  end
end
