# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class Except < DiagramItem
    include ExpandedNode

    def initialize(item, excluded, label: :auto, id: nil, cls: nil, attrs: {})
      super('g', id: id, cls: cls, data_attrs: attrs)
      raise InvalidArgument, 'excluded must be a String or diagram node' unless excluded.is_a?(String) || excluded.is_a?(DiagramItem)
      raise InvalidArgument, 'label must be :auto, nil, or a String' unless label == :auto || label.nil? || label.is_a?(String)

      @item = wrap_string(item)
      @excluded = excluded
      @label = label
      adopt_expansion(build_group(:en))
      @japanese = build_group(:ja) if label == :auto
    end

    def to_s
      "Except(#{@item}, #{@excluded}, label=#{@label.inspect})"
    end

    def child_nodes
      [@item, *(@excluded.is_a?(DiagramItem) ? [@excluded] : [])]
    end

    def to_h
      excluded = @excluded.is_a?(DiagramItem) ? @excluded.to_h : @excluded
      Serialization.add_attributes(
        { 'type' => 'except', 'item' => @item.to_h, 'excluded' => excluded,
          'label' => @label == :auto ? { 'auto' => true } : @label }, self
      )
    end

    private

    def expanded(context = nil)
      context && context.options.locale == :ja && @japanese ? @japanese : @expanded
    end

    def build_group(locale)
      label = if @label == :auto
                value = @excluded.is_a?(DiagramItem) ? A11y::Describer.call(@excluded, locale: locale) : @excluded
                locale == :ja ? "#{value}を除く" : "except #{value}"
              else
                @label
              end
      Group.new(@item, label: label)
    end
  end
end
