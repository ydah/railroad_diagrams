# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rbconfig'

# rubocop:disable-next RSpec/DescribeClass
RSpec.describe 'optional integrations' do
  it 'loads the core without loading optional frameworks' do
    library = File.expand_path('../../lib', __dir__)
    code = 'require "railroad_diagrams"; abort if defined?(::Jekyll) || defined?(::Asciidoctor) || defined?(::ActionView)'
    environment = { 'RUBYOPT' => nil, 'BUNDLE_GEMFILE' => nil }
    _output, errors, status = Open3.capture3(environment, RbConfig.ruby, '-I', library, '-e', code)
    expect(status.exitstatus).to eq(0)
    expect(errors).to eq('')
  end
end
