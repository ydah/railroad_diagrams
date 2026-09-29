# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Optional < DiagramMultiContainer
    # @rbs item: DiagramItem | String
    # @rbs skip: bool
    # @rbs return: Choice
    def self.new(item, skip = false, id: nil, cls: nil, attrs: {})
      Choice.new(skip ? 0 : 1, Skip.new, item, id: id, cls: cls, attrs: attrs)
    end
  end
end
