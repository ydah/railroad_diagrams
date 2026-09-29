# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable-next RSpec/DescribeClass
RSpec.describe 'Asciidoctor block processor' do
  it 'renders a railroad YAML block as an SVG passthrough' do
    begin
      require 'asciidoctor'
    rescue LoadError
      skip 'Asciidoctor is not installed'
    end
    require_relative '../../integrations/asciidoctor-railroad/lib/asciidoctor-railroad'

    source = "[railroad]\n----\nrules:\n  entry: hello\n----\n"
    html = Asciidoctor.convert(source, safe: :safe, header_footer: false)
    expect(html).to include('<svg', 'hello')
    expect(html).not_to include('rules:')
  end
end
