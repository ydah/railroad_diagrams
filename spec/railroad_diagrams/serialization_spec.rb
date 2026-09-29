# frozen_string_literal: true

require 'spec_helper'
require 'railroad_diagrams/complex_diagram'
require 'railroad_diagrams/block'
require 'railroad_diagrams/char_class'
require 'railroad_diagrams/special'
require 'railroad_diagrams/expanded_node'
require 'railroad_diagrams/repeat'
require 'railroad_diagrams/separated_list'
require 'railroad_diagrams/except'
require 'railroad_diagrams/serialization'
require_relative '../support/tree_generator'

RSpec.describe RailroadDiagrams::Serialization do
  let(:rd) { RailroadDiagrams }

  # rubocop:disable-next RSpec/ExampleLength
  it 'uses the documented canonical shape without generated diagram ends' do
    diagram = rd::Diagram.new('SELECT', rd::Optional.new('DISTINCT'),
                              rd::OneOrMore.new(rd::NonTerminal.new('column', href: '#rule-column'), ','))

    expect(diagram.to_h).to eq(
      'type' => 'diagram', 'diagram_type' => 'simple',
      'items' => [
        { 'type' => 'terminal', 'text' => 'SELECT' },
        { 'type' => 'optional', 'item' => { 'type' => 'terminal', 'text' => 'DISTINCT' }, 'skip' => false },
        { 'type' => 'one_or_more', 'item' => { 'type' => 'non_terminal', 'text' => 'column',
                                               'href' => '#rule-column' },
          'repeat' => { 'type' => 'terminal', 'text' => ',' } }
      ]
    )
  end

  # rubocop:disable-next RSpec/ExampleLength
  it 'round trips every existing node type and user attributes' do
    nodes = [
      rd::Diagram.new('a', type: 'complex', title: 'Title', desc: :auto, id: 'diagram',
                           cls: 'custom', attrs: { 'data-rule' => 'a' }),
      rd::Terminal.new('a', href: 'https://example.org', title: 'tip', cls: 'token', id: 'term', attrs: { 'data-x' => '1' }),
      rd::NonTerminal.new('name', href: '#rule'), rd::Comment.new('note'), rd::Skip.new,
      rd::Start.new('complex', label: 'begin'), rd::End.new('simple', label: 'end'),
      rd::Sequence.new('a', 'b'), rd::Stack.new('a', 'b'),
      rd::Choice.new(1, 'a', 'b'), rd::MultipleChoice.new(0, 'any', 'a', 'b'),
      rd::OneOrMore.new('a', ','), rd::Group.new('a', label: 'label'),
      rd::HorizontalChoice.new('a', 'b'), rd::OptionalSequence.new('a', 'b'),
      rd::AlternatingSequence.new('a', 'b'), rd::ZeroOrMore.new('a')
    ]

    nodes.each do |node|
      hash = node.to_h
      expect(rd.from_h(hash)).to eq(node)
      expect(rd.from_h(hash).to_h).to eq(hash)
      expect(rd.from_json(node.to_json).to_h).to eq(hash)
      expect(rd.from_yaml(node.to_yaml).to_h).to eq(hash)
      expect(JSON.parse(node.to_json)).to eq(hash)
    end
  end

  it 'round trips generated trees and keeps JSON stable after rendering' do
    schema = JSON.parse(File.read(File.expand_path('../../schema/v1.json', __dir__)))
    types = schema.fetch('definitions').fetch('node').fetch('properties').fetch('type').fetch('enum')

    100.times do |seed|
      diagram = TreeGenerator.diagram(seed)
      json = diagram.to_json
      diagram.to_svg
      expect(diagram.to_json).to eq(json)
      expect(rd.from_json(json).to_json).to eq(json)
      expect(diagram.to_h['items'].map { |item| item['type'] } - types).to be_empty
    end
  end

  # rubocop:disable-next RSpec/ExampleLength
  it 'round trips the new node forms, including automatic and literal labels' do
    nodes = [
      rd::ComplexDiagram.new('a'), rd::Block.new(width: 20.5, id: 'block'),
      rd::Repeat.new('a', min: 2, max: 4, separator: ',', label: :auto),
      rd::Repeat.new('a', label: 'auto'),
      rd::SeparatedList.new('a', ',', min: 2, trailing: true),
      rd::Except.new('a', 'b', label: 'auto'),
      rd::Except.new('a', rd::CharClass.new('[a-z]'), label: :auto),
      rd::CharClass.new('[a-z]', href: '#letters', cls: 'letters'),
      rd::Special.new('EOF', title: 'end of file')
    ]

    nodes.each do |node|
      expect(rd.from_h(node.to_h).to_h).to eq(node.to_h)
      expect(rd.from_json(node.to_json).to_h).to eq(node.to_h)
      expect(rd.from_yaml(node.to_yaml).to_h).to eq(node.to_h)
    end
  end

  it 'preserves explicit diagram ends and distinguishes auto descriptions from text' do
    diagram = rd::Diagram.new(rd::Start.new(label: 'S'), rd::End.new(label: 'E'), desc: 'auto')
    expect(rd.from_h(diagram.to_h).to_h).to eq(diagram.to_h)
    expect(diagram.to_h['desc']).to eq('auto')
    expect(diagram.to_h).not_to have_key('desc_auto')
  end

  # rubocop:disable-next RSpec/MultipleExpectations
  it 'rejects malformed, unknown, and unsafe inputs' do
    expect { rd.from_h('type' => 'missing') }.to raise_error(rd::ParseError, /unknown node type/)
    expect { rd.from_h(type: 'skip') }.to raise_error(rd::ParseError, /string keys/)
    expect { rd.from_h('type' => 'skip', 'extra' => true) }.to raise_error(rd::ParseError, /unknown field/)
    expect { rd.from_h('type' => 'skip', 'schema_version' => 2) }.to raise_error(rd::ParseError, /schema version/)
    expect { rd.from_h('type' => 'terminal', 'text' => 1) }.to raise_error(rd::ParseError, /string/)
    expect { rd.from_json('{') }.to raise_error(rd::ParseError)
    expect { rd.from_yaml("--- !ruby/object:Object {}\n") }.to raise_error(rd::ParseError)
    expect { rd.from_yaml("---\na: &a x\nb: *a\n") }.to raise_error(rd::ParseError)
  end
end
