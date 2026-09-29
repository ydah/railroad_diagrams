# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require_relative 'support/examples_loader'

RSpec.describe 'Golden outputs' do
  ExamplesLoader.names.each do |name|
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
