# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  Metrics = Struct.new(:width, :up, :height, :down, :needs_space, keyword_init: true)
end
