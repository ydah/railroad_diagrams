# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'keyword arguments' do
  let(:rd) { RailroadDiagrams }

  around do |example|
    previous = ENV['RAILROAD_DIAGRAMS_DEPRECATION']
    ENV['RAILROAD_DIAGRAMS_DEPRECATION'] = 'warn'
    example.run
  ensure
    ENV['RAILROAD_DIAGRAMS_DEPRECATION'] = previous
  end

  it 'accepts keyword links, titles, labels, and skip flags' do
    expect(rd::Terminal.new('a', href: '#a', title: 'A').instance_variable_get(:@href)).to eq('#a')
    expect(rd::NonTerminal.new('a', href: '#a').instance_variable_get(:@href)).to eq('#a')
    expect(rd::Comment.new('a', title: 'A').instance_variable_get(:@title)).to eq('A')
    expect(rd::Group.new('a', label: 'rule').child_nodes.last).to be_a(rd::Comment)
    expect(rd::Optional.new('a', skip: true).instance_variable_get(:@default)).to eq(0)
    expect(rd::ZeroOrMore.new('a', ',', skip: true).instance_variable_get(:@default)).to eq(0)
  end

  it 'rejects positional and keyword values for the same argument' do
    expect { rd::Terminal.new('a', '#old', href: '#new') }.to raise_error(rd::InvalidArgument)
    expect { rd::Group.new('a', 'old', label: 'new') }.to raise_error(rd::InvalidArgument)
    expect { rd::Optional.new('a', true, skip: false) }.to raise_error(rd::InvalidArgument)
  end

  it 'warns for positional link, label, and skip arguments' do
    expect { rd::Terminal.new('a', '#old') }.to output(/DEPRECATION/).to_stderr
    expect { rd::Group.new('a', 'old') }.to output(/DEPRECATION/).to_stderr
    expect { rd::Optional.new('a', true) }.to output(/DEPRECATION/).to_stderr
  end

  it 'keeps a trailing positional Hash as a legacy href' do
    node = rd::Terminal.new('a', { 'x' => 1 })
    expect(node.instance_variable_get(:@href)).to eq('x' => 1)
  end
end
