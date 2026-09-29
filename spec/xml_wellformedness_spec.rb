# frozen_string_literal: true

require 'spec_helper'
require 'rexml/document'
require_relative 'support/examples_loader'

RSpec.describe 'SVG well-formedness' do
  def path_points(data)
    tokens = data.scan(/[MmLlHhVvAaZz]|[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?/)
    raise "unrecognized path data: #{data}" unless tokens.join == data.gsub(/[\s,]/, '')

    points = []
    x = y = start_x = start_y = 0.0
    index = 0
    lengths = { 'M' => 2, 'm' => 2, 'L' => 2, 'l' => 2,
                'H' => 1, 'h' => 1, 'V' => 1, 'v' => 1,
                'A' => 7, 'a' => 7, 'Z' => 0, 'z' => 0 }
    while index < tokens.length
      command = tokens[index]
      index += 1
      length = lengths.fetch(command)
      values = tokens[index, length].map { |value| Float(value) }
      raise "incomplete path data: #{data}" unless values.length == length

      index += length
      case command
      when 'M'
        x, y = values
        start_x = x
        start_y = y
      when 'm'
        x += values[0]
        y += values[1]
        start_x = x
        start_y = y
      when 'L' then x, y = values
      when 'l'
        x += values[0]
        y += values[1]
      when 'H' then x = values[0]
      when 'h' then x += values[0]
      when 'V' then y = values[0]
      when 'v' then y += values[0]
      when 'A' then x, y = values.last(2)
      when 'a'
        x += values[-2]
        y += values[-1]
      when 'Z', 'z'
        x = start_x
        y = start_y
      end
      points << [x, y]
    end
    points
  end

  it 'reads absolute, relative, and arc endpoints' do
    expect(path_points('M10 20h5v-3l2 1a10 10 0 0 1 3 -2')).to eq(
      [[10.0, 20.0], [15.0, 20.0], [15.0, 17.0], [17.0, 18.0], [20.0, 16.0]]
    )
  end

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

      it "#{name} (#{format}) keeps path endpoints inside the viewBox" do
        root = REXML::Document.new(ExamplesLoader.render(name, format)).root
        _x, _y, width, height = root.attributes['viewBox'].split.map(&:to_f)
        REXML::XPath.each(root, '//path') do |path|
          path_points(path.attributes['d']).each do |x, y|
            expect(x).to be_between(0, width).inclusive, path.attributes['d']
            expect(y).to be_between(0, height).inclusive, path.attributes['d']
          end
        end
      end
    end
  end
end
