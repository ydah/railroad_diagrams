# frozen_string_literal: true

require_relative 'lib/railroad_diagrams/version'

Gem::Specification.new do |spec|
  spec.name = 'railroad_diagrams'
  spec.version = RailroadDiagrams::VERSION
  spec.authors = ['Yudai Takada']
  spec.email = ['t.yudai92@gmail.com']

  spec.summary = '🛤️ A tiny Ruby+SVG library for drawing railroad syntax diagrams like JSON.org.'
  spec.description = 'Generate SVG railroad syntax diagrams, like on JSON.org.'
  spec.homepage = 'https://github.com/ydah/railroad_diagrams'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/releases"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features|sample)/}) }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
