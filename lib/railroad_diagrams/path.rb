# frozen_string_literal: true

module RailroadDiagrams
  class Path
    attr_reader :x, :y, :attrs

    def initialize(x, y)
      @x = x
      @y = y
      @attrs = { 'd' => "M#{x} #{y}" }
    end

    def m(x, y)
      @attrs['d'] += "m#{x} #{y}"
      self
    end

    def l(x, y)
      @attrs['d'] += "l#{x} #{y}"
      self
    end

    def h(val)
      @attrs['d'] += "h#{val}"
      self
    end

    def right(val)
      h([0, val].max)
    end

    def left(val)
      h(-[0, val].max)
    end

    def v(val)
      @attrs['d'] += "v#{val}"
      self
    end

    def down(val)
      v([0, val].max)
    end

    def up(val)
      v(-[0, val].max)
    end

    def arc_8(start, dir)
      arc = AR
      s2 = 1 / Math.sqrt(2) * arc
      s2inv = arc - s2
      sweep = dir == 'cw' ? '1' : '0'
      path = "a #{arc} #{arc} 0 0 #{sweep} "

      sd = start + dir
      offset = case sd
               when 'ncw' then [s2, s2inv]
               when 'necw' then [s2inv, s2]
               when 'ecw' then [-s2inv, s2]
               when 'secw' then [-s2, s2inv]
               when 'scw' then [-s2, -s2inv]
               when 'swcw' then [-s2inv, -s2]
               when 'wcw' then [s2inv, -s2]
               when 'nwcw' then [s2, -s2inv]
               when 'nccw' then [-s2, s2inv]
               when 'nwccw' then [-s2inv, s2]
               when 'wccw' then [s2inv, s2]
               when 'swccw' then [s2, s2inv]
               when 'sccw' then [s2, -s2inv]
               when 'seccw' then [s2inv, -s2]
               when 'eccw' then [-s2inv, -s2]
               when 'neccw' then [-s2, -s2inv]
               end

      path += offset.map(&:to_s).join(' ')
      @attrs['d'] += path
      self
    end

    def arc(sweep)
      x = AR
      y = AR
      x *= -1 if sweep[0] == 'e' || sweep[1] == 'w'
      y *= -1 if sweep[0] == 's' || sweep[1] == 'n'
      cw = %w[ne es sw wn].include?(sweep) ? 1 : 0
      @attrs['d'] += "a#{AR} #{AR} 0 0 #{cw} #{x} #{y}"
      self
    end

    def add(parent)
      parent.children << self
      self
    end

    def write_svg(write)
      write.call('<path')
      @attrs.sort.each do |name, value|
        write.call(" #{name}=\"#{RailroadDiagrams.escape_attr(value)}\"")
      end
      write.call(' />')
    end

    def format
      @attrs['d'] += 'h.5'
      self
    end

    def text_diagram
      TextDiagram.new(0, 0, [])
    end

    def to_s
      "Path(#{@x.inspect}, #{@y.inspect})"
    end
  end
end
