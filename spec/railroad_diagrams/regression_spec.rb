# frozen_string_literal: true

require 'spec_helper'

RSpec::Matchers.define_negated_matcher :exclude, :include

RSpec.describe 'Regressions (Phase 0)' do

  def svg(diagram)
    s = +''
    diagram.write_svg(s.method(:<<))
    s
  end

  def text(diagram)
    s = +''
    diagram.write_text(s.method(:<<))
    s
  end

  it 'BUG-01: walk visits every node' do
    visited = []
    RailroadDiagrams::Diagram.new('a', RailroadDiagrams::Group.new('b', 'label')).walk(->(n) { visited << n.class })
    expect(visited).to include(RailroadDiagrams::Diagram, RailroadDiagrams::Group, RailroadDiagrams::Terminal)
  end

  it 'BUG-02: base text_diagram raises NotImplementedError' do
    expect { RailroadDiagrams::DiagramItem.new('g').text_diagram }.to raise_error(NotImplementedError)
  end

  it 'BUG-03: Diagram#to_s describes its items' do
    expect(RailroadDiagrams::Diagram.new('a').to_s).to include('Terminal(a')
  end

  describe 'BUG-04: write_standalone css' do
    def standalone(css = :omit)
      s = +''
      d = RailroadDiagrams::Diagram.new('a')
      css == :omit ? d.write_standalone(s.method(:<<)) : d.write_standalone(s.method(:<<), css)
      s
    end

    it('uses the default css when omitted') { expect(standalone).to include('svg.railroad-diagram path') }
    it('uses the default css when true') { expect(standalone(true)).to include('svg.railroad-diagram path') }
    it('keeps custom css') { expect(standalone('.custom{}')).to include('.custom{}').and exclude('svg.railroad-diagram path') }
    it('omits <style> when false') { expect(standalone(false)).not_to include('<style') }
  end

  it 'BUG-05: format is idempotent' do
    d = RailroadDiagrams::Diagram.new('a')
    d.format
    first = svg(d)
    d.format
    expect(svg(d)).to eq(first)
  end

  it 'BUG-06: Comment fills the width it is given' do
    c = RailroadDiagrams::Comment.new('c')
    c.format(0, 0, 100)
    total = c.children.grep(RailroadDiagrams::Path).sum { |p| p.attrs['d'][/h([\d.]+)\z/, 1].to_f }
    expect(total + c.width).to be_within(0.001).of(100)
  end

  it 'BUG-07: Group label is not stretched to the box width' do
    g = RailroadDiagrams::Group.new(RailroadDiagrams::Terminal.new('long terminal text'), 'x')
    g.format(0, 0, g.width)
    label = g.children.find { |c| c.is_a?(RailroadDiagrams::Comment) }
    expect(label.children.grep(RailroadDiagrams::Path).map { |p| p.attrs['d'] }).to all(end_with('h0'))
  end

  it 'BUG-08: MultipleChoice text shows its items' do
    out = text(RailroadDiagrams::Diagram.new(RailroadDiagrams::MultipleChoice.new(0, 'any', 'alpha', 'beta')))
    expect(out).to include('alpha').and include('beta')
  end

  it 'BUG-09: expand marks only the entry/exit rows' do
    td = RailroadDiagrams::TextDiagram.new(0, 0, %w[ab ab]).expand(1, 1, 0, 0)
    expect(td.lines).to eq(['─ab─', ' ab '])
  end

  it 'BUG-10: write_text works without set_formatting' do
    RailroadDiagrams::TextDiagram.parts = nil
    expect(text(RailroadDiagrams::Diagram.new('a'))).to include('a')
  end

  it 'BUG-11: attribute values escape < and >' do
    out = svg(RailroadDiagrams::Diagram.new(RailroadDiagrams::Terminal.new('a', 'http://x/?q=<b>', 'x<y')))
    expect(out).to include('http://x/?q=&lt;b&gt;').and exclude('q=<b>')
  end

  it 'BUG-12: large numbers are not written in exponent form' do
    expect(RailroadDiagrams.escape_attr(1_234_567.5)).to eq('1234567.5')
  end

  it 'BUG-14: Choice rejects invalid default' do
    expect { RailroadDiagrams::Choice.new(-1, 'a', 'b') }.to raise_error(ArgumentError)
    expect { RailroadDiagrams::Choice.new('0', 'a', 'b') }.to raise_error(ArgumentError)
  end

  it 'BUG-15: center into a smaller width raises ArgumentError' do
    expect { RailroadDiagrams::TextDiagram.new(0, 0, ['abcd']).center(2) }.to raise_error(ArgumentError, /smaller width/)
  end

  it 'BUG-17: TextDiagram#inspect is public' do
    expect(RailroadDiagrams::TextDiagram.new(0, 0, ['a']).inspect).to start_with('TextDiagram(')
  end

  it 'BUG-18: Style#text_diagram returns an empty diagram' do
    expect(RailroadDiagrams::Style.new('x').text_diagram.lines).to eq([])
  end

  it 'BUG-19: write_standalone is callable on any item' do
    expect { RailroadDiagrams::Terminal.new('a').write_standalone(->(_) {}) }.not_to raise_error
  end
end
