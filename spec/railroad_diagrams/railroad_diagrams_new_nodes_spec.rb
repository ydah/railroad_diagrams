# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/railroad_diagrams/complex_diagram'
require_relative '../../lib/railroad_diagrams/block'
require_relative '../../lib/railroad_diagrams/char_class'
require_relative '../../lib/railroad_diagrams/special'
require_relative '../../lib/railroad_diagrams/expanded_node'
require_relative '../../lib/railroad_diagrams/repeat'
require_relative '../../lib/railroad_diagrams/separated_list'
require_relative '../../lib/railroad_diagrams/except'
require_relative '../../lib/railroad_diagrams/serialization'

RSpec.describe RailroadDiagrams do
  def context(locale = :en)
    RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(locale: locale))
  end

  it 'creates a complex diagram through the factory' do
    diagram = RailroadDiagrams::ComplexDiagram.new('word')
    expect(diagram).to be_a(RailroadDiagrams::Diagram)
    expect(diagram.to_h['diagram_type']).to eq('complex')
  end

  it 'measures and draws a Block with its specified dimensions' do
    block = RailroadDiagrams::Block.new(width: 42, up: 6, height: 9, down: 4, needs_space: false)
    expect(context.metrics(block).to_a).to eq([42, 6, 9, 4, false])
    svg = RailroadDiagrams::Svg::Serializer.call(block.render_svg(context, 0, 20, 42))
    expect(svg).to include('<rect height="19" width="42" x="0" y="14"></rect>')
    expect(block.render_text(context).lines.join).to include('│')
    expect(block.to_h).to include('height' => 9, 'needs_space' => false)
  end

  it 'rejects invalid Block dimensions' do
    expect { RailroadDiagrams::Block.new(width: -1) }.to raise_error(RailroadDiagrams::InvalidArgument)
    expect { RailroadDiagrams::Block.new(up: Float::INFINITY) }.to raise_error(RailroadDiagrams::InvalidArgument)
    expect { RailroadDiagrams::Block.new(height: Complex(1, 1)) }.to raise_error(RailroadDiagrams::InvalidArgument)
    expect { RailroadDiagrams::Block.new(width: Rational(1, 2)) }.to raise_error(RailroadDiagrams::InvalidArgument)
  end

  it 'uses translated repeat counts and handles zero to one occurrences' do
    repeat = RailroadDiagrams::Repeat.new('word', min: 2, max: 4, separator: ',')
    expect(repeat.render_text(context(:en)).lines.join).to include('2–4 times')
    expect(repeat.render_text(context(:ja)).lines.join).to include('2〜4回')
    expect(RailroadDiagrams::Repeat.new('word', min: 0, max: 1).child_nodes.length).to eq(1)
    expect(RailroadDiagrams::Repeat.new('word', min: 0, max: 0).render_text(context).lines.join).not_to include('word')
    expect { RailroadDiagrams::Repeat.new('word', min: 3, max: 2) }.to raise_error(RailroadDiagrams::InvalidArgument)
  end

  it 'makes a list optional as a whole and allows trailing separators' do
    list = RailroadDiagrams::SeparatedList.new('word', ',', min: 0, trailing: true)
    expect(list.child_nodes.map(&:class)).to eq([RailroadDiagrams::Terminal, RailroadDiagrams::Terminal])
    expect(list.render_text(context).lines.join).to include('word', ',')
    expect(list.to_h).to include('min' => 0, 'trailing' => true)
    expect { RailroadDiagrams::SeparatedList.new('a', ',', min: -1) }.to raise_error(RailroadDiagrams::InvalidArgument)
  end

  it 'describes a string or node exclusion in the label' do
    word = RailroadDiagrams::Except.new('word', 'reserved')
    expect(word.render_text(context(:en)).lines.join).to include('except reserved')
    expect(word.render_text(context(:ja)).lines.join).to include('reservedを除く')
    node = RailroadDiagrams::Except.new('word', RailroadDiagrams::Terminal.new('reserved'))
    expect(node.render_text(context(:en)).lines.join).to include('reserved')
    expect(node.child_nodes.length).to eq(2)
  end

  it 'distinguishes character classes and special tokens without changing their shapes' do
    klass = RailroadDiagrams::CharClass.new('[a-z]')
    special = RailroadDiagrams::Special.new('any char')
    expect(klass.attrs['class']).to include('terminal', 'char-class')
    expect(special.attrs['class']).to include('non-terminal', 'special')
    expect(klass.render_text(context).lines).to eq(RailroadDiagrams::Terminal.new('[a-z]').render_text(context).lines)
    expect(special.render_text(context).lines).to eq(RailroadDiagrams::NonTerminal.new('any char').render_text(context).lines)
    expect(klass.to_h).to include('type' => 'char_class', 'text' => '[a-z]')
    expect(special.to_h).to include('type' => 'special', 'text' => 'any char')
  end

  it 'round trips each new node through the canonical structure' do # rubocop:disable RSpec/ExampleLength
    nodes = [
      RailroadDiagrams::Block.new(id: 'space'),
      RailroadDiagrams::Repeat.new('a', min: 2, max: 4, separator: ',', label: :auto),
      RailroadDiagrams::Repeat.new('a', label: 'auto'),
      RailroadDiagrams::SeparatedList.new('a', ',', min: 0, trailing: true),
      RailroadDiagrams::Except.new('a', RailroadDiagrams::Terminal.new('b'), label: :auto),
      RailroadDiagrams::Except.new('a', 'b', label: 'auto'),
      RailroadDiagrams::CharClass.new('[a-z]', href: '#class', cls: 'user'),
      RailroadDiagrams::Special.new('any', title: 'wildcard', cls: 'user')
    ]
    nodes.each do |node|
      expect(described_class.from_h(node.to_h).to_h).to eq(node.to_h)
    end
  end

  it 'keeps legacy and pure SVG output identical for expanded nodes' do # rubocop:disable RSpec/ExampleLength
    nodes = [
      RailroadDiagrams::Block.new,
      RailroadDiagrams::Repeat.new('a', min: 2, max: 3),
      RailroadDiagrams::SeparatedList.new('a', ','),
      RailroadDiagrams::Except.new('a', 'b')
    ]
    nodes.each do |node|
      pure = RailroadDiagrams::Diagram.new(node).to_svg
      legacy = +''
      RailroadDiagrams::Diagram.new(node).write_svg(legacy)
      expect(pure).to eq(legacy)
    end
  end
end
