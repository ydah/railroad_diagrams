# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable-next RSpec/DescribeClass
RSpec.describe 'Jekyll fenced diagrams' do
  it 'converts railroad fences in a Jekyll page before Markdown rendering' do
    begin
      require 'jekyll'
    rescue LoadError
      skip 'Jekyll is not installed'
    end
    require_relative '../../integrations/jekyll-railroad/lib/jekyll-railroad'

    source = "Before\n\n```railroad\nrules:\n  entry: hello\n```\n\nAfter\n"
    rendered = RailroadDiagrams::Jekyll.render_fences(source)
    expect(rendered).to include('Before', 'After', '<svg', 'hello')
    expect(rendered).not_to include('```railroad')
  end
end
