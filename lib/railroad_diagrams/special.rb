# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # A special grammar symbol shown as a nonterminal-style box.
  # @example
  #   Special.new('EOF')
  class Special < NonTerminal
    def initialize(text, href: nil, title: nil, cls: '', **options)
      @semantic_cls = cls
      super(text, href: href, title: title, cls: ['special', cls].reject(&:empty?).join(' '), **options)
    end

    def to_s
      "Special(#{@text})"
    end

    def to_h
      result = { 'type' => 'special', 'text' => @text }
      result['href'] = @href if @href
      result['title'] = @title if @title
      Serialization.add_attributes(result, self)
      @semantic_cls.empty? ? result.delete('cls') : result['cls'] = @semantic_cls
      result
    end
  end
end
