# frozen_string_literal: true

require 'spec_helper'
require 'railroad_diagrams/importers/yaml_grammar'

RSpec.describe RailroadDiagrams::Importers::YamlGrammar do
  let(:fixture) { File.expand_path('../../fixtures/yaml/sql_select.yml', __dir__) }

  # rubocop:disable RSpec/ExampleLength
  it 'parses the documented shorthand into ordered rules and diagram nodes' do
    document = described_class.parse(File.read(fixture), filename: fixture)

    expect(document.title).to eq('SQL SELECT')
    expect(document.rules.map(&:first)).to eq(%w[select_stmt column])
    expect(document.rules[0][1].to_h).to eq(
      'type' => 'sequence',
      'items' => [
        { 'type' => 'terminal', 'text' => 'SELECT' },
        { 'type' => 'optional', 'item' => { 'type' => 'terminal', 'text' => 'DISTINCT' }, 'skip' => false },
        { 'type' => 'separated_list', 'item' => { 'type' => 'non_terminal', 'text' => 'column' },
          'separator' => { 'type' => 'terminal', 'text' => ',' }, 'min' => 1, 'trailing' => false },
        { 'type' => 'terminal', 'text' => 'FROM' },
        { 'type' => 'non_terminal', 'text' => 'table' },
        { 'type' => 'optional', 'item' => { 'type' => 'sequence', 'items' => [
          { 'type' => 'terminal', 'text' => 'WHERE' }, { 'type' => 'non_terminal', 'text' => 'expr' }
        ] }, 'skip' => false }
      ]
    )
    expect(document.rules[1][1].to_h['type']).to eq('choice')
  end

  it 'supports every documented shorthand form' do
    source = <<~YAML
      rules:
        forms:
          - ~
          - comment: note
          - stack: [a, b]
          - hchoice: [a, b]
          - oseq: [a, b]
          - alt: [a, b]
          - zero_or_more: { item: a, separator: ",", skip: true }
          - one_or_more: { item: a, separator: "," }
          - repeat: { item: a, min: 2, max: 4 }
          - group: { item: a, label: note }
          - except: { item: a, excluded: b }
    YAML

    nodes = described_class.parse(source).rules.first[1].child_nodes
    expect(nodes.map { |node| node.to_h['type'] }).to eq(
      %w[skip comment stack horizontal_choice optional_sequence alternating_sequence
         zero_or_more one_or_more repeat group except]
    )
  end
  # rubocop:enable RSpec/ExampleLength

  it 'reports the source position of an unknown key' do
    source = "rules:\n  item:\n    mystery: value\n"
    expect { described_class.parse(source, filename: 'bad.yml') }.to raise_error(RailroadDiagrams::ParseError) do |error|
      expect(error.message).to include('bad.yml:3:5', 'unknown key: mystery')
      expect(error.line).to eq(3)
    end
  end

  it 'reports the source position of a wrong value type' do
    source = "rules:\n  item:\n    choice: scalar\n"
    expect { described_class.parse(source, filename: 'bad.yml') }.to raise_error(RailroadDiagrams::ParseError) do |error|
      expect(error.message).to include('bad.yml:3:13', 'choice must be a sequence')
      expect(error.line).to eq(3)
    end
  end

  it 'accepts inline optional options' do
    source = "rules:\n  item:\n    optional: { item: a, skip: true }\n"
    node = described_class.parse(source).rules.first[1]
    expect(node.to_h).to eq('type' => 'optional', 'item' => { 'type' => 'terminal', 'text' => 'a' }, 'skip' => true)
  end

  it 'reports nested option errors at their key' do
    source = "rules:\n  item:\n    list: { item: a, mystery: b }\n"
    expect { described_class.parse(source, filename: 'bad.yml') }.to raise_error(RailroadDiagrams::ParseError) do |error|
      expect(error.message).to include('bad.yml:3:22', 'unknown key: mystery')
    end
  end

  it 'rejects duplicate keys, aliases, and Ruby objects' do
    expect { described_class.parse("rules:\n  a: x\n  a: y\n") }.to raise_error(RailroadDiagrams::ParseError, /duplicate key/)
    expect { described_class.parse("rules:\n  a: &a x\n  b: *a\n") }.to raise_error(RailroadDiagrams::ParseError)
    expect { described_class.parse("rules:\n  a: !ruby/object:Object {}\n") }.to raise_error(RailroadDiagrams::ParseError)
  end

  # rubocop:disable-next RSpec/ExampleLength
  it 'accepts compact and configured repetition, choices, and groups' do
    source = <<~YAML
      rules:
        forms:
          - {choice: [a, b], default: 1}
          - {optional: a, skip: true}
          - {zero_or_more: a}
          - {one_or_more: a}
          - {repeat: a}
          - {repeat: {item: a, min: 2, max: null, separator: ",", label: count}}
          - {list: {item: a, min: 0, trailing: true}}
          - {group: a}
          - {except: {item: a, excluded: "<digit>", label: excluded}}
    YAML
    nodes = described_class.parse(source).rules.first.last.child_nodes
    expect(nodes.map { |node| node.to_h['type'] }).to eq(
      %w[choice optional zero_or_more one_or_more repeat repeat separated_list group except]
    )
    expect(nodes[0].to_h['default']).to eq(1)
    expect(nodes[1].to_h['skip']).to be(true)
    expect(nodes[6].to_h['trailing']).to be(true)
    expect(nodes[8].to_h['excluded']['type']).to eq('non_terminal')
  end

  # rubocop:disable-next RSpec/ExampleLength
  it 'rejects missing and malformed grammar fields with their source locations' do
    {
      'title: 3' => /title must be a string/,
      'rules: []' => /expected a mapping/,
      "rules:\n  a: {optional: {item: x, skip: true}, skip: false}" => /skip specified twice/,
      "rules:\n  a: {repeat: {min: 2}}" => /missing item/,
      "rules:\n  a: {list: {item: x, trailing: maybe}}" => /trailing must be a boolean/,
      "rules:\n  a: {choice: [a], default: bad}" => /default must be an integer/,
      "rules:\n  a: {repeat: {item: x, max: bad}}" => /max must be an integer or null/,
      "rules:\n  a: 7" => /expected a string, sequence, mapping, or null/
    }.each do |source, message|
      expect { described_class.parse(source) }.to raise_error(RailroadDiagrams::ParseError, message)
    end
  end
end
