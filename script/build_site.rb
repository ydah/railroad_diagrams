# frozen_string_literal: true

require 'erb'
require 'fileutils'
require_relative '../lib/railroad_diagrams'
require_relative '../spec/support/examples_loader'
require_relative 'build_playground_bundle'

module SiteBuild
  NODES = {
    'Sequence' => 'rr-sequence', 'Stack' => 'rr-stack', 'Choice' => 'rr-choice',
    'Optional' => 'rr-optional', 'OneOrMore' => 'rr-oneormore',
    'ZeroOrMore' => 'rr-zeroormore-1', 'Group' => 'rr-group',
    'HorizontalChoice' => 'rr-horizontalchoice', 'OptionalSequence' => 'rr-optionalsequence',
    'AlternatingSequence' => 'rr-alternatingsequence', 'MultipleChoice' => 'rr-multchoice',
    'Start' => 'labeled-start', 'Comment' => 'comment', 'ComplexDiagram' => 'node-complex',
    'Block' => 'node-block', 'Repeat' => 'node-repeat', 'SeparatedList' => 'node-list',
    'Except' => 'node-except', 'CharClass' => 'node-char-class', 'Special' => 'node-special',
    'Diagram' => 'node-diagram', 'Terminal' => 'node-terminal', 'NonTerminal' => 'node-non-terminal',
    'Skip' => 'node-skip', 'End' => 'node-end'
  }.freeze

  module_function

  def build(directory = 'site')
    diagrams = ExamplesLoader.load
    diagrams.merge!(
      'node-diagram' => RailroadDiagrams::Diagram.new('item'),
      'node-terminal' => RailroadDiagrams::Diagram.new(RailroadDiagrams::Terminal.new('literal')),
      'node-non-terminal' => RailroadDiagrams::Diagram.new(RailroadDiagrams::NonTerminal.new('rule')),
      'node-skip' => RailroadDiagrams::Diagram.new(RailroadDiagrams::Skip.new),
      'node-end' => RailroadDiagrams::Diagram.new(RailroadDiagrams::End.new)
    )
    template = ERB.new(File.read(File.expand_path('../docs/gallery.erb', __dir__)))
    FileUtils.mkdir_p(File.join(directory, 'themes'))
    ExamplesLoader::THEMES.each do |theme|
      samples = NODES.map do |label, name|
        diagram = diagrams.fetch(name)
        [label, diagram.to_svg(theme: theme.to_sym), diagram.to_text(charset: :unicode)]
      end
      css = RailroadDiagrams::Theme[theme].css(css_variables: false)
      prefix = '../'
      html = template.result(binding)
      File.write(File.join(directory, 'themes', "#{theme}.html"), html)
      if theme == 'default'
        prefix = ''
        File.write(File.join(directory, 'index.html'), template.result(binding))
      end
    end
    PlaygroundBundle.build(File.join(directory, 'playground_bundle.js'))
    FileUtils.cp(File.expand_path('../docs/playground.html', __dir__), File.join(directory, 'playground.html'))
    FileUtils.cp(File.expand_path('../docs/playground.js', __dir__), File.join(directory, 'playground.js'))
  end
end

SiteBuild.build(ARGV.fetch(0, 'site')) if $PROGRAM_NAME == __FILE__
