# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'tmpdir'

module PlaygroundVendor
  VERSION = '2.10.1'
  ASSETS = {
    browser: ['https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.10.1/dist/browser/+esm',
              '6199077de37795557ea15be527a9ee80a9ea8dc74e5c10f96038d3ad1a46dece'],
    shim: ['https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.4.2/+esm',
           'c625d3c4188c87b9a510f89aee0890e345e6b32c50759860edda9062ed40f30d'],
    wasm: ['https://cdn.jsdelivr.net/npm/@ruby/4.0-wasm-wasi@2.10.1/dist/ruby+stdlib.wasm',
           '9fe3c749730a16da9b0d1a973bb77bec164f8d958efcb7f5b81e4275ea8c5439']
  }.freeze

  module_function

  def build(directory = 'site/vendor')
    FileUtils.mkdir_p(directory)
    Dir.mktmpdir('railroad-wasm') do |temporary|
      files = ASSETS.each_with_object({}) do |(name, (url, digest)), paths|
        path = File.join(temporary, name.to_s)
        raise "could not download #{url}" unless system('curl', '-fsSL', '--retry', '3', url, '-o', path)
        raise "checksum mismatch for #{url}" unless Digest::SHA256.file(path).hexdigest == digest

        paths[name] = path
      end
      browser = File.read(files.fetch(:browser))
      replaced = browser.sub!(%r{/npm/@bjorn3/browser_wasi_shim@0\.4\.2/\+esm}, './browser_wasi_shim.mjs')
      raise 'unexpected ruby.wasm browser import' unless replaced

      File.write(File.join(directory, 'ruby-wasm-browser.mjs'), browser)
      FileUtils.cp(files.fetch(:shim), File.join(directory, 'browser_wasi_shim.mjs'))
      FileUtils.cp(files.fetch(:wasm), File.join(directory, 'ruby+stdlib.wasm'))
    end
  end
end

PlaygroundVendor.build(ARGV.fetch(0, 'site/vendor')) if $PROGRAM_NAME == __FILE__
