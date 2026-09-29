# frozen_string_literal: true

require 'spec_helper'
require 'railroad_diagrams/importers/w3c_ebnf'

RSpec.describe RailroadDiagrams::Importers::W3cEbnf do
  let(:parser) { described_class::Parser }

  it 'keeps token positions across newlines and skips comments and constraints' do
    tokens = described_class::Lexer.new("/* note */\n[1] a ::= #x20 [ wfc: note ] 'x'").tokens
    expect(tokens.map(&:type)).to eq(%i[comment rule_number name define hex_char constraint string eof])
    expect(tokens[2].line).to eq(2)
    expect(tokens[2].column).to eq(5)
    expect(tokens[4].value).to eq('#x20')
  end

  it 'parses adjacent rules independent of line boundaries' do
    rules = parser.new("a ::= 'x' b ::= a+\n[2] c ::= b?").parse
    expect(rules.map(&:name)).to eq(%w[a b c])
    expect(rules[1].expression).to eq([:one_or_more, [:name, 'a']])
  end

  it 'binds postfix, difference, sequence, then choice' do
    rule = parser.new("a ::= Char - ('*' | '/') item+ | #x20").parse.first
    expect(rule.expression).to eq(
      [:choice, [
        [:sequence, [
          [:except, [:name, 'Char'], [:choice, [[:string, '*'], [:string, '/']]]],
          [:one_or_more, [:name, 'item']]
        ]],
        [:hex_char, '#x20']
      ]]
    )
  end

  it 'reports filename, line, column, source and caret for syntax errors' do
    expect { parser.new("ok ::= 'x'\nbad ::= ('x' | )", filename: 'broken.ebnf').parse }
      .to raise_error(RailroadDiagrams::ParseError) { |error|
        expect(error.message).to include('broken.ebnf:2:16:')
        expect(error.message).to include("bad ::= ('x' | )\n                 ^")
        expect(error.line).to eq(2)
        expect(error.column).to eq(16)
        expect(error.source_line).to eq("bad ::= ('x' | )")
      }
  end

  it 'rejects duplicate rules and unterminated tokens with a position' do
    expect { parser.new("a ::= 'x'\na ::= 'y'").parse }
      .to raise_error(RailroadDiagrams::ParseError, /<input>:2:1: duplicate rule/)
    expect { parser.new('a ::= [^a').parse }
      .to raise_error(RailroadDiagrams::ParseError, /<input>:1:7: unterminated char_class/)
    expect { parser.new('a ::= #x').parse }
      .to raise_error(RailroadDiagrams::ParseError, /<input>:1:7: expected hexadecimal digits/)
  end

  it 'imports arithmetic, JSON and SQL fixtures into a document' do
    { 'arithmetic' => 4, 'json' => 5, 'sql' => 8 }.each do |name, count|
      filename = File.expand_path("../../fixtures/ebnf/#{name}.ebnf", __dir__)
      document = described_class.parse(File.read(filename), filename: filename)
      expect(document).to be_a(RailroadDiagrams::Document)
      expect(document.rules.length).to eq(count)
      expect(document.rules.first[1]).to be_a(RailroadDiagrams::DiagramItem)
    end
  end

  it 'maps XML-style subtraction and character classes to their diagram nodes' do
    document = described_class.parse("Char ::= [#x20-#xD7FF]\nCharData ::= Char - ('<' | '&')")
    expect(document.rules[0][1]).to be_a(RailroadDiagrams::CharClass)
    expect(document.rules[1][1]).to be_a(RailroadDiagrams::Except)
  end

  it 'simplifies on request and links defined references in HTML' do
    document = described_class.parse("entry ::= value | value\nvalue ::= 'x'", simplify: true)
    expect(document.rules[0][1]).to be_a(RailroadDiagrams::NonTerminal)
    expect(document.to_html).to include('href="#rule-value"')
  end

  it 'passes the current rule name to direct left-recursion simplification' do
    document = described_class.parse("item ::= item 'b' | 'a'", simplify: true)
    expect(document.rules.first.last).to be_a(RailroadDiagrams::Sequence)
    expect(document.rules.first.last.each_node.grep(RailroadDiagrams::NonTerminal)).to be_empty
  end

  if ENV['EBNF_NETWORK'] == '1'
    # rubocop:disable-next RSpec/ExampleLength
    it 'imports the full XML 1.0 Fifth Edition grammar from W3C' do
      require 'net/http'
      require 'rexml/document'
      require 'rexml/xpath'
      require 'tmpdir'

      cache = File.join(Dir.tmpdir, 'railroad-xml-1.0-fifth-edition.xml')
      source = File.exist?(cache) ? File.read(cache) : Net::HTTP.get(URI('https://www.w3.org/TR/xml/REC-xml-20081126.xml'))
      File.write(cache, source) unless File.exist?(cache)
      xml = REXML::Document.new(source)
      flatten = nil
      flatten = lambda do |element|
        if element.is_a?(REXML::Text)
          element.value
        elsif element.respond_to?(:children)
          element.children.map { |child| flatten.call(child) }.join
        else
          ''
        end
      end
      grammar = REXML::XPath.match(xml, '//prod').map do |production|
        name = flatten.call(production.elements['lhs']).strip
        rhs = flatten.call(production.elements['rhs']).gsub(/[\r\n\t]+/, ' ').strip
        "[#{production.attributes['num']}] #{name} ::= #{rhs}"
      end.join("\n")

      document = described_class.parse(grammar, filename: 'xml-1.0.ebnf')
      expect(document.rules.length).to eq(85)
      expect(document.rules.assoc('CharData')[1]).to be_a(RailroadDiagrams::Except)
      expect(document.to_html).to include('id="rule-chardata"')
    end
  end
end
