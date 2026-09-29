require 'spec_helper'
require 'railroad_diagrams/builder'
require_relative '../support/examples_loader'

RSpec.describe RailroadDiagrams::DSL do
  it 'renders every demo sample exactly like the direct constructor version' do
    legacy = ExamplesLoader::Collector.new
    dsl = ExamplesLoader::Collector.new
    dsl.define_singleton_method(:add_dsl) { |name, diagram| add(name, diagram) }
    { 'demo.rb' => legacy, 'demo_dsl.rb' => dsl }.each do |file, collector|
      path = File.expand_path("../../examples/#{file}", __dir__)
      collector.instance_eval(File.read(path, encoding: 'utf-8'), path)
    end

    expect(dsl.diagrams.keys).to eq(legacy.diagrams.keys)
    legacy.diagrams.each do |name, diagram|
      expect(dsl.diagrams.fetch(name).to_svg).to eq(diagram.to_svg), name
    end
  end
end
