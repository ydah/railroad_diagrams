# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class DiagramMultiContainer < DiagramItem
    # @rbs name: String
    # @rbs items: Array[DiagramItem | String]
    # @rbs attrs: Hash[String, String | Numeric]?
    # @rbs text: String?
    # @rbs return: void
    def initialize(name, items, attrs = nil, text = nil)
      super(name, attrs: attrs, text: text)
      @items = items.map { |item| wrap_string(item) }
    end

    # @rbs x: Numeric
    # @rbs y: Numeric
    # @rbs width: Numeric
    # @rbs return: DiagramMultiContainer
    def format(x, y, width)
      raise NotImplementedError
    end

    # @rbs callback: ^(DiagramItem) -> void
    # @rbs return: void
    def walk(callback)
      callback(self)
      @items.each { |item| item.walk(callback) }
    end

    # @rbs return: String
    def to_str
      "DiagramMultiContainer(#{@name}, #{@items}, #{@attrs}, #{@children})"
    end
  end
end
