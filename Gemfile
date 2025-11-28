# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake"
gem 'rspec'
gem 'simplecov', require: false

if !ENV['GITHUB_ACTION'] || ENV['INSTALL_STEEP'] == 'true'
  gem 'rbs', require: false
  gem 'rbs-inline', require: false
  gem 'steep', require: false
end
