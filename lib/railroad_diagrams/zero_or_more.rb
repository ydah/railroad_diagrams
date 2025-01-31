# frozen_string_literal: true

module RailroadDiagrams
  class ZeroOrMore
    def self.new(item, repeat = nil, skip = false)
      Optional.new(OneOrMore.new(item, repeat), skip)
    end
  end
end
