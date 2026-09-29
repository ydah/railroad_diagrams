# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # A diagram with complex start and end markers.
  # @example
  #   ComplexDiagram.new('expression')
  class ComplexDiagram
    def self.new(*items, **options)
      Diagram.new(*items, type: 'complex', **options)
    end
  end
end
