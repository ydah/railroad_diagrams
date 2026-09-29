# frozen_string_literal: true

require 'rexml/document'
require 'spec_helper'

RSpec.describe RailroadDiagrams::Document do
  let(:document) { described_class.new(title: 'Grammar <test>', theme: :auto, locale: :en) }

  before(:each) do
    document.add_rule('Root', RailroadDiagrams::Sequence.new(RailroadDiagrams::NonTerminal.new('Part'), RailroadDiagrams::Terminal.new('<end>')))
    document.add_rule('Part', RailroadDiagrams::Terminal.new('x'))
  end

  it 'renders a complete document with navigation, links, text, and references' do
    html = document.to_html
    parsed = REXML::Document.new(html)
    anchors = REXML::XPath.match(parsed, '//*[@id]').map { |element| element.attributes['id'] }
    hrefs = REXML::XPath.match(parsed, '//*[@href]').map { |element| element.attributes['href'] }

    expect(anchors).to include('rule-root', 'rule-part')
    expect(hrefs.grep(/^#rule-/)).to all(satisfy { |href| anchors.include?(href.delete_prefix('#')) })
    expect(html).to include('Grammar &lt;test&gt;', '&lt;end&gt;', '<details>')
    expect(document.rule_sections.last[:referenced_by]).to eq(['Root'])
    expect(document.rules.map(&:first)).to eq(%w[Root Part])
  end

  it 'supports definition and alphabetical indexes and optional search' do
    expect(document.to_html.index('href="#rule-root"')).to be < document.to_html.index('href="#rule-part"')
    expect(document.to_html(index: :alphabetical).index('href="#rule-part"')).to be < document.to_html(index: :alphabetical).index('href="#rule-root"')
    expect(document.to_html(interactive: false)).not_to include('<script', 'type="search"')
  end

  it 'makes duplicate and non-ASCII names into unique anchors' do
    document.add_rule('Part', RailroadDiagrams::Terminal.new('y'))
    document.add_rule('日本語', RailroadDiagrams::Terminal.new('z'))
    expect(document.rule_sections.map { |section| section[:id] }).to eq(%w[rule-root rule-part rule-part-2 rule-rule])
  end

  it 'does not change nodes passed by callers while adding links' do
    original = document.rules.first.last.child_nodes.first
    expect(original.instance_variable_get(:@href)).to be_nil
    document.to_html
    expect(original.instance_variable_get(:@href)).to be_nil
  end

  it 'escapes rule names and lists lint warnings without introducing markup' do
    document.add_rule('<missing>', RailroadDiagrams::NonTerminal.new('undefined'))
    html = document.to_html

    expect(REXML::Document.new(html)).to be_a(REXML::Document)
    expect(html).to include('&lt;missing&gt;', 'undefined rule: undefined')
    expect(html).not_to include('<missing>')
    expect(document.lint.map(&:kind)).to include(:undefined_reference)
  end
end
