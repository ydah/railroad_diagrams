# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'rexml/document'
require_relative 'support/examples_loader'

RSpec.describe 'Golden outputs' do
  ExamplesLoader.names.each do |name|
    it "#{name} (Context SVG) matches the existing golden file" do
      actual = ExamplesLoader.load.fetch(name).to_svg
      expect(actual).to eq(File.read(ExamplesLoader.golden_path(name, 'svg'), encoding: 'utf-8'))
    end

    it "#{name} optimized SVG is valid XML with rounded root dimensions" do
      root = REXML::Document.new(ExamplesLoader.render(name, 'svg-optimized')).root
      expect(root.name).to eq('svg')
      expect(%w[width height viewBox].map { |key| root.attributes[key] }.join(' ')).not_to match(/\.\d{3,}/)
    end

    it "#{name} default standalone SVG matches the existing golden file" do
      actual = ExamplesLoader.load.fetch(name).to_standalone_svg(theme: :default)
      expect(actual).to eq(File.read(ExamplesLoader.golden_path(name, 'standalone'), encoding: 'utf-8'))
    end

    ExamplesLoader::THEMES.each do |theme|
      it "#{name} standalone #{theme} SVG is valid XML" do
        path = ExamplesLoader.golden_path(name, "standalone-#{theme}")
        expect(REXML::Document.new(File.read(path, encoding: 'utf-8')).root.name).to eq('svg')
      end
    end

    ExamplesLoader::RENDERERS.each_key do |format|
      it "#{name} (#{format}) matches the golden file" do
        actual = ExamplesLoader.render(name, format)
        path = ExamplesLoader.golden_path(name, format)

        if ENV['GOLDEN_UPDATE']
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, actual)
        end

        expect(File).to exist(path), "golden file missing: #{path} (run `rake golden:update`)"
        expect(actual).to eq(File.read(path, encoding: 'utf-8'))
      end
    end
  end
end
