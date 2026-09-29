# rbs_inline: enabled
# frozen_string_literal: true

module RailroadDiagrams
  # Immutable-by-convention rendering settings used by Diagram output methods.
  # @example
  #   RailroadDiagrams.default_options.merge(theme: :dark)
  Options = Struct.new(
    :vertical_separation, :arc_radius, :diagram_class, :stroke_odd_pixel_length,
    :internal_alignment, :char_width, :comment_char_width, :ambiguous_width,
    :measurer, :text_charset, :escape_html, :precision, :optimize_paths,
    :href_mode, :link_policy, :link_policy_violation, :link_target, :link_rel, :id_prefix, :debug,
    :locale, :theme, :inline_styles, :max_width, :show_start, :show_end, :coerce,
    keyword_init: true
  ) do
    # Return a copy with validated overrides.
    # @example
    #   RailroadDiagrams.default_options.merge(locale: :ja)
    def merge(**overrides)
      unknown = overrides.keys - members
      raise InvalidArgument, "unknown option(s): #{unknown.join(', ')}" unless unknown.empty?

      self.class.new(**to_h.merge(overrides)).freeze # rubocop:disable Style/KeywordArgumentsMerging
    end
  end

  DEFAULT_OPTIONS = Options.new(
    vertical_separation: VS, arc_radius: AR, diagram_class: DIAGRAM_CLASS,
    stroke_odd_pixel_length: STROKE_ODD_PIXEL_LENGTH,
    internal_alignment: INTERNAL_ALIGNMENT.to_sym,
    char_width: CHAR_WIDTH, comment_char_width: COMMENT_CHAR_WIDTH,
    ambiguous_width: 1, measurer: nil, text_charset: :unicode, escape_html: false,
    precision: nil, optimize_paths: false, href_mode: :xlink, link_policy: :safe, link_policy_violation: :warn,
    link_target: nil, link_rel: nil, id_prefix: nil, debug: false, locale: :en,
    theme: :default, inline_styles: false, max_width: nil, show_start: true, show_end: true, coerce: nil
  ).freeze

  class << self
    # Return the current default rendering settings.
    # @example
    #   RailroadDiagrams.default_options.href_mode #=> :xlink
    def default_options
      @default_options || DEFAULT_OPTIONS
    end

    # Update the default rendering settings for future diagrams.
    # @example
    #   RailroadDiagrams.configure { |options| options[:theme] = :dark }
    def configure
      values = default_options.to_h
      yield values
      @default_options = DEFAULT_OPTIONS.merge(**values)
    end
  end
end
