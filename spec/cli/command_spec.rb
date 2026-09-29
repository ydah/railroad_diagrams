# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'tmpdir'
require 'rbconfig'
require 'fileutils'
require 'timeout'
require 'railroad_diagrams/cli/command'

# rubocop:disable-next RSpec/SpecFilePathFormat
RSpec.describe RailroadDiagrams::CLI::Command do
  let(:executable) { File.expand_path('../../exe/railroad_diagrams', __dir__) }
  let(:directory) { Dir.mktmpdir('railroad-cli') }

  after(:each) do
    FileUtils.remove_entry(directory)
  end

  def file(name, contents)
    path = File.join(directory, name)
    File.write(path, contents)
    path
  end

  def run_cli(*args, stdin_data: nil)
    Open3.capture3({ 'RUBYOPT' => coverage_rubyopt, 'BUNDLE_GEMFILE' => nil }, RbConfig.ruby, executable, *args,
                   stdin_data: stdin_data, chdir: directory)
  end

  def coverage_rubyopt
    "-r#{File.expand_path('../coverage_boot.rb', __dir__)}" if ENV['COVERAGE']
  end

  it 'shows subcommands and warns that Ruby input executes code' do
    stdout, stderr, status = run_cli('--help')
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include('render', 'demo', 'themes', 'version', '.rb input executes arbitrary Ruby code')
    expect(stderr).to eq('')
  end

  it 'keeps the old demo command with one deprecation warning' do
    stdout, stderr, status = run_cli('--format=svg', 'rr-sequence')
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include('<html>', '<svg', 'rr-sequence')
    expect(stderr.scan(/deprecated/i).length).to eq(1)
  end

  it 'renders YAML rules to linked HTML with lint messages' do
    source = file('grammar.yml', "rules:\n  start: ['a', '<missing>']\n")
    stdout, stderr, status = run_cli('render', source, '--format', 'html', '--lint')
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include('id="rule-start"', 'undefined rule: missing')
    expect(stderr).to include('undefined rule: missing')
  end

  it 'renders EBNF, JSON and Ruby inputs' do
    ebnf = file('grammar.ebnf', "entry ::= 'a' | 'b'\n")
    json = file('token.json', '{"type":"terminal","text":"JSON"}')
    ruby = file('token.rb', "seq 'Ruby', :name\n")
    [
      [ebnf, 'entry', 'a'], [json, 'token', 'JSON'], [ruby, 'token', 'Ruby']
    ].each do |path, name, text|
      stdout, stderr, status = run_cli('render', path, '--format', 'text')
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include(name, text)
      expect(stderr).to eq('')
    end
  end

  it 'selects the text character set' do
    source = file('grammar.yml', "rules:\n  entry:\n    - {optional: a}\n    - {one_or_more: b}\n")
    stdout, stderr, status = run_cli('render', source, '--format', 'text', '--charset', 'ascii')
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include('entry:', 'a', 'b')
    expect(stdout).to be_ascii_only
    expect(stderr).to eq('')
  end

  it 'renders a JSON grammar document and rejects invalid metadata' do
    source = file('grammar.json', '{"title":"Names","rules":{"name":{"type":"terminal","text":"Alice"}}}')
    stdout, _, status = run_cli('render', source, '--format', 'html')
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include('<title>Names</title>', 'Alice')

    broken = file('bad.json', '{"title":42,"rules":{"name":{"type":"terminal","text":"Alice"}}}')
    _, stderr, status = run_cli('render', broken)
    expect(status.exitstatus).to eq(1)
    expect(stderr).to include('title must be a string')
    expect(stderr).not_to include('from ')
  end

  it 'accepts standard input only with an explicit input format' do
    source = "rules:\n  entry: hello\n"
    _, stderr, status = run_cli('render', '-', stdin_data: source)
    expect(status.exitstatus).to eq(2)
    expect(stderr).to include('--input-format')

    stdout, stderr, status = run_cli('render', '-', '--input-format', 'yaml', '--format', 'svg', stdin_data: source)
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include('<svg', 'hello')
    expect(stderr).to eq('')
  end

  it 'writes selected rules into separate files' do
    source = file('grammar.ebnf', "first ::= 'a'\nsecond ::= 'b'\n")
    target = File.join(directory, 'out')
    _, stderr, status = run_cli('render', source, '--format', 'svg', '--split', '--rule', 'second', '-o', target)
    expect(status.exitstatus).to eq(0)
    expect(Dir.children(target)).to eq(['second.svg'])
    expect(File.read(File.join(target, 'second.svg'))).to include('>b<')
    expect(stderr).to eq('')
  end

  it 'writes index.html when the output is a directory' do
    source = file('grammar.yml', "rules:\n  start: hello\n")
    target = File.join(directory, 'site')
    Dir.mkdir(target)
    _, stderr, status = run_cli('render', source, '-o', target)
    expect(status.exitstatus).to eq(0)
    expect(File.read(File.join(target, 'index.html'))).to include('id="rule-start"')
    expect(stderr).to eq('')
  end

  it 'applies theme, custom CSS, width and simplification' do
    source = file('grammar.ebnf', "entry ::= 'a' | 'a'\n")
    css = file('custom.css', '.railroad-diagram { color: red; }')
    stdout, stderr, status = run_cli('render', source, '-f', 'standalone', '--theme', 'dark', '--css', css,
                                     '--max-width', '300', '--simplify')
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include('color: red', '#1e1e1e', '<svg')
    expect(stdout.scan('>a<').length).to eq(1)
    expect(stderr).to eq('')
  end

  it 'uses distinct exit codes for usage and input errors' do
    _, _, usage = run_cli('render', '--format', 'unknown')
    _, _, input = run_cli('render', file('broken.ebnf', "entry ::= ('a'\n"))
    expect(usage.exitstatus).to eq(2)
    expect(input.exitstatus).to eq(1)
  end

  it 'reports unsafe CSS as a rendering error' do
    source = file('grammar.yml', "rules:\n  start: hello\n")
    css = file('bad.css', '</StYle><script>alert(1)</script>')
    _, stderr, status = run_cli('render', source, '--css', css)
    expect(status.exitstatus).to eq(3)
    expect(stderr).to include('style')

    _, _, split_status = run_cli('render', source, '--css', css, '--split', '-o', File.join(directory, 'out'))
    expect(split_status.exitstatus).to eq(3)
  end

  # rubocop:disable-next RSpec/ExampleLength
  it 'regenerates output after a watched file changes and exits on interrupt' do
    source = file('grammar.yml', "rules:\n  start: before\n")
    output = File.join(directory, 'result.json')
    env = { 'RUBYOPT' => coverage_rubyopt, 'BUNDLE_GEMFILE' => nil }
    Open3.popen3(env, RbConfig.ruby, executable, 'render', source, '-f', 'json', '-o', output,
                 '--watch', chdir: directory) do |_input, _stdout, stderr, process|
      Timeout.timeout(10) { sleep 0.05 until File.exist?(output) }
      File.write(source, "rules:\n  start: after\n")
      Timeout.timeout(10) { sleep 0.05 until File.read(output).include?('after') }
      Process.kill('INT', process.pid)
      expect(process.value.exitstatus).to eq(0)
      expect(stderr.read).to eq('')
    ensure
      begin
        Process.kill('TERM', process.pid) if process.alive?
      rescue Errno::ESRCH
        nil
      end
    end
  end

  it 'lists themes and prints the gem version' do
    themes, _, theme_status = run_cli('themes')
    version, _, version_status = run_cli('version')
    expect(theme_status.exitstatus).to eq(0)
    expect(themes).to include('default', 'dark', 'high_contrast')
    expect(version_status.exitstatus).to eq(0)
    expect(version).to include(RailroadDiagrams::VERSION)
  end
end
