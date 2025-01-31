# frozen_string_literal: true

module RailroadDiagrams
  class Optional < DiagramMultiContainer
    def self.new(item, skip = false)
      Choice.new(skip ? 0 : 1, Skip.new, item)
    end
  end
end
