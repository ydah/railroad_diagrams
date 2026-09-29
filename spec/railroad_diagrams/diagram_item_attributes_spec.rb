# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

RSpec.describe RailroadDiagrams::DiagramItem do
  cases = {
    Terminal: ['a'], NonTerminal: ['a'], Comment: ['a'],
    Skip: [], Start: [], End: [],
    Sequence: ['a'], Stack: ['a'], Choice: [0, 'a'],
    Optional: ['a'], ZeroOrMore: ['a'], OneOrMore: ['a'],
    Group: ['a'], HorizontalChoice: %w[a b], OptionalSequence: %w[a b],
    AlternatingSequence: %w[a b], MultipleChoice: [0, 'any', 'a', 'b']
  }

  cases.each do |name, args|
    it "renders #{name} id, class, and data attributes" do
      type = RailroadDiagrams.const_get(name)
      node = type.new(*args, id: 'node', cls: 'custom', attrs: { 'data-label' => '<&' })
      svg = RailroadDiagrams::Diagram.new(node).to_svg(id_prefix: 'prefix-')
      element = REXML::Document.new(svg).get_elements('//*[@id="prefix-node"]').first
      expect(element.attributes['class']).to include('custom')
      expect(element.attributes['data-label']).to eq('<&')
      expect(svg).to include('data-label="&lt;&amp;"')
    end
  end
end
