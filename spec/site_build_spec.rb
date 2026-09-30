# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'rexml/document'
require_relative '../script/build_site'

RSpec.describe SiteBuild do
  it 'builds linked theme pages and a preview for every visible node' do
    Dir.mktmpdir do |directory|
      described_class.build(directory)
      index = REXML::Document.new(File.read(File.join(directory, 'index.html')))
      expect(REXML::XPath.match(index, '//article').size).to eq(described_class::NODES.size)
      expect(Dir[File.join(directory, 'themes', '*.html')].size).to eq(ExamplesLoader::THEMES.size)
      expect(REXML::XPath.match(index, '//nav/a').map { |link| link.attributes['href'] }).to include('themes/dark.html', 'guide/index.html')
      expect(File.read(File.join(directory, 'playground.js'))).to include('./vendor/ruby+stdlib.wasm')
      expect(File.read(File.join(directory, 'playground_bundle.js'))).to include('playground_render')
    end
  end

  it 'publishes a guide with unique anchors, working contents links, and its diagram' do
    Dir.mktmpdir do |directory|
      described_class.build(directory)
      guide = REXML::Document.new(File.read(File.join(directory, 'guide', 'index.html')))
      expect(REXML::XPath.first(guide, '//h1').text).to eq('User Guide')
      ids = REXML::XPath.match(guide, '//*[@id]').map { |element| element.attributes['id'] }
      fragments = REXML::XPath.match(guide, '//a').map { |link| link.attributes['href'] }.grep(/\A#/)
      expect(ids.uniq).to eq(ids)
      expect(fragments.map { |href| href.delete_prefix('#') } - ids).to eq([])
      expect(File.read(File.join(directory, 'guide', 'select.svg'))).to include('SELECT', 'DISTINCT')
    end
  end
end
