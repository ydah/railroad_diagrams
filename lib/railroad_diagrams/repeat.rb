# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # Draws a repetition with minimum and optional maximum counts.
  # @example
  #   Repeat.new('digit', min: 2, max: 4)
  class Repeat < DiagramItem
    include ExpandedNode

    # rubocop:disable-next Metrics/ParameterLists
    def initialize(item, min: 1, max: nil, separator: nil, label: :auto, id: nil, cls: nil, attrs: {})
      super('g', id: id, cls: cls, data_attrs: attrs)
      raise InvalidArgument, 'min must be a non-negative integer' unless min.is_a?(Integer) && min >= 0
      raise InvalidArgument, 'max must be an integer greater than or equal to min' unless max.nil? || (max.is_a?(Integer) && max >= min)
      raise InvalidArgument, 'label must be :auto, nil, or a String' unless label == :auto || label.nil? || label.is_a?(String)

      @item = wrap_string(item)
      @separator = separator.nil? ? nil : wrap_string(separator)
      @min = min
      @max = max
      @label = label
      adopt_expansion(build_repeat(:en))
      @japanese = build_repeat(:ja) if label == :auto && count_label(:en)
    end

    def to_s
      "Repeat(#{@item}, min=#{@min}, max=#{@max}, separator=#{@separator}, label=#{@label.inspect})"
    end

    def child_nodes
      @separator ? [@item, @separator] : [@item]
    end

    def to_h
      Serialization.add_attributes(
        { 'type' => 'repeat', 'item' => @item.to_h, 'min' => @min, 'max' => @max,
          'separator' => @separator&.to_h, 'label' => @label == :auto ? { 'auto' => true } : @label }, self
      )
    end

    private

    def expanded(context = nil)
      context && context.options.locale == :ja && @japanese ? @japanese : @expanded
    end

    def build_repeat(locale)
      return Skip.new if @max&.zero?
      return @min.zero? ? Optional.new(@item) : @item if @max == 1

      label = @label == :auto ? count_label(locale) : @label
      repeat = if label
                 Sequence.new(Comment.new(label), @separator || Skip.new)
               else
                 @separator
               end
      node = OneOrMore.new(@item, repeat)
      @min.zero? ? Optional.new(node) : node
    end

    def count_label(locale)
      if @max && @min == @max
        I18n.t(:repeat_exact, locale: locale, count: @min)
      elsif @max
        I18n.t(:repeat_range, locale: locale, min: @min, max: @max)
      elsif @min > 1
        I18n.t(:repeat_min, locale: locale, min: @min)
      end
    end
  end
end
