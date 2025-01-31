# frozen_string_literal: true

module RailroadDiagrams
  class DiagramMultiContainer < DiagramItem
    def initialize(name, items, attrs = nil, text = nil)
      super(name, attrs:, text:)
      @items = items.map { |item| wrap_string(item) }
    end

    def format(x, y, width)
      raise NotImplementedError
    end

    def walk(callback)
      callback(self)
      @items.each { |item| item.walk(callback) }
    end

    def to_str
      "DiagramMultiContainer(#{@name}, #{@items}, #{@attrs}, #{@children})"
    end
  end
end
