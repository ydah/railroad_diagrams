# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class SeparatedList < DiagramItem
    include ExpandedNode

    # rubocop:disable-next Metrics/ParameterLists
    def initialize(item, separator, min: 1, trailing: false, id: nil, cls: nil, attrs: {})
      super('g', id: id, cls: cls, data_attrs: attrs)
      raise InvalidArgument, 'min must be a non-negative integer' unless min.is_a?(Integer) && min >= 0
      raise InvalidArgument, 'trailing must be a boolean' unless [true, false].include?(trailing)

      @item = wrap_string(item)
      @separator = wrap_string(separator)
      @min = min
      @trailing = trailing
      repeated = min > 1 ? Repeat.new(@item, min: min, separator: @separator) : OneOrMore.new(@item, @separator)
      repeated = Sequence.new(repeated, Optional.new(@separator)) if trailing
      adopt_expansion(min.zero? ? Optional.new(repeated) : repeated)
    end

    def to_s
      "SeparatedList(#{@item}, #{@separator}, min=#{@min}, trailing=#{@trailing})"
    end

    def child_nodes
      [@item, @separator]
    end

    def to_h
      Serialization.add_attributes(
        { 'type' => 'separated_list', 'item' => @item.to_h, 'separator' => @separator.to_h,
          'min' => @min, 'trailing' => @trailing }, self
      )
    end
  end
end
