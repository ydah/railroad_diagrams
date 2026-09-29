require 'spec_helper'

RSpec.describe RailroadDiagrams::End do
  describe '#initialize' do
    it 'defaults to simple type' do
      end_node = described_class.new
      expect(end_node.instance_variable_get(:@type)).to eq('simple')
    end

    it 'accepts complex type' do
      end_node = described_class.new('complex')
      expect(end_node.instance_variable_get(:@type)).to eq('complex')
    end

    it 'sets width to 20' do
      end_node = described_class.new
      expect(end_node.width).to eq(20)
    end

    it 'sets up and down to 10' do
      end_node = described_class.new
      expect(end_node.up).to eq(10)
      expect(end_node.down).to eq(10)
    end

    it 'is a path element' do
      end_node = described_class.new
      expect(end_node.instance_variable_get(:@name)).to eq('path')
    end
  end

  describe '#format' do
    it 'returns self' do
      end_node = described_class.new
      result = end_node.format(0, 0, 100)
      expect(result).to eq(end_node)
    end

    it 'sets d attribute for simple type' do
      end_node = described_class.new('simple')
      end_node.format(10, 20, 100)
      expect(end_node.attrs['d']).to eq('M 10 20 h 20 m -10 -10 v 20 m 10 -20 v 20')
    end

    it 'sets d attribute for complex type' do
      end_node = described_class.new('complex')
      end_node.format(10, 20, 100)
      expect(end_node.attrs['d']).to eq('M 10 20 h 20 m 0 -10 v 20')
    end

    it 'uses correct x position' do
      end_node = described_class.new('simple')
      end_node.format(50, 60, 100)
      expect(end_node.attrs['d']).to start_with('M 50 60')
    end

    it 'uses correct y position' do
      end_node = described_class.new('simple')
      end_node.format(10, 100, 100)
      expect(end_node.attrs['d']).to start_with('M 10 100')
    end
  end

  describe '#text_diagram' do
    it 'returns a TextDiagram for simple type' do
      end_node = described_class.new('simple')
      td = end_node.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'returns a TextDiagram for complex type' do
      end_node = described_class.new('complex')
      td = end_node.text_diagram
      expect(td).to be_a(RailroadDiagrams::TextDiagram)
    end

    it 'includes cross and tee for simple type' do
      end_node = described_class.new('simple')
      td = end_node.text_diagram
      expect(td.lines.join("\n")).to include('┼')
      expect(td.lines.join("\n")).to include('┤')
    end

    it 'includes line and tee for complex type' do
      end_node = described_class.new('complex')
      td = end_node.text_diagram
      expect(td.lines.join("\n")).to include('─')
      expect(td.lines.join("\n")).to include('┤')
    end

    it 'has single line' do
      end_node = described_class.new('simple')
      td = end_node.text_diagram
      expect(td.lines.length).to eq(1)
    end
  end

  describe '#to_s' do
    it 'returns debug string for simple type' do
      end_node = described_class.new('simple')
      expect(end_node.to_s).to eq('End(type=simple)')
    end

    it 'returns debug string for complex type' do
      end_node = described_class.new('complex')
      expect(end_node.to_s).to eq('End(type=complex)')
    end
  end

  describe 'labeled ends' do
    %w[simple complex].each do |type|
      it "renders the #{type} label the same way through legacy and Context APIs" do
        end_node = described_class.new(type, label: 'DONE')
        context = RailroadDiagrams::Context.new
        metrics = context.metrics(end_node)
        svg = RailroadDiagrams::Svg::Serializer.call(end_node.render_svg(context, 10, 100, metrics.width))
        text = end_node.render_text(context).lines
        expect(end_node.children).to be_empty
        end_node.format(10, 100, end_node.width)

        expect(svg).to eq(svg_output(end_node))
        expect(svg).to include('style="text-anchor:end"')
        expect(text).to eq(end_node.text_diagram.lines)
      end
    end

    it 'measures the label using Context character width without changing legacy dimensions' do
      end_node = described_class.new(label: '日本')
      context = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(char_width: 10))
      expect([end_node.width, context.metrics(end_node).width]).to eq([44.0, 50])
      expect([context.metrics(end_node).up, context.metrics(end_node).height, context.metrics(end_node).down]).to eq([10, 0, 10])
      svg = RailroadDiagrams::Svg::Serializer.call(end_node.render_svg(context, 0, 100, 50))
      expect(svg).to include('h 50', 'x="50"')
    end

    it 'right aligns its text label and uses Context text characters' do
      end_node = described_class.new(label: 'A')
      ascii = RailroadDiagrams::Context.new(RailroadDiagrams.default_options.merge(text_charset: :ascii))
      expect(end_node.render_text(ascii).lines).to eq(['  A', '-+|'])
    end

    it 'preserves the unlabeled path element and its serialized output' do
      end_node = described_class.new
      context = RailroadDiagrams::Context.new
      expect(end_node.instance_variable_get(:@name)).to eq('path')
      expect(RailroadDiagrams::Svg::Serializer.call(end_node.render_svg(context, 10, 20, 20))).to eq(
        '<path d="M 10 20 h 20 m -10 -10 v 20 m 10 -20 v 20"></path>'
      )
    end
  end
end
