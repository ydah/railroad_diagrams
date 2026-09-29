# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class ZeroOrMore < Optional
    # @rbs item: DiagramItem | String
    # @rbs repeat: (DiagramItem | String)?
    # @rbs skip: bool
    # @rbs return: void
    def initialize(item, repeat = nil, legacy_skip = Deprecation::UNSET, skip: Deprecation::UNSET,
                   id: nil, cls: nil, attrs: {})
      skip = Deprecation.positional_argument('skip', legacy_skip, skip, false)
      super(OneOrMore.new(item, repeat), skip: skip, id: id, cls: cls, attrs: attrs)
    end
  end
end
