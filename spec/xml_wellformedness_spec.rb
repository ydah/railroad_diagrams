# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'
require_relative 'support/examples_loader'

RSpec.describe 'SVG well-formedness' do
  ExamplesLoader.names.each do |name|
    %w[svg standalone].each do |format|
      it "#{name} (#{format}) is well-formed and matches the viewBox" do
        xml = ExamplesLoader.render(name, format)
        root = REXML::Document.new(xml).root
        expect(root.name).to eq('svg')
        x, y, width, height = root.attributes['viewBox'].split.map(&:to_f)
        expect([x, y, width, height]).to eq([0.0, 0.0, root.attributes['width'].to_f, root.attributes['height'].to_f])
      end

      it "#{name} (#{format}) keeps rectangles inside the viewBox" do
        root = REXML::Document.new(ExamplesLoader.render(name, format)).root
        _x, _y, width, height = root.attributes['viewBox'].split.map(&:to_f)
        REXML::XPath.each(root, '//rect') do |rect|
          left = rect.attributes['x'].to_f
          top = rect.attributes['y'].to_f
          expect(left).to be >= 0
          expect(top).to be >= 0
          expect(left + rect.attributes['width'].to_f).to be <= width
          expect(top + rect.attributes['height'].to_f).to be <= height
        end
      end
    end
  end
end
