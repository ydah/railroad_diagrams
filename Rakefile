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
  sh 'bundle exec rbs-inline --output=sig/generated lib'
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

namespace :golden do
  desc 'Regenerate golden files (review the diff before committing!)'
  task :update do
    sh({ 'GOLDEN_UPDATE' => '1' }, 'bundle exec rspec spec/golden_spec.rb')
  end
end

namespace :docs do
  desc 'Copy diagram previews from the reviewed golden outputs'
  task :images do
    require 'fileutils'

    samples = %w[
      simple Group_example comment rrx2Dsequence rrx2Dstack rrx2Dchoice
      rrx2Doptional rrx2Doneormore rrx2Dzeroormorex2D1 rrx2Dgroup
      rrx2Dhorizontalchoice rrx2Doptionalsequence rrx2Dalternatingsequence
      rrx2Dmultchoice labeledx2Dstart
      nodex2Dcomplex nodex2Dblock nodex2Drepeat nodex2Dlist
      nodex2Dexcept nodex2Dcharx2Dclass nodex2Dspecial
    ]
    FileUtils.mkdir_p('docs/images')
    samples.each do |name|
      FileUtils.cp("spec/golden/#{name}/standalone.svg", "docs/images/#{name}.svg")
    end
  end
end
