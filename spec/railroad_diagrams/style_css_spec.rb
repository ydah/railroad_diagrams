# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::Style do
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
