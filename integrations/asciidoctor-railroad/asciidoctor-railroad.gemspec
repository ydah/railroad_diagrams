# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'asciidoctor-railroad'
  spec.version = '0.1.0'
  spec.summary = 'Railroad diagram blocks for Asciidoctor'
  spec.authors = ['Yudai Takada']
  spec.homepage = 'https://github.com/ydah/railroad_diagrams'
  spec.license = 'MIT'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.5'
  spec.files = Dir.chdir(__dir__) { Dir['lib/**/*.rb', 'README.md', 'LICENSE.txt', 'sample/**/*'].select { |path| File.file?(path) } }
  spec.require_paths = ['lib']

  spec.add_dependency 'asciidoctor', '>= 2.0'
  spec.add_dependency 'railroad_diagrams', '>= 1.0.0'
end
