# frozen_string_literal: true

require 'spec_helper'
require 'railroad_diagrams/theme'

RSpec.describe RailroadDiagrams::Theme do
  it 'preserves the legacy default CSS byte for byte without variables' do
    expect(described_class[:default].css(css_variables: false)).to eq(RailroadDiagrams::Style.default_style)
  end

  it 'provides frozen tokens for every theme' do
    %i[default classic dark auto print high_contrast].each do |name|
      theme = described_class[name]
      expect(theme.name).to eq(name)
      expect(theme.tokens).to be_frozen
      expect(theme.tokens).to include('--rr-bg', '--rr-stroke', '--rr-text', '--rr-font')
    end
  end

  it 'renders CSS variables and direct values' do
    theme = described_class[:dark]
    expect(theme.css).to include('--rr-bg: #1e1e1e;', 'var(--rr-bg)', 'var(--rr-terminal-fill)')
    direct = theme.css(css_variables: false)
    expect(direct).to include('background-color: #1e1e1e;', 'fill: hsl(190, 60%, 30%);')
    expect(direct).not_to include('var(')
  end

  it 'uses the upstream palette for classic and monochrome fills for print' do
    expect(described_class[:classic].css(css_variables: false)).to include('background-color: hsl(30,20%,95%);')
    expect(described_class[:print].css(css_variables: false)).to include('fill: none;')
    expect(described_class[:high_contrast].css(css_variables: false)).to include('stroke-width:4;')
  end

  it 'switches the auto palette with a dark color scheme media query' do
    css = described_class[:auto].css
    expect(css).to include('@media (prefers-color-scheme: dark)', '--rr-bg: #1e1e1e;')
    direct = described_class[:auto].css(css_variables: false)
    expect(direct).to include('@media (prefers-color-scheme: dark)', 'background-color: #1e1e1e;')
    expect(direct).not_to include('var(')
  end

  it 'rejects unknown theme names' do
    expect { described_class[:missing] }.to raise_error(RailroadDiagrams::InvalidArgument, /unknown theme/)
  end
end
