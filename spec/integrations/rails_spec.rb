# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable-next RSpec/DescribeClass
RSpec.describe 'Rails view helper' do
  # rubocop:disable-next RSpec/ExampleLength
  it 'returns a safe SVG from a DSL block after Action View loads' do
    begin
      require 'active_support'
      require 'action_view'
    rescue LoadError
      skip 'Action View is not installed'
    end
    require 'railroad_diagrams/rails'

    view_class = Class.new do
      include RailroadDiagrams::Rails::Helper
    end
    svg = view_class.new.railroad_diagram(theme: :dark) { seq('SELECT', :table) }
    expect(svg).to be_html_safe
    expect(svg).to include('<svg', 'SELECT', 'table')
  end
end
