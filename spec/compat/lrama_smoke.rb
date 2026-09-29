# frozen_string_literal: true

require 'open3'
require 'tmpdir'
require 'rbconfig'

lrama = File.expand_path(ARGV.fetch(0))
library = File.expand_path('../../lib', __dir__)

Dir.mktmpdir('railroad-lrama-') do |dir|
  html = File.join(dir, 'diagram.html')
  parser = File.join(dir, 'parser.c')
  command = [RbConfig.ruby, "-I#{library}", File.join(lrama, 'exe/lrama'),
             "--diagram=#{html}", "--output=#{parser}", File.join(lrama, 'sample/parse.y')]
  _stdout, stderr, status = Open3.capture3(*command, chdir: lrama)
  raise "Lrama diagram failed: #{stderr}" unless status.success?
  raise 'Lrama produced no SVG' unless File.read(html).include?('<svg')
end
