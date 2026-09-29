# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe 'Output API' do
  let(:diagram) { RailroadDiagrams::Diagram.new('a') }

  it 'returns the same SVG as the legacy writer' do
    expected = +''
    diagram.write_svg(expected.method(:<<))
    expect(diagram.to_svg).to eq(expected)
  end

  it 'writes to an IO and returns standalone SVG' do
    io = StringIO.new
    diagram.write_standalone(io)
    expect(diagram.to_standalone_svg).to eq(io.string)
    expect(io.string).to include('<style>')
  end

  it 'returns plain text by default and restores the selected character set' do
    RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_ASCII)
    expect(diagram.to_text).to include('─')
    expect(diagram.to_text(charset: :ascii)).to include('-')
    expect(RailroadDiagrams::TextDiagram.parts).to eq(RailroadDiagrams::TextDiagram::PARTS_ASCII)
  end

  it 'keeps legacy text escaping and permits plain text output' do
    diagram = RailroadDiagrams::Diagram.new('<a&b>')
    escaped = +''
    diagram.write_text(escaped)
    expect(escaped).to include('&lt;a&amp;b&gt;')
    expect(diagram.to_text).to include('<a&b>')
    plain = +''
    diagram.write_text(plain, escape_html: false)
    expect(plain).to include('<a&b>')
  end

  it 'rejects invalid writers through the shared error marker' do
    expect { diagram.write_svg(Object.new) }.to raise_error(RailroadDiagrams::Error)
    expect { diagram.to_text(charset: :unknown) }.to raise_error(RailroadDiagrams::InvalidArgument)
  end
end
