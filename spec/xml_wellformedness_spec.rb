# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'
require_relative 'support/examples_loader'

RSpec.describe 'SVG well-formedness' do
  ExamplesLoader.names.each do |name|
    %w[svg standalone].each do |format|
      it "#{name} (#{format}) is well-formed XML" do
        xml = ExamplesLoader.render(name, format)
        expect { REXML::Document.new(xml) }.not_to raise_error
        expect(REXML::Document.new(xml).root.name).to eq('svg')
      end
    end
  end
end
