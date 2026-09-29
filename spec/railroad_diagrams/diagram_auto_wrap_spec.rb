# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rbconfig'
require 'rexml/document'

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

  it 'passes the width option through the demo command' do
    command = File.expand_path('../../exe/railroad_diagrams', __dir__)
    output, error, status = Open3.capture3(RbConfig.ruby, command, '--max-width', '250', 'rr-sequence')
    expect(status).to be_success
    expect(error).to eq('')
    expect(width(output[%r{<svg.*?</svg>}m])).to be <= 250
  end
end
