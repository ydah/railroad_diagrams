# frozen_string_literal: true

module ExamplesLoader
  EXAMPLE_FILES = Dir[File.expand_path('../../examples/*.rb', __dir__)].sort.freeze
  THEMES = %w[default classic dark auto print high_contrast].freeze

  class Collector
    include RailroadDiagrams

    attr_reader :diagrams

    def initialize
      @diagrams = {}
    end

    def add(name, diagram)
      raise ArgumentError, "duplicate example name: #{name}" if @diagrams.key?(name)

      @diagrams[name] = diagram
    end
  end

  module_function

  # 呼ぶたびに新しいノードを組み立てる（描画による状態汚染を避けるため）
  def load
    collector = Collector.new
    EXAMPLE_FILES.each do |file|
      collector.instance_eval(File.read(file, encoding: 'utf-8'), file)
    end
    collector.diagrams
  end

  def names
    load.keys
  end

  # 英数字以外は16進に置き換えて一意にする（"{} block" と "() block" の衝突対策）
  def slug(name)
    name.gsub(/[^A-Za-z0-9]/) { |c| c == ' ' ? '_' : format('x%X', c.ord) }
  end

  THEME_RENDERERS = THEMES.each_with_object({}) do |theme, renderers|
    renderers["standalone-#{theme}"] = ->(d) { d.to_standalone_svg(theme: theme.to_sym) }
  end.freeze

  RENDERERS = {
    'svg' => ->(d) { s = +''; d.write_svg(s.method(:<<)); s },
    'svg-optimized' => ->(d) { d.to_svg(precision: 2, optimize_paths: true) },
    'svg-debug' => ->(d) { d.to_svg(debug: true) },
    'standalone' => ->(d) { s = +''; d.write_standalone(s.method(:<<)); s },
    'ascii' => lambda { |d|
      RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_ASCII)
      s = +''; d.write_text(s.method(:<<)); s
    },
    'unicode' => lambda { |d|
      RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_UNICODE)
      s = +''; d.write_text(s.method(:<<)); s
    }
  }.merge(THEME_RENDERERS).freeze

  EXTENSIONS = {
    'svg' => 'svg', 'svg-optimized' => 'svg', 'svg-debug' => 'svg',
    'standalone' => 'svg', 'ascii' => 'txt', 'unicode' => 'txt'
  }.merge(THEME_RENDERERS.keys.each_with_object({}) { |format, extensions| extensions[format] = 'svg' }).freeze

  def render(name, format)
    RENDERERS.fetch(format).call(load.fetch(name))
  end

  def golden_path(name, format)
    File.expand_path("../golden/#{slug(name)}/#{format}.#{EXTENSIONS.fetch(format)}", __dir__)
  end
end
