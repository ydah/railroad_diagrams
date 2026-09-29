# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailroadDiagrams::Error do
  it 'catches invalid arguments and parse errors' do
    expect { RailroadDiagrams::Choice.new(-1, 'a') }.to raise_error(RailroadDiagrams::Error)
    expect { raise RailroadDiagrams::ParseError, 'bad grammar' }.to raise_error(RailroadDiagrams::Error)
  end

  it 'uses a consistent argument error for invalid AlternatingSequence arity' do
    expect { RailroadDiagrams::AlternatingSequence.new('a') }.to raise_error(RailroadDiagrams::InvalidArgument)
  end

  it 'can turn a deprecation into an error' do
    previous = ENV['RAILROAD_DIAGRAMS_DEPRECATION']
    ENV['RAILROAD_DIAGRAMS_DEPRECATION'] = 'raise'
    expect { RailroadDiagrams::Deprecation.warn('old form') }.to raise_error(RailroadDiagrams::InvalidArgument, /old form/)
  ensure
    ENV['RAILROAD_DIAGRAMS_DEPRECATION'] = previous
  end
end
