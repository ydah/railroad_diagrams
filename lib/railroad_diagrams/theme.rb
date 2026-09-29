# rbs_inline: enabled
# frozen_string_literal: true

require 'erb'

module RailroadDiagrams
  # A named color and typography palette for diagram output.
  # @example
  #   Theme[:dark].css
  class Theme < Struct.new(:name, :tokens, keyword_init: true)
    DEFAULT_TOKENS = {
      '--rr-bg' => 'white',
      '--rr-stroke' => '#333333',
      '--rr-stroke-width' => '3',
      '--rr-terminal-fill' => 'hsl(190, 100%, 83%)',
      '--rr-nonterminal-fill' => 'hsl(223, 100%, 83%)',
      '--rr-text' => '#333333',
      '--rr-font' => 'bold 14px monospace',
      '--rr-comment-font' => 'italic 12px monospace',
      '--rr-group-stroke' => 'gray',
      '--rr-track-stroke' => 'black',
      '--rr-track-fill' => 'rgba(0,0,0,0)',
      '--rr-rect-fill' => 'hsl(120,100%,90%)',
      '--rr-diagram-text-fill' => 'white',
      '--rr-hover-fill' => '#eee'
    }.freeze

    CLASSIC_TOKENS = DEFAULT_TOKENS.merge(
      '--rr-bg' => 'hsl(30,20%,95%)',
      '--rr-stroke' => 'black',
      '--rr-terminal-fill' => 'hsl(120,100%,90%)',
      '--rr-nonterminal-fill' => 'hsl(120,100%,90%)',
      '--rr-text' => 'black'
    ).freeze

    DARK_TOKENS = DEFAULT_TOKENS.merge(
      '--rr-bg' => '#1e1e1e',
      '--rr-stroke' => '#d4d4d4',
      '--rr-terminal-fill' => 'hsl(190, 60%, 30%)',
      '--rr-nonterminal-fill' => 'hsl(223, 50%, 35%)',
      '--rr-text' => '#f0f0f0',
      '--rr-group-stroke' => '#888',
      '--rr-track-stroke' => '#d4d4d4',
      '--rr-rect-fill' => '#333333',
      '--rr-diagram-text-fill' => '#1e1e1e',
      '--rr-hover-fill' => '#444444'
    ).freeze

    PRINT_TOKENS = DEFAULT_TOKENS.merge(
      '--rr-stroke' => 'black',
      '--rr-terminal-fill' => 'none',
      '--rr-nonterminal-fill' => 'none',
      '--rr-text' => 'black',
      '--rr-group-stroke' => 'black',
      '--rr-rect-fill' => 'none',
      '--rr-diagram-text-fill' => 'white',
      '--rr-hover-fill' => 'white'
    ).freeze

    HIGH_CONTRAST_TOKENS = DARK_TOKENS.merge(
      '--rr-bg' => 'black',
      '--rr-stroke' => 'white',
      '--rr-stroke-width' => '4',
      '--rr-terminal-fill' => 'black',
      '--rr-nonterminal-fill' => 'black',
      '--rr-text' => 'white',
      '--rr-group-stroke' => 'white',
      '--rr-track-stroke' => 'white',
      '--rr-rect-fill' => 'black',
      '--rr-diagram-text-fill' => 'black',
      '--rr-hover-fill' => '#222222'
    ).freeze

    THEMES = {
      default: new(name: :default, tokens: DEFAULT_TOKENS).freeze,
      classic: new(name: :classic, tokens: CLASSIC_TOKENS).freeze,
      dark: new(name: :dark, tokens: DARK_TOKENS).freeze,
      auto: new(name: :auto, tokens: DEFAULT_TOKENS).freeze,
      print: new(name: :print, tokens: PRINT_TOKENS).freeze,
      high_contrast: new(name: :high_contrast, tokens: HIGH_CONTRAST_TOKENS).freeze
    }.freeze

    # Resolve one of the built-in themes by name.
    # @example
    #   Theme[:print]
    def self.[](name)
      THEMES.fetch(name.to_sym) { raise InvalidArgument, "unknown theme: #{name.inspect}" }
    end

    def css(css_variables: true)
      return render(tokens, css_variables, name) unless name == :auto

      base_css = render(DEFAULT_TOKENS, css_variables, :default)
      dark_css = if css_variables
                   "  svg.railroad-diagram {\n#{DARK_TOKENS.map { |key, value| "    #{key}: #{value};\n" }.join}  }\n"
                 else
                   render(DARK_TOKENS, false, :dark).lines.map { |line| "  #{line}" }.join
                 end
      ERB.new(File.read(File.expand_path('themes/auto.css.erb', __dir__))).result(binding)
    end

    def inline_style(element, classes)
      palette = tokens
      own_classes = element.attrs.fetch('class', '').split
      all_classes = classes + own_classes
      rules = case element.name
              when 'svg'
                ["background-color:#{palette.fetch('--rr-bg')}", "color:#{palette.fetch('--rr-text')}"]
              when 'path'
                ["stroke-width:#{palette.fetch('--rr-stroke-width')}", "stroke:#{palette.fetch('--rr-stroke')}",
                 "fill:#{palette.fetch('--rr-track-fill')}"]
              when 'rect'
                ["stroke-width:#{palette.fetch('--rr-stroke-width')}", "stroke:#{palette.fetch('--rr-stroke')}",
                 "fill:#{palette.fetch('--rr-rect-fill')}"]
              when 'text'
                ["font:#{palette.fetch('--rr-font')}", 'text-anchor:middle', 'white-space:pre']
              else []
              end
      if element.name == 'rect'
        rules << "fill:#{palette.fetch('--rr-terminal-fill')}" if all_classes.include?('terminal')
        rules << "fill:#{palette.fetch('--rr-nonterminal-fill')}" if all_classes.include?('non-terminal')
        rules.push("stroke:#{palette.fetch('--rr-group-stroke')}", 'stroke-dasharray:10 5', 'fill:none') if own_classes.include?('group-box')
      elsif element.name == 'path' && own_classes.include?('diagram-text')
        rules.push("fill:#{palette.fetch('--rr-diagram-text-fill')}", 'cursor:help')
      elsif element.name == 'text'
        rules << "fill:#{palette.fetch('--rr-text')}" unless %i[default auto].include?(name)
        rules << 'font-size:12px' if own_classes.include?('diagram-text')
        rules << 'font-size:16px' if own_classes.include?('diagram-arrow')
        rules << 'text-anchor:start' if own_classes.include?('label')
        rules << "font:#{palette.fetch('--rr-comment-font')}" if own_classes.include?('comment')
      end
      rules.join(';')
    end

    private

    def render(palette, css_variables, theme_name)
      value = ->(key) { css_variables ? "var(#{key})" : palette.fetch(key) }
      declarations = if css_variables
                       "svg.railroad-diagram {\n#{palette.map { |key, entry| "  #{key}: #{entry};\n" }.join}}\n"
                     else
                       ''
                     end
      color_selector = theme_name == :default && !css_variables ? '*' : 'svg.railroad-diagram *'
      text_fill = theme_name == :default && !css_variables ? '' : "\n  fill: #{value.call('--rr-text')};"
      ERB.new(File.read(File.expand_path('themes/base.css.erb', __dir__))).result(binding)
    end
  end
end
