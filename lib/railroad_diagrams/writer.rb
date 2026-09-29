# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Writer
    module_function

    # @rbs target: untyped
    # @rbs return: ^(String) -> void
    def wrap(target)
      return target if target.respond_to?(:call)
      return ->(s) { target.write(s) } if target.respond_to?(:write)
      return ->(s) { target << s } if target.respond_to?(:<<)

      raise InvalidArgument, "writer must respond to #call, #write or #<<: #{target.inspect}"
    end
  end
end
