# frozen_string_literal: true

require 'json'
require_relative '../lib/railroad_diagrams'

module PlaygroundBundle
  module_function

  def build(path)
    source = expand(File.expand_path('../lib/railroad_diagrams.rb', __dir__), {})
    css = RailroadDiagrams::Theme[:default].css(css_variables: false)
    source << <<~RUBY
      module RailroadDiagrams
        PLAYGROUND_CSS = #{css.dump}.freeze

        def self.playground_render(source)
          item = Builder.new.instance_eval(source, '(playground)', 1)
          item = Coercion.call(item)
          diagram = item.is_a?(Diagram) ? item : Diagram.new(item)
          JSON.generate('svg' => diagram.to_standalone_svg(css: PLAYGROUND_CSS),
                        'text' => diagram.to_text(charset: :unicode))
        end
      end
    RUBY
    File.write(path, "export const rubySource = #{JSON.generate(source)};\n")
  end

  def expand(path, seen)
    return '' if seen[path]

    seen[path] = true
    File.readlines(path).map do |line|
      match = line.match(/\A\s*require_relative ['"]([^'"]+)['"]\s*\z/)
      match ? expand(File.expand_path("#{match[1]}.rb", File.dirname(path)), seen) : line
    end.join
  end
end

PlaygroundBundle.build(ARGV.fetch(0)) if $PROGRAM_NAME == __FILE__
