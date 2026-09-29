require 'spec_helper'
require 'railroad_diagrams/link_policy'
require 'rexml/document'

RSpec.describe RailroadDiagrams::LinkPolicy do
  it 'renders one linked label and puts its title first for each label node' do
    [RailroadDiagrams::Terminal, RailroadDiagrams::NonTerminal, RailroadDiagrams::Comment].each do |type|
      diagram = RailroadDiagrams::Diagram.new(type.new('label', 'https://example.com', 'Hint'))
      group = REXML::Document.new(diagram.to_svg).get_elements('//g[@class]').last
      expect(group.elements[1].name).to eq('title')
      expect(group.get_elements('a/text').map(&:text)).to eq(['label'])
    end
  end

  describe '.allowed?' do
    it 'allows HTTP, HTTPS, mail, relative paths, and fragments' do
      urls = ['https://example.com/a', 'HTTP://example.com/a', 'mailto:a@example.com',
              '/docs/日本語', './page', '../page', 'page?q=1', '?q=1', '#section']
      expect(urls.map { |url| described_class.allowed?(url) }).to eq([true] * urls.length)
    end

    it 'rejects active or malformed URLs in safe mode' do
      urls = ['javascript:alert(1)', 'JaVaScRiPt:alert(1)', 'data:text/html,x',
              'file:///tmp/x', 'ftp://example.com', '//example.com/x',
              'https:example.com', '', "java\nscript:alert(1)", '/\\example.com']
      expect(urls.map { |url| described_class.allowed?(url) }).to eq([false] * urls.length)
    end

    it 'lets allow_all preserve legacy links and accepts a custom Proc' do
      expect(described_class.allowed?('javascript:alert(1)', policy: :allow_all)).to be true
      policy = ->(url) { url.start_with?('#') }
      expect(described_class.allowed?('#anchor', policy: policy)).to be true
      expect(described_class.allowed?('/page', policy: policy)).to be false
    end

    it 'rejects unsupported policies and non-string URLs' do
      expect { described_class.allowed?('/page', policy: :unknown) }.to raise_error(RailroadDiagrams::InvalidArgument)
      expect { described_class.allowed?(nil) }.to raise_error(RailroadDiagrams::InvalidArgument)
    end
  end
end
