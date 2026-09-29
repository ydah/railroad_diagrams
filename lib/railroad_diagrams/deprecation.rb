# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  module Deprecation
    UNSET = Object.new.freeze
    @seen = {}
    @mutex = Mutex.new

    class << self
      def positional_argument(name, legacy, keyword, default = nil)
        return keyword.equal?(UNSET) ? default : keyword if legacy.equal?(UNSET)

        raise InvalidArgument, "#{name} specified twice" unless keyword.equal?(UNSET)

        warn("positional #{name} is deprecated; use #{name}:", uplevel: 2)
        legacy
      end

      # @rbs message: String
      # @rbs uplevel: Integer
      # @rbs return: void
      def warn(message, uplevel: 1)
        mode = ENV.fetch('RAILROAD_DIAGRAMS_DEPRECATION', 'warn')
        return if mode == 'silent'
        raise InvalidArgument, "[railroad_diagrams] #{message}" if mode == 'raise'

        location = caller_locations(uplevel + 1, 1).first
        key = [message, location && location.path, location && location.lineno]
        return unless @mutex.synchronize { @seen[key] ? false : (@seen[key] = true) }

        Kernel.warn("[railroad_diagrams] DEPRECATION: #{message} (#{location})")
      end
    end
  end
end
