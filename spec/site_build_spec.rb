# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'rexml/document'
require_relative '../script/build_site'

RSpec.describe SiteBuild do
  it 'builds a linked page for every theme and a preview for every visible node' do
    Dir.mktmpdir do |directory|
      described_class.build(directory)
      index = REXML::Document.new(File.read(File.join(directory, 'index.html')))
      expect(REXML::XPath.match(index, '//article').size).to eq(described_class::NODES.size)
      expect(Dir[File.join(directory, 'themes', '*.html')].size).to eq(ExamplesLoader::THEMES.size)
      expect(REXML::XPath.match(index, '//nav/a').map { |link| link.attributes['href'] }).to include('themes/dark.html')
    end
  end
end
