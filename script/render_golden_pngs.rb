# frozen_string_literal: true

require 'fileutils'

files = Dir.glob('spec/golden/**/standalone*.svg').sort
abort 'no standalone SVG goldens found' if files.empty?

files.each do |file|
  target = File.join('tmp/golden-png', File.basename(File.dirname(file)), "#{File.basename(file, '.svg')}.png")
  FileUtils.mkdir_p(File.dirname(target))
  abort "failed to render #{file}" unless system('rsvg-convert', file, '-o', target)
end

puts "Rendered #{files.length} golden PNGs"
