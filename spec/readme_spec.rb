# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'open3'
require 'rbconfig'
require 'rexml/document'

RSpec.describe 'README quick start' do # rubocop:disable RSpec/DescribeClass
  it 'runs unchanged and writes a standalone SVG' do
    readme = File.read(File.expand_path('../README.md', __dir__))
    example = readme.match(/## Quick start.*?```ruby\n(.*?)\n```/m)[1]

    Dir.mktmpdir do |directory|
      library = File.expand_path('../lib', __dir__)
      _stdout, stderr, status = Open3.capture3(RbConfig.ruby, '-I', library, '-e', example, chdir: directory)
      expect(status).to be_success, stderr

      svg = REXML::Document.new(File.read(File.join(directory, 'select.svg')))
      expect(svg.root.name).to eq('svg')
      expect(REXML::XPath.first(svg, '//style')).not_to be_nil
    end
  end
end
