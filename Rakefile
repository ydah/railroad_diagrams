# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# RSpec task
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--format documentation'
end

# rbs-inline task - Generate RBS files from inline annotations
desc 'Generate RBS files from inline annotations'
task :rbs_inline do
  sh 'bundle exec rbs-inline --output lib'
end

# Steep task - Run type checking
desc 'Run Steep type checking'
task :steep do
  sh 'bundle exec steep check'
end

# Type check task - Generate RBS and run Steep
desc 'Generate RBS files and run type checking'
task type_check: [:rbs_inline, :steep]

# Default task - Run tests and type checking
task default: [:spec, :type_check]
