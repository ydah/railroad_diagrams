# frozen_string_literal: true

module TreeGenerator
  OSEQ_WEIGHT = Integer(ENV.fetch('OSEQ_WEIGHT', 1))
  raise ArgumentError, 'OSEQ_WEIGHT must be positive' unless OSEQ_WEIGHT.positive?

  module_function

  def node(random, depth)
    return leaf(random) if depth.zero? || random.rand < 0.3

    children = Array.new(random.rand(1..3)) { node(random, depth - 1) }
    case random.rand(9 + OSEQ_WEIGHT)
    when 0 then RailroadDiagrams::Sequence.new(*children)
    when 1 then RailroadDiagrams::Stack.new(*children)
    when 2 then RailroadDiagrams::Choice.new(random.rand(children.size), *children)
    when 3 then RailroadDiagrams::Optional.new(children.first, skip: random.rand < 0.5)
    when 4 then RailroadDiagrams::OneOrMore.new(children.first, children[1])
    when 5 then RailroadDiagrams::ZeroOrMore.new(children.first)
    when 6 then RailroadDiagrams::Group.new(children.first, label: 'g')
    when 7 then RailroadDiagrams::HorizontalChoice.new(*children)
    when 8, (10..(8 + OSEQ_WEIGHT)) then RailroadDiagrams::OptionalSequence.new(*children)
    else
      children.size >= 2 ? RailroadDiagrams::AlternatingSequence.new(*children.first(2)) : children.first
    end
  end

  def leaf(random)
    case random.rand(4)
    when 0 then RailroadDiagrams::Terminal.new(%w[a bb ccc select 日本語].sample(random: random))
    when 1 then RailroadDiagrams::NonTerminal.new(%w[x expr stmt].sample(random: random))
    when 2 then RailroadDiagrams::Comment.new(%w[c note].sample(random: random))
    else RailroadDiagrams::Skip.new
    end
  end

  def diagram(seed)
    RailroadDiagrams::Diagram.new(node(Random.new(seed), 4))
  end
end
