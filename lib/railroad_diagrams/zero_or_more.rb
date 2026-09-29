# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class ZeroOrMore
    # @rbs item: DiagramItem | String
    # @rbs repeat: (DiagramItem | String)?
    # @rbs skip: bool
    # @rbs return: Choice
    def self.new(item, repeat = nil, skip = false, id: nil, cls: nil, attrs: {})
      Optional.new(OneOrMore.new(item, repeat), skip, id: id, cls: cls, attrs: attrs)
    end
  end
end
