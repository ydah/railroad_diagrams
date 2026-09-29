# rbs_inline: enabled
# frozen_string_literal: true

require 'uri'

module RailroadDiagrams
  module LinkPolicy
    module_function

    # @rbs url: String
    # @rbs policy: (:safe | :allow_all | Proc)
    # @rbs return: bool
    def allowed?(url, policy: :safe)
      raise InvalidArgument, 'link URL must be a String' unless url.is_a?(String)

      case policy
      when :safe then safe?(url)
      when :allow_all then true
      when Proc then !!policy.call(url)
      else raise InvalidArgument, "unknown link policy: #{policy.inspect}"
      end
    end

    def safe?(url)
      return false if url.empty? || url.match?(/[[:space:][:cntrl:]\\]/)

      uri = URI.parse(URI::DEFAULT_PARSER.escape(url, /[^\x00-\x7F]/))
      case uri.scheme&.downcase
      when 'http', 'https' then !uri.host.to_s.empty?
      when 'mailto' then !uri.opaque.to_s.empty?
      when nil then uri.host.nil? && !url.start_with?('//')
      else false
      end
    rescue URI::Error
      false
    end
    private_class_method :safe?
  end
end
