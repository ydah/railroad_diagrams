# frozen_string_literal: true

require 'open-uri'

namespace :unicode do
  desc 'Generate fixed Unicode display-width tables'
  task :generate, [:version] do |_task, args|
    version = args[:version] || '16.0.0'
    base = "https://www.unicode.org/Public/#{version}/ucd/"
    eaw = URI.open("#{base}EastAsianWidth.txt").read
    emoji = URI.open("#{base}emoji/emoji-data.txt").read
    categories = URI.open("#{base}extracted/DerivedGeneralCategory.txt").read

    parse = lambda do |source, initial, &mapping|
      values = Array.new(0x110000, initial)
      source.each_line do |line|
        fields = line.split('#', 2).first.to_s.split(';').map(&:strip)
        next unless fields.size == 2 && fields[0].match?(/\A[0-9A-F]+(?:\.\.[0-9A-F]+)?\z/)

        value = mapping.call(fields[1])
        next if value.nil?

        first, last = fields[0].split('..').map { |hex| hex.to_i(16) }
        (first..(last || first)).each { |cp| values[cp] = value }
      end
      values
    end

    widths = Array.new(0x110000, 0)
    [[0x3400, 0x4DBF], [0x4E00, 0x9FFF], [0xF900, 0xFAFF],
     [0x20000, 0x2FFFD], [0x30000, 0x3FFFD]].each do |first, last|
      (first..last).each { |cp| widths[cp] = 2 }
    end
    explicit = parse.call(eaw, nil) { |property| { 'W' => 2, 'F' => 2, 'A' => 3 }.fetch(property, 0) }
    explicit.each_with_index { |value, cp| widths[cp] = value unless value.nil? }
    presentation = parse.call(emoji, 0) { |property| 1 if property == 'Emoji_Presentation' }
    pictographic = parse.call(emoji, 0) { |property| 1 if property == 'Extended_Pictographic' }
    zero = parse.call(categories, 0) { |property| 1 if %w[Mn Me Cf].include?(property) }

    compact = lambda do |values|
      ranges = []
      values.each_with_index do |value, cp|
        next if value.nil? || value.zero?

        if ranges.last && ranges.last[1] == cp - 1 && ranges.last[2] == value
          ranges.last[1] = cp
        else
          ranges << [cp, cp, value]
        end
      end
      ranges
    end

    output = ["# frozen_string_literal: true", '# Generated from Unicode Character Database; do not edit.',
              'module RailroadDiagrams', '  module Unicode', '    module Tables',
              "      UNICODE_VERSION = #{version.inspect}.freeze"]
    { 'EAST_ASIAN_WIDTH' => widths, 'EMOJI_PRESENTATION' => presentation,
      'EXTENDED_PICTOGRAPHIC' => pictographic, 'ZERO_WIDTH' => zero }.each do |name, values|
      output << "      #{name} = ["
      compact.call(values).each { |first, last, value| output << "        [#{first}, #{last}, #{value}]," }
      output << '      ].freeze'
    end
    output.concat(['    end', '  end', 'end', ''])
    path = File.expand_path('../lib/railroad_diagrams/unicode/tables.rb', __dir__)
    File.write(path, output.join("\n"))
  end
end
