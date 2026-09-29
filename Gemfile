# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake"
gem 'rspec'
gem 'simplecov', require: false
gem 'rexml', require: false
gem 'yard', require: false

if RUBY_VERSION >= '2.7'
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end

if RUBY_VERSION >= '3.3' && (!ENV['GITHUB_ACTION'] || ENV['INSTALL_STEEP'] == 'true')
  gem 'rbs', require: false
  gem 'rbs-inline', require: false
  gem 'steep', require: false
end
