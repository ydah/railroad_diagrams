# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Optional < Choice
    # @rbs item: DiagramItem | String
    # @rbs skip: bool
    # @rbs return: void
    def initialize(item, legacy_skip = Deprecation::UNSET, skip: Deprecation::UNSET,
                   id: nil, cls: nil, attrs: {})
      skip = Deprecation.positional_argument('skip', legacy_skip, skip, false)
      super(skip ? 0 : 1, Skip.new, item, id: id, cls: cls, attrs: attrs)
    end
  end
end
