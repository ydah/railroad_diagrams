require 'spec_helper'

RSpec.describe RailroadDiagrams::DiagramItem do
  cases = {
    'Sequence' => [-> { RailroadDiagrams::Sequence.new('a', 'b') }, [77.0, 11, 0, 11], 'M28.5 100h10'],
    'Stack' => [-> { RailroadDiagrams::Stack.new('a', 'b') }, [68.5, 11, 40, 11], 'M58.5 140h10'],
    'Choice' => [-> { RailroadDiagrams::Choice.new(0, 'a', 'b') }, [68.5, 11, 0, 41], 'M0.0 100h20'],
    'Optional' => [-> { RailroadDiagrams::Optional.new('a') }, [68.5, 20, 0, 11], 'M0.0 100a10 10 0 0 0 10 -10v0a10 10 0 0 1 10 -10'],
    'OneOrMore' => [-> { RailroadDiagrams::OneOrMore.new('a', ',') }, [48.5, 11, 0, 41], 'M10.0 100a10 10 0 0 0 -10 10v10a10 10 0 0 0 10 10'],
    'ZeroOrMore' => [-> { RailroadDiagrams::ZeroOrMore.new('a', ',') }, [88.5, 20, 0, 41], 'M0.0 100a10 10 0 0 0 10 -10v0a10 10 0 0 1 10 -10'],
    'HorizontalChoice' => [-> { RailroadDiagrams::HorizontalChoice.new('a', 'b') },
                           [137.0, 20, 0, 20], 'M0.0 100a10 10 0 0 0 10 -10v0a10 10 0 0 1 10 -10h38.5'],
    'OptionalSequence' => [-> { RailroadDiagrams::OptionalSequence.new('a', 'b') }, [117.0, 20.0, 0, 20.0], 'M0.0 100h20'],
    'AlternatingSequence' => [-> { RailroadDiagrams::AlternatingSequence.new('a', 'b') },
                              [88.5, 36, 0, 36], 'M0.0 100a10 10 0 0 0 10 -10v-5a10 10 0 0 1 10 -10'],
    'MultipleChoice' => [-> { RailroadDiagrams::MultipleChoice.new(0, 'any', 'a', 'b') }, [98.5, 11, 0, 41], 'M30.0 100v20a10 10 0 0 0 10 10']
  }

  cases.each do |name, (build, dimensions, path_data)|
    it "renders #{name} with its expected dimensions and branch path" do
      node = build.call
      expect([node.width, node.up, node.height, node.down]).to eq(dimensions)
      node.format(0, 100, node.width)
      expect(node.children.grep(RailroadDiagrams::Path).map { |path| path.attrs['d'] }).to include(path_data)
    end
  end

  it 'places the Group border around its label and child' do
    group = RailroadDiagrams::Group.new('a', 'g')
    expect([group.width, group.up, group.height, group.down]).to eq([48.5, 35, 0, 19])
    group.format(0, 100, group.width)
    border = group.children.find { |child| child.is_a?(described_class) && child.attrs['class'] == 'group-box' }
    expect(border.attrs).to include('x' => 0.0, 'y' => 81, 'width' => 48.5, 'height' => 38)
  end
end
