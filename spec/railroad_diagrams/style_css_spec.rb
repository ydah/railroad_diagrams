# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'

RSpec.describe RailroadDiagrams::Style do
  it 'keeps CSS terminators inside the style element' do
    css = 'text { content: "]]></style><script>bad</script>"; }'
    diagram = RailroadDiagrams::Diagram.new('a', described_class.new(css))
    [diagram.to_svg, diagram.to_standalone_svg(css: css)].each do |svg|
      document = REXML::Document.new(svg)
      expect(document.root.name).to eq('svg')
      expect(document.get_elements('//script')).to be_empty
    end
  end

  it 'preserves spaces and styles MultipleChoice labels' do
    css = described_class.default_style
    expect(css).to include('white-space: pre;')
    expect(css).to include('text.diagram-text')
    expect(css).to include('path.diagram-text')
  end

  it 'marks Comment without dropping its legacy class' do
    expect(RailroadDiagrams::Comment.new('note').attrs['class']).to include('comment', 'non-terminal')
  end
end
