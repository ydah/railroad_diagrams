# frozen_string_literal: true

module ExamplesLoader
  DEMO_FILE = File.expand_path('../../examples/demo.rb', __dir__)

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
    collector.instance_eval(File.read(DEMO_FILE, encoding: 'utf-8'), DEMO_FILE)
    collector.diagrams
  end

  def names
    load.keys
  end

  # 英数字以外は16進に置き換えて一意にする（"{} block" と "() block" の衝突対策）
  def slug(name)
    name.gsub(/[^A-Za-z0-9]/) { |c| c == ' ' ? '_' : format('x%X', c.ord) }
  end

  RENDERERS = {
    'svg' => ->(d) { s = +''; d.write_svg(s.method(:<<)); s },
    'standalone' => ->(d) { s = +''; d.write_standalone(s.method(:<<)); s },
    'ascii' => lambda { |d|
      RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_ASCII)
      s = +''; d.write_text(s.method(:<<)); s
    },
    'unicode' => lambda { |d|
      RailroadDiagrams::TextDiagram.set_formatting(RailroadDiagrams::TextDiagram::PARTS_UNICODE)
      s = +''; d.write_text(s.method(:<<)); s
    }
  }.freeze

  EXTENSIONS = { 'svg' => 'svg', 'standalone' => 'svg', 'ascii' => 'txt', 'unicode' => 'txt' }.freeze

  def render(name, format)
    RENDERERS.fetch(format).call(load.fetch(name))
  end

  def golden_path(name, format)
    File.expand_path("../golden/#{slug(name)}/#{format}.#{EXTENSIONS.fetch(format)}", __dir__)
  end
end
