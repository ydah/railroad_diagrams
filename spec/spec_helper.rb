require 'railroad_diagrams'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:each) do
    RailroadDiagrams::TextDiagram.set_formatting(
      RailroadDiagrams::TextDiagram::PARTS_UNICODE
    )
  end
end

module SvgHelpers
  def svg_output(diagram)
    output = StringIO.new
    diagram.write_svg(output.method(:write))
    output.string
  end

  def has_element?(svg, tag, attrs = {})
    attrs.all? { |k, v| svg.include?("#{k}=\"#{v}\"") } && svg.include?("<#{tag}")
  end
end

RSpec.configure do |config|
  config.include SvgHelpers
end
