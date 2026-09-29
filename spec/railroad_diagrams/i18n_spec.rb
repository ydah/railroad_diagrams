require 'spec_helper'
require 'railroad_diagrams/i18n'

RSpec.describe RailroadDiagrams::I18n do
  describe '.t' do
    it 'preserves the existing English MultipleChoice tooltips' do
      expect(described_class.t(:multiple_choice_any_tooltip)).to eq('take one or more branches, once each, in any order')
      expect(described_class.t(:multiple_choice_all_tooltip)).to eq('take all branches, once each, in any order')
    end

    it 'returns Japanese tooltips and description phrases' do
      expect(described_class.t(:multiple_choice_any_tooltip, locale: :ja)).to eq('1つ以上の分岐を、それぞれ1回ずつ、任意の順序で通る')
      expect(described_class.t(:describe_sequence, locale: :ja, items: '「SELECT」、省略可能な「DISTINCT」'))
        .to eq('順に: 「SELECT」、省略可能な「DISTINCT」')
      expect(described_class.t(:describe_optional, locale: :ja, item: '「DISTINCT」')).to eq('省略可能な「DISTINCT」')
    end

    it 'formats the documented repeat labels' do
      expect(described_class.t(:repeat_exact, count: 3)).to eq('3 times')
      expect(described_class.t(:repeat_range, min: 2, max: 5)).to eq('2–5 times')
      expect(described_class.t(:repeat_min, min: 2)).to eq('2+ times')
      expect(described_class.t(:repeat_exact, locale: :ja, count: 3)).to eq('3回')
      expect(described_class.t(:repeat_range, locale: :ja, min: 2, max: 5)).to eq('2〜5回')
      expect(described_class.t(:repeat_min, locale: :ja, min: 2)).to eq('2回以上')
    end

    it 'rejects unknown locales, keys, and interpolation arguments' do
      expect { described_class.t(:describe_sequence, locale: :fr, items: 'A') }.to raise_error(RailroadDiagrams::InvalidArgument)
      expect { described_class.t(:missing) }.to raise_error(RailroadDiagrams::InvalidArgument)
      expect { described_class.t(:repeat_exact) }.to raise_error(RailroadDiagrams::InvalidArgument)
      expect { described_class.t(:repeat_exact, count: 2, unused: 1) }.to raise_error(RailroadDiagrams::InvalidArgument)
    end

    it 'inserts values as text without interpreting format tokens in them' do
      # rubocop:disable-next Style/FormatStringToken
      expect(described_class.t(:describe_terminal, text: '%{danger}')).to eq('“%{danger}”')
    end
  end
end
