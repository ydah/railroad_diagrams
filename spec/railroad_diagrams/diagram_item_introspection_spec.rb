# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::DiagramItem do
  let(:rd) { RailroadDiagrams }

  it 'visits each semantic node in depth-first order' do
    diagram = rd::Diagram.new(rd::Sequence.new('SELECT', rd::Optional.new('DISTINCT')))
    nodes = diagram.each_node.to_a
    expect(nodes.map { |node| node.class.name.split('::').last }).to eq(
      %w[Diagram Start Sequence Terminal Optional Skip Terminal End]
    )
    expect(diagram.map(&:class)).to eq(nodes.map(&:class))
  end

  it 'compares structure without depending on rendering caches' do
    left = rd::Diagram.new(rd::Sequence.new('A', rd::Optional.new('B')))
    same = rd::Diagram.new(rd::Sequence.new('A', rd::Optional.new('B')))
    different = rd::Diagram.new(rd::Sequence.new('A', rd::Choice.new(1, rd::Skip.new, 'B')))
    left.to_svg
    expect(left).to eq(same)
    expect(left.hash).to eq(same.hash)
    expect(left).not_to eq(different)
  end

  it 'inspects nested nodes in DSL form and keeps to_s unchanged' do
    node = rd::Sequence.new('SELECT', rd::Optional.new('DISTINCT'))
    expect(node.inspect).to eq('seq(t("SELECT"), opt(t("DISTINCT")))')
    expect(node.to_s).to start_with('Sequence(')
    expect(rd::Diagram.new('A', desc: :auto).inspect).to eq('diagram(t("A"), desc: :auto)')
  end
end
