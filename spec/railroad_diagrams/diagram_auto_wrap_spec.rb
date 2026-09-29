# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'
require 'stringio'

RSpec.describe RailroadDiagrams::Diagram do
  def width(svg)
    REXML::Document.new(svg).root.attributes['width'].to_f
  end

  def labels(svg)
    REXML::Document.new(svg).get_elements('//text').map(&:text)
  end

  it 'wraps a long sequence within the requested SVG width in leaf order' do
    diagram = described_class.new(RailroadDiagrams::Sequence.new(*(1..10).map(&:to_s)))
    original = diagram.to_svg
    wrapped = diagram.to_svg(max_width: 250)
    expect(width(original)).to be > 250
    expect(width(wrapped)).to be <= 250
    expect(labels(wrapped)).to eq(labels(original))
    expect(diagram.to_svg(max_width: nil)).to eq(original)
  end

  it 'keeps a single oversized element and validates the limit' do
    diagram = described_class.new('a very long single terminal')
    expect(width(diagram.to_svg(max_width: 80))).to be > 80
    expect { diagram.to_svg(max_width: 0) }.to raise_error(RailroadDiagrams::InvalidArgument)
  end

  # The SVG width must be parsed from the captured HTML.
  # rubocop:disable-next RSpec/ExpectOutput
  it 'passes the width option through the demo command' do
    original = $stdout
    $stdout = StringIO.new
    RailroadDiagrams::Command.new.run(['--max-width', '250', 'rr-sequence'])
    expect(width($stdout.string[%r{<svg.*?</svg>}m])).to be <= 250
  ensure
    $stdout = original
  end
end
