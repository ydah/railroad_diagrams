require 'simplecov'

SimpleCov.root File.expand_path('..', __dir__)
SimpleCov.command_name "cli-#{Process.pid}"
SimpleCov.coverage_dir ENV.fetch('COVERAGE_DIR', 'coverage')
SimpleCov.formatter(Class.new { def format(_result); end })
SimpleCov.start do
  enable_coverage :branch
  skip '/spec/'
end
