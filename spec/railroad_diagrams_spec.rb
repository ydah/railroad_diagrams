require 'spec_helper'

RSpec.describe RailroadDiagrams do
  describe 'Constants' do
    it 'has VS constant' do
      expect(described_class::VS).to eq(8)
    end

    it 'has AR constant' do
      expect(described_class::AR).to eq(10)
    end

    it 'has DIAGRAM_CLASS constant' do
      expect(described_class::DIAGRAM_CLASS).to eq('railroad-diagram')
    end

    it 'has STROKE_ODD_PIXEL_LENGTH constant' do
      expect(described_class::STROKE_ODD_PIXEL_LENGTH).to be true
    end

    it 'has INTERNAL_ALIGNMENT constant' do
      expect(described_class::INTERNAL_ALIGNMENT).to eq('center')
    end

    it 'has CHAR_WIDTH constant' do
      expect(described_class::CHAR_WIDTH).to eq(8.5)
    end

    it 'has COMMENT_CHAR_WIDTH constant' do
      expect(described_class::COMMENT_CHAR_WIDTH).to eq(7)
    end
  end

  describe '.escape_attr' do
    it 'escapes ampersands' do
      expect(described_class.escape_attr('foo&bar')).to eq('foo&amp;bar')
    end

    it 'escapes single quotes' do
      expect(described_class.escape_attr("foo'bar")).to eq('foo&apos;bar')
    end

    it 'escapes double quotes' do
      expect(described_class.escape_attr('foo"bar')).to eq('foo&quot;bar')
    end

    it 'escapes all special characters' do
      expect(described_class.escape_attr(%q{a&b'c"d})).to eq('a&amp;b&apos;c&quot;d')
    end

    it 'converts numeric values to string' do
      expect(described_class.escape_attr(42)).to eq('42')
      expect(described_class.escape_attr(3.14)).to eq('3.14')
    end

    it 'returns string unchanged if no special characters' do
      expect(described_class.escape_attr('hello')).to eq('hello')
    end
  end

  describe '.escape_html' do
    it 'escapes ampersands' do
      expect(described_class.escape_html('foo&bar')).to eq('foo&amp;bar')
    end

    it 'escapes single quotes' do
      expect(described_class.escape_html("foo'bar")).to eq('foo&apos;bar')
    end

    it 'escapes double quotes' do
      expect(described_class.escape_html('foo"bar')).to eq('foo&quot;bar')
    end

    it 'escapes less than' do
      expect(described_class.escape_html('foo<bar')).to eq('foo&lt;bar')
    end

    it 'escapes all special characters' do
      expect(described_class.escape_html(%q{a&b'c"d<e})).to eq('a&amp;b&apos;c&quot;d&lt;e')
    end

    it 'returns string unchanged if no special characters' do
      expect(described_class.escape_html('hello')).to eq('hello')
    end
  end
end
