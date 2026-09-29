# RailroadDiagrams

[![Gem Version](https://badge.fury.io/rb/railroad_diagrams.svg)](https://rubygems.org/gems/railroad_diagrams)

Generate railroad syntax diagrams as SVG or fixed-width text with Ruby 2.5 or newer. Inspired by [railroad-diagrams](https://github.com/tabatkins/railroad-diagrams).

![A sample railroad diagram](docs/images/simple.svg)

## Install

```bash
gem install railroad_diagrams
```

Or add `gem 'railroad_diagrams'` to your Gemfile and run `bundle install`.

## Quick start

```ruby
require 'railroad_diagrams'

diagram = RailroadDiagrams::Diagram.new('SELECT', RailroadDiagrams::Optional.new('DISTINCT'))
File.write('select.svg', diagram.to_standalone_svg)
```

`to_standalone_svg` includes CSS. Use `to_svg` to embed the diagram in a page with your own CSS. Both methods return strings; `write_svg` and `write_standalone` write to an IO, a String, or a callable.

Select a built-in theme with `to_standalone_svg(theme: :dark)` or use `theme: :auto` to follow the viewer's color scheme. Pass `inline_styles: true` when the destination strips SVG style elements. `to_html(title: 'Syntax')` returns a complete HTML page. For screen readers, pass `title:` and `desc: :auto` to `Diagram.new`; `to_svg(locale: :ja)` produces a Japanese description. Links in `to_svg` allow HTTP, HTTPS, email, and relative URLs by default.

## Nodes

Strings passed as children become `Terminal` nodes. Build larger diagrams by nesting the constructors below. See [examples/demo.rb](examples/demo.rb) for complete diagrams.

| Node | Example | Preview |
| --- | --- | --- |
| `Terminal` | `Terminal.new('word')` | <img src="docs/images/simple.svg" alt="Terminal example" width="180"> |
| `NonTerminal` | `NonTerminal.new('expression')` | <img src="docs/images/Group_example.svg" alt="NonTerminal example" width="180"> |
| `Comment` | `Comment.new('note')` | <img src="docs/images/comment.svg" alt="Comment example" width="180"> |
| `Sequence` | `Sequence.new('a', 'b')` | <img src="docs/images/rrx2Dsequence.svg" alt="Sequence example" width="180"> |
| `Stack` | `Stack.new('a', 'b')` | <img src="docs/images/rrx2Dstack.svg" alt="Stack example" width="180"> |
| `Choice` | `Choice.new(0, 'a', 'b')` | <img src="docs/images/rrx2Dchoice.svg" alt="Choice example" width="180"> |
| `Optional` | `Optional.new('a')` | <img src="docs/images/rrx2Doptional.svg" alt="Optional example" width="180"> |
| `OneOrMore` | `OneOrMore.new('a', ',')` | <img src="docs/images/rrx2Doneormore.svg" alt="OneOrMore example" width="180"> |
| `ZeroOrMore` | `ZeroOrMore.new('a', ',')` | <img src="docs/images/rrx2Dzeroormorex2D1.svg" alt="ZeroOrMore example" width="180"> |
| `Group` | `Group.new('a', 'label')` | <img src="docs/images/rrx2Dgroup.svg" alt="Group example" width="180"> |
| `HorizontalChoice` | `HorizontalChoice.new('a', 'b')` | <img src="docs/images/rrx2Dhorizontalchoice.svg" alt="HorizontalChoice example" width="180"> |
| `OptionalSequence` | `OptionalSequence.new('a', 'b')` | <img src="docs/images/rrx2Doptionalsequence.svg" alt="OptionalSequence example" width="180"> |
| `AlternatingSequence` | `AlternatingSequence.new('a', 'b')` | <img src="docs/images/rrx2Dalternatingsequence.svg" alt="AlternatingSequence example" width="180"> |
| `MultipleChoice` | `MultipleChoice.new(0, 'any', 'a', 'b')` | <img src="docs/images/rrx2Dmultchoice.svg" alt="MultipleChoice example" width="180"> |
| `Skip`, `Start`, `End` | `Skip.new`, `Start.new`, `End.new` | <img src="docs/images/labeledx2Dstart.svg" alt="Start and End example" width="180"> |

`Optional.new` and `ZeroOrMore.new` return a `Choice`. `HorizontalChoice.new` and `OptionalSequence.new` return a `Sequence` when passed zero or one child. These factory return types are part of the current API.

## Text output

```ruby
puts diagram.to_text                       # Unicode box characters
puts diagram.to_text(charset: :ascii)       # ASCII only
puts diagram.to_text(charset: :unicode_square, strip_trailing: true)
puts diagram.to_text(escape_html: true)     # safe to embed in HTML
puts diagram.to_markdown                     # fenced code block
```

Labels use Unicode display widths, so CJK and emoji fit their boxes. Ambiguous-width characters occupy one column. The older `write_text` method escapes HTML by default for compatibility.

## Demo CLI

`railroad_diagrams --format=svg > demo.html` writes an HTML page containing the bundled examples. Formats: `svg`, `standalone`, `ascii`, and `unicode`. Pass example names after the options to select diagrams. This command runs the bundled demo; use the Ruby API for your own diagrams.

## Configuration and compatibility

The constants in [lib/railroad_diagrams.rb](lib/railroad_diagrams.rb), including `VS`, `AR`, `CHAR_WIDTH`, and `INTERNAL_ALIGNMENT`, remain available for compatibility. Pass options such as `arc_radius:`, `char_width:`, and `theme:` to individual output calls. `Style.default_style` returns the default CSS. `to_text(charset:)` uses per-call state and is safe to call from multiple threads.

Read the [migration guide](docs/migration.md) for behavior changes and deprecations. Before 1.0, breaking changes receive at least one minor release of deprecation notice; removal is deferred to 2.0.

## Development and releases

Run `bin/setup`, then `bundle exec rake` for specs and type checking. `bundle exec rake golden:update` regenerates golden outputs; review those diffs before committing. `bundle exec rake docs:images` copies the reviewed SVG outputs into the node gallery. `bin/console` opens an IRB session.

To release, update `lib/railroad_diagrams/version.rb` and `CHANGELOG.md`, run the test suite, then push a matching `vX.Y.Z` tag. The [release workflow](.github/workflows/release.yml) publishes the gem through RubyGems Trusted Publishing and creates a GitHub release.

See [CONTRIBUTING.md](CONTRIBUTING.md) for changes and [SECURITY.md](SECURITY.md) for vulnerability reports. Licensed under [MIT](LICENSE.txt).
