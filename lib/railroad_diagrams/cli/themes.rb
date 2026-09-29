# frozen_string_literal: true

module RailroadDiagrams
  module CLI
    module Themes
      module_function

      def run
        puts Theme::THEMES.keys.join("\n")
        0
      end
    end
  end
end
