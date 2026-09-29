# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # Draws zero or more occurrences of an item.
  # @example
  #   ZeroOrMore.new('digit')
  class ZeroOrMore < Optional
    # @rbs item: DiagramItem | String
    # @rbs repeat: (DiagramItem | String)?
    # @rbs skip: bool
    # @rbs return: void
    # rubocop:disable-next Metrics/ParameterLists
    def initialize(item, repeat = nil, legacy_skip = Deprecation::UNSET, skip: Deprecation::UNSET,
                   id: nil, cls: nil, attrs: {})
      skip = Deprecation.positional_argument('skip', legacy_skip, skip, false)
      super(OneOrMore.new(item, repeat), skip: skip, id: id, cls: cls, attrs: attrs)
    end
  end
end
