# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class CharClass < Terminal
    def initialize(text, href: nil, title: nil, cls: '', **options)
      @semantic_cls = cls
      super(text, href: href, title: title, cls: ['char-class', cls].reject(&:empty?).join(' '), **options)
    end

    def to_s
      "CharClass(#{@text})"
    end

    def to_h
      result = { 'type' => 'char_class', 'text' => @text }
      result['href'] = @href if @href
      result['title'] = @title if @title
      Serialization.add_attributes(result, self)
      @semantic_cls.empty? ? result.delete('cls') : result['cls'] = @semantic_cls
      result
    end
  end
end
