# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  class ComplexDiagram
    def self.new(*items, **options)
      Diagram.new(*items, type: 'complex', **options)
    end
  end
end
