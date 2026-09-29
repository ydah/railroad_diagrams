# RailroadDiagrams [![Gem Version](https://badge.fury.io/rb/railroad_diagrams.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/railroad_diagrams)

A tiny Ruby+SVG library for drawing railroad syntax diagrams.

<img width="500" alt="image" src="https://github.com/user-attachments/assets/2e9542d5-bfbf-4a27-9258-88391a948ddd" />

Inspired by: https://github.com/tabatkins/railroad-diagrams

# Installation

Add this line to your application's Gemfile:
```ruby
gem 'railroad_diagrams'
```

Add then execute:
```bash
bundle install
```

Or install it yourself as:
```bash
gem install railroad_diagrams
```

## Usage

```ruby
require 'railroad_diagrams'
diagram = RailroadDiagrams::Diagram.new('SELECT', RailroadDiagrams::Optional.new('DISTINCT'))
File.write('select.svg', diagram.to_standalone_svg)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Run `bundle exec rake` for the specs and type check, or `bundle exec rake golden:update` to regenerate golden outputs for review. Run `bin/console` for an interactive prompt.

`to_svg`, `to_standalone_svg`, and `to_text` return strings. The older `write_svg`, `write_standalone`, and `write_text` methods accept an IO, a String, or a callable. Text output defaults to Unicode; use `to_text(charset: :ascii)` for ASCII. Labels use Unicode display widths, with ambiguous-width characters treated as one column.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ydah/railroad_diagrams.
