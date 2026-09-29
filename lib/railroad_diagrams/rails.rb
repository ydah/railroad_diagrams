# frozen_string_literal: true

require 'railroad_diagrams'
require 'active_support'
require 'active_support/core_ext/string/output_safety'

module RailroadDiagrams
  # Rails view integration, loaded only when required explicitly.
  # @example
  #   require 'railroad_diagrams/rails'
  module Rails
    # Adds `railroad_diagram` to Action View.
    # @example
    #   railroad_diagram { seq('SELECT', :table) }
    module Helper
      def railroad_diagram(**options, &dsl)
        raise InvalidArgument, 'railroad_diagram requires a block' unless dsl

        title = options.delete(:title)
        desc = options.delete(:desc)
        Diagram.new(RailroadDiagrams.build(&dsl), title: title, desc: desc).to_svg(**options).html_safe
      end
    end
  end
end

ActiveSupport.on_load(:action_view) { include RailroadDiagrams::Rails::Helper }
