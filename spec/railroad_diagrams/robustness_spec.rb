# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Constructor robustness' do
  it 'accepts a Style item alongside nodes' do
    diagram = RailroadDiagrams::Diagram.new('a', RailroadDiagrams::Style.new('.x{}'))
    expect(diagram.instance_variable_get(:@items)).to include(a_kind_of(RailroadDiagrams::Style))
    expect(diagram.to_svg).to include('.x{}')
    expect(diagram.to_text).to include('a')
  end

  it 'handles an empty diagram but rejects an empty stack' do
    expect(RailroadDiagrams::Diagram.new.to_text).to eq("\n")
    expect { RailroadDiagrams::Stack.new }.to raise_error(RailroadDiagrams::InvalidArgument)
  end

  it 'converts label values to strings' do
    expect(RailroadDiagrams::Terminal.new(42).width).to eq(2 * RailroadDiagrams::CHAR_WIDTH + 20)
    expect(RailroadDiagrams::Diagram.new(RailroadDiagrams::NonTerminal.new(:expr)).to_text).to include('expr')
    expect(RailroadDiagrams::Comment.new(12).text_diagram.lines).to eq(['12'])
    expect(RailroadDiagrams::Start.new(label: 42).text_diagram.lines.join).to include('42')
  end

  it 'rejects unknown options and diagram types' do
    expect { RailroadDiagrams::Diagram.new('a', width: 20) }.to raise_error(RailroadDiagrams::InvalidArgument)
    expect { RailroadDiagrams::Diagram.new('a', type: 'other') }.to raise_error(RailroadDiagrams::InvalidArgument)
  end
end
