# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'rexml/document'

RSpec.describe 'Output API' do
  let(:diagram) { RailroadDiagrams::Diagram.new('a') }

  it 'returns the same SVG as the legacy writer' do
    expected = +''
    diagram.write_svg(expected.method(:<<))
    expect(diagram.to_svg).to eq(expected)
  end

  it 'writes to an IO and returns standalone SVG' do
    io = StringIO.new
    diagram.write_standalone(io)
    expect(diagram.to_standalone_svg).to eq(io.string)
    expect(io.string).to include('<style>')
  end

  it 'renders standalone SVG with a selected theme' do
    expect(diagram.to_standalone_svg(theme: :dark)).to include('background-color: #1e1e1e;')
    expect(diagram.to_standalone_svg(theme: :auto)).to include('@media (prefers-color-scheme: dark)')
    expect(diagram.to_standalone_svg(css: false)).not_to include('<style>')
  end

  it 'renders the selected theme as inline styles without a style element' do
    diagram = RailroadDiagrams::Diagram.new(RailroadDiagrams::Terminal.new('a'),
                                            RailroadDiagrams::NonTerminal.new('b'))
    svg = diagram.to_standalone_svg(theme: :dark, inline_styles: true)
    root = REXML::Document.new(svg).root

    expect(svg).not_to include('<style>')
    expect(root.attributes['style']).to include('background-color:#1e1e1e')
    expect(root.get_elements('//rect').map { |rect| rect.attributes['style'] })
      .to include(a_string_including('hsl(190, 60%, 30%)'), a_string_including('hsl(223, 50%, 35%)'))
    expect { diagram.to_standalone_svg(css: 'rect { fill: red }', inline_styles: true) }
      .to raise_error(RailroadDiagrams::InvalidArgument, /custom CSS/)
  end

  it 'adds node dimensions and bounding boxes in debug mode' do
    svg = RailroadDiagrams::Diagram.new(RailroadDiagrams::Sequence.new('a', 'b')).to_svg(debug: true)
    document = REXML::Document.new(svg)
    expect(document.get_elements('//*[@data-type="Terminal"]').length).to eq(2)
    expect(document.get_elements('//*[@data-type="Sequence"]').length).to eq(1)
    expect(document.get_elements('//rect[@class="debug-bounds"]')).not_to be_empty
    expect(svg).to include('data-updown=')
  end

  it 'escapes node attributes and prefixes ids throughout the diagram' do
    leaf = RailroadDiagrams::Terminal.new('A', id: 'rule', attrs: { 'data-note' => '<&"' })
    sequence = RailroadDiagrams::Sequence.new(leaf, RailroadDiagrams::Skip.new(id: 'gap'),
                                              id: 'branch', cls: 'custom')
    diagram = RailroadDiagrams::Diagram.new(sequence, id: 'diagram', attrs: { 'data-kind' => 'syntax' })
    svg = diagram.to_svg(id_prefix: 'sample-')
    document = REXML::Document.new(svg)

    expect(document.get_elements('//*[@id]').map { |element| element.attributes['id'] })
      .to eq(%w[sample-diagram sample-branch sample-rule sample-gap])
    expect(document.get_elements('//*[@id="sample-rule"]').first.attributes['data-note']).to eq('<&"')
    expect(document.get_elements('//*[@id="sample-branch"]').first.attributes['class']).to include('custom')
    expect(svg).to include('data-note="&lt;&amp;&quot;"')
  end

  it 'rejects unsafe node attributes and ids' do
    expect { RailroadDiagrams::Terminal.new('A', attrs: { 'onclick' => 'run()' }) }
      .to raise_error(RailroadDiagrams::InvalidArgument)
    expect { RailroadDiagrams::Skip.new(id: 'bad id') }.to raise_error(RailroadDiagrams::InvalidArgument)
  end

  it 'renders a self-contained HTML page with escaped text alternative' do
    page = RailroadDiagrams::Diagram.new('<A&>').to_html(title: '<Syntax&>', theme: :dark)
    document = REXML::Document.new(page.sub('<!doctype html>', ''))
    expect(page).to start_with('<!doctype html>')
    expect(document.elements['html/head/title'].text).to eq('<Syntax&>')
    expect(page).to include('background-color: #1e1e1e;', '<details>', '&lt;A&amp;&gt;')
    expect(document.elements['html/body/main/svg'].name).to eq('svg')
  end

  it 'returns plain text by default and restores the selected character set' do
    RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_ASCII)
    expect(diagram.to_text).to include('─')
    expect(diagram.to_text(charset: :ascii)).to include('-')
    expect(RailroadDiagrams::TextDiagram.parts).to eq(RailroadDiagrams::TextDiagram::PARTS_ASCII)
  end

  it 'supports square corners and optional trailing-space removal' do
    diagram = RailroadDiagrams::Diagram.new(RailroadDiagrams::Choice.new(0, 'a', 'bb'))
    square = diagram.to_text(charset: :unicode_square)
    expect(square).to include('┌')
    trimmed = diagram.to_text(strip_trailing: true)
    expect(trimmed.lines).to all(satisfy { |line| line.chomp == line.chomp.rstrip })
  end

  it 'returns a Markdown code block with a safe fence length' do
    diagram = RailroadDiagrams::Diagram.new('```')
    markdown = diagram.to_markdown
    expect(markdown).to start_with("````text\n")
    expect(markdown).to end_with("````\n")
    expect(markdown).to include('```')
  end

  it 'removes unsafe links by default and can raise on policy violations' do
    node = RailroadDiagrams::Terminal.new('click', 'javascript:alert(1)')
    diagram = RailroadDiagrams::Diagram.new(node, node)
    svg = nil
    expect { svg = diagram.to_svg }.to output("railroad_diagrams: rejected link URL\n").to_stderr
    expect(svg).not_to include('<a ')
    expect { diagram.to_svg(link_policy_violation: :raise) }.to raise_error(RailroadDiagrams::InvalidArgument)
    expect(diagram.to_svg(link_policy: :allow_all)).to include('xlink:href="javascript:alert(1)"')
  end

  it 'supports SVG 2 links and protects new windows' do
    diagram = RailroadDiagrams::Diagram.new(RailroadDiagrams::Terminal.new('rule', '#rule'))
    svg = diagram.to_svg(href_mode: :both, link_target: '_blank')
    expect(svg).to include('href="#rule"', 'xlink:href="#rule"')
    expect(svg).to include('target="_blank"', 'rel="noopener noreferrer"')
  end

  it 'keeps legacy text escaping and permits plain text output' do
    diagram = RailroadDiagrams::Diagram.new('<a&b>')
    escaped = +''
    diagram.write_text(escaped)
    expect(escaped).to include('&lt;a&amp;b&gt;')
    expect(diagram.to_text).to include('<a&b>')
    plain = +''
    diagram.write_text(plain, escape_html: false)
    expect(plain).to include('<a&b>')
  end

  it 'rejects invalid writers through the shared error marker' do
    expect { diagram.write_svg(Object.new) }.to raise_error(RailroadDiagrams::Error)
    expect { diagram.to_text(charset: :unknown) }.to raise_error(RailroadDiagrams::InvalidArgument)
  end
end
