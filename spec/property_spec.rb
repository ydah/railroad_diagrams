# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'
require_relative 'support/tree_generator'

RSpec.describe 'Rendering properties' do
  it 'keeps the lower track below a tall left branch' do
    branch = RailroadDiagrams::HorizontalChoice.new(RailroadDiagrams::Stack.new('a', 'b'), 'c')
    lines = RailroadDiagrams::Diagram.new(branch).to_text.lines.map(&:chomp)
    expect(lines.map { |line| RailroadDiagrams::Unicode::DisplayWidth.of(line) }.uniq.size).to eq(1)
  end

  cases = Integer(ENV.fetch('PROPERTY_CASES', 500))
  base = Integer(ENV.fetch('SEED', 20_260_929))

  cases.times do |index|
    seed = base + index
    it "seed #{seed}: deterministic SVG and rectangular text" do
      diagram = TreeGenerator.diagram(seed)
      svg = diagram.to_svg
      expect(diagram.to_svg).to eq(svg)
      expect(TreeGenerator.diagram(seed).to_svg).to eq(svg)
      expect(REXML::Document.new(svg).root.name).to eq('svg')

      %i[ascii unicode].each do |charset|
        lines = diagram.to_text(charset: charset).lines.map(&:chomp)
        widths = lines.map { |line| RailroadDiagrams::Unicode::DisplayWidth.of(line) }
        expect(widths.uniq.size).to be <= 1
      end
    end
  end
end
