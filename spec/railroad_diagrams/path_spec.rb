require 'spec_helper'

RSpec.describe RailroadDiagrams::Path do
  describe '#initialize' do
    it 'sets initial position' do
      path = described_class.new(10, 20)
      expect(path.x).to eq(10)
      expect(path.y).to eq(20)
      expect(path.attrs['d']).to eq('M10 20')
    end
  end

  describe '#m' do
    it 'adds relative move command' do
      path = described_class.new(0, 0).m(5, 10)
      expect(path.attrs['d']).to eq('M0 0m5 10')
    end

    it 'returns self for chaining' do
      path = described_class.new(0, 0)
      expect(path.m(1, 2)).to eq(path)
    end
  end

  describe '#l' do
    it 'adds relative line command' do
      path = described_class.new(0, 0).l(5, 10)
      expect(path.attrs['d']).to eq('M0 0l5 10')
    end

    it 'returns self for chaining' do
      path = described_class.new(0, 0)
      expect(path.l(1, 2)).to eq(path)
    end
  end

  describe '#h' do
    it 'adds horizontal line command' do
      path = described_class.new(0, 0).h(50)
      expect(path.attrs['d']).to eq('M0 0h50')
    end

    it 'handles negative values' do
      path = described_class.new(0, 0).h(-30)
      expect(path.attrs['d']).to eq('M0 0h-30')
    end

    it 'returns self for chaining' do
      path = described_class.new(0, 0)
      expect(path.h(10)).to eq(path)
    end
  end

  describe '#v' do
    it 'adds vertical line command' do
      path = described_class.new(0, 0).v(50)
      expect(path.attrs['d']).to eq('M0 0v50')
    end

    it 'handles negative values' do
      path = described_class.new(0, 0).v(-30)
      expect(path.attrs['d']).to eq('M0 0v-30')
    end

    it 'returns self for chaining' do
      path = described_class.new(0, 0)
      expect(path.v(10)).to eq(path)
    end
  end

  describe '#right' do
    it 'moves right by positive value' do
      path = described_class.new(0, 0).right(10)
      expect(path.attrs['d']).to eq('M0 0h10')
    end

    it 'does not move for negative value' do
      path = described_class.new(0, 0).right(-10)
      expect(path.attrs['d']).to eq('M0 0h0')
    end

    it 'does not move for zero' do
      path = described_class.new(0, 0).right(0)
      expect(path.attrs['d']).to eq('M0 0h0')
    end
  end

  describe '#left' do
    it 'moves left by positive value' do
      path = described_class.new(0, 0).left(10)
      expect(path.attrs['d']).to eq('M0 0h-10')
    end

    it 'does not move for negative value' do
      path = described_class.new(0, 0).left(-10)
      expect(path.attrs['d']).to eq('M0 0h0')
    end

    it 'does not move for zero' do
      path = described_class.new(0, 0).left(0)
      expect(path.attrs['d']).to eq('M0 0h0')
    end
  end

  describe '#down' do
    it 'moves down by positive value' do
      path = described_class.new(0, 0).down(10)
      expect(path.attrs['d']).to eq('M0 0v10')
    end

    it 'does not move for negative value' do
      path = described_class.new(0, 0).down(-10)
      expect(path.attrs['d']).to eq('M0 0v0')
    end

    it 'does not move for zero' do
      path = described_class.new(0, 0).down(0)
      expect(path.attrs['d']).to eq('M0 0v0')
    end
  end

  describe '#up' do
    it 'moves up by positive value' do
      path = described_class.new(0, 0).up(10)
      expect(path.attrs['d']).to eq('M0 0v-10')
    end

    it 'does not move for negative value' do
      path = described_class.new(0, 0).up(-10)
      expect(path.attrs['d']).to eq('M0 0v0')
    end

    it 'does not move for zero' do
      path = described_class.new(0, 0).up(0)
      expect(path.attrs['d']).to eq('M0 0v0')
    end
  end

  describe '#arc' do
    it 'creates arc from north to east' do
      path = described_class.new(0, 0).arc('ne')
      expect(path.attrs['d']).to include('a10 10 0 0 1')
    end

    it 'creates arc from east to south' do
      path = described_class.new(0, 0).arc('es')
      expect(path.attrs['d']).to include('a10 10 0 0 1')
    end

    it 'creates arc from south to west' do
      path = described_class.new(0, 0).arc('sw')
      expect(path.attrs['d']).to include('a10 10 0 0 1')
    end

    it 'creates arc from west to north' do
      path = described_class.new(0, 0).arc('wn')
      expect(path.attrs['d']).to include('a10 10 0 0 1')
    end

    it 'creates counter-clockwise arc' do
      path = described_class.new(0, 0).arc('nw')
      expect(path.attrs['d']).to include('a10 10 0 0 0')
    end

    it 'returns self for chaining' do
      path = described_class.new(0, 0)
      expect(path.arc('ne')).to eq(path)
    end
  end

  describe '#arc_8' do
    it 'creates arc in 8 directions' do
      path = described_class.new(0, 0).arc_8('n', 'cw')
      expect(path.attrs['d']).to include('a 10 10 0 0 1')
    end

    it 'creates counter-clockwise arc' do
      path = described_class.new(0, 0).arc_8('n', 'ccw')
      expect(path.attrs['d']).to include('a 10 10 0 0 0')
    end

    it 'returns self for chaining' do
      path = described_class.new(0, 0)
      expect(path.arc_8('n', 'cw')).to eq(path)
    end
  end

  describe '#add' do
    it 'adds self to parent children' do
      parent = RailroadDiagrams::DiagramItem.new('g')
      path = described_class.new(0, 0)

      result = path.add(parent)

      expect(parent.children).to include(path)
      expect(result).to eq(path)
    end
  end

  describe '#write_svg' do
    it 'writes path element' do
      path = described_class.new(10, 20).h(50)
      output = StringIO.new

      path.write_svg(output.method(:write))

      expect(output.string).to eq('<path d="M10 20h50" />')
    end

    it 'escapes attribute values' do
      path = described_class.new(0, 0)
      path.attrs['data'] = 'foo&bar'
      output = StringIO.new

      path.write_svg(output.method(:write))

      expect(output.string).to include('data="foo&amp;bar"')
    end

    it 'sorts attributes alphabetically' do
      path = described_class.new(0, 0)
      path.attrs['z'] = '1'
      path.attrs['a'] = '2'
      output = StringIO.new

      path.write_svg(output.method(:write))

      string = output.string
      a_pos = string.index('a="2"')
      d_pos = string.index('d="M0 0"')
      z_pos = string.index('z="1"')

      expect(a_pos).to be < d_pos
      expect(d_pos).to be < z_pos
    end
  end

  describe '#format' do
    it 'adds h.5 to path' do
      path = described_class.new(0, 0).format
      expect(path.attrs['d']).to eq('M0 0h.5')
    end

    it 'returns self for chaining' do
      path = described_class.new(0, 0)
      expect(path.format).to eq(path)
    end
  end

  describe '#text_diagram' do
    it 'returns empty TextDiagram' do
      path = described_class.new(0, 0)
      td = path.text_diagram

      expect(td).to be_a(RailroadDiagrams::TextDiagram)
      expect(td.entry).to eq(0)
      expect(td.exit).to eq(0)
      expect(td.lines).to eq([])
    end
  end

  describe '#to_s' do
    it 'returns debug string' do
      path = described_class.new(100, 200)
      expect(path.to_s).to eq('Path(100, 200)')
    end
  end

  describe 'method chaining' do
    it 'allows complex path chaining' do
      path = described_class.new(0, 0)
        .h(10)
        .v(20)
        .arc('ne')
        .l(5, 5)
        .m(1, 1)

      expect(path.attrs['d']).to include('M0 0')
      expect(path.attrs['d']).to include('h10')
      expect(path.attrs['d']).to include('v20')
      expect(path.attrs['d']).to include('l5 5')
      expect(path.attrs['d']).to include('m1 1')
    end
  end
end
