# Migration guide

## From 0.3.0

- `Diagram#to_svg`, `#to_standalone_svg`, and `#to_text` return strings. The existing `write_*` methods remain available and also accept IO objects and mutable strings.
- `Diagram#to_text` returns unescaped text by default. Use `escape_html: true` when embedding it in HTML. `write_text` still escapes by default.
- Standalone SVG includes the default CSS when `css` is omitted or `true`; pass `css: false` to omit the style element.
- `AlternatingSequence.new` with the wrong number of children raises `InvalidArgument`, a subclass of `ArgumentError`, instead of `RuntimeError`.
- `DiagramItem#to_str` now warns. Use `#inspect` for debug output. It remains callable until 2.0.
- `Comment` SVG groups now include a `comment` CSS class alongside the existing `non-terminal` class.
- Text diagrams use Unicode display widths. CJK and emoji labels may occupy more columns than before.

See [CHANGELOG.md](../CHANGELOG.md) for all fixes and additions.

## From 0.6.0

- `Optional.new` now returns an `Optional` instance, and `ZeroOrMore.new` returns a `ZeroOrMore` instance. Both still satisfy `is_a?(Choice)` and retain their SVG layout. Code that compares `instance_of?(Choice)` must use `is_a?(Choice)`.
- Pass links and titles as keywords, for example `Terminal.new('name', href: '#name', title: 'Name')`. Pass group labels as `label:` and optional branches as `skip:`. Positional forms still work but warn; set `RAILROAD_DIAGRAMS_DEPRECATION=raise` to find them in tests.
- `Terminal.new('a', { 'x' => 1 })` remains a positional href hash on Ruby 2.5 and later. It is not a valid SVG link; use a string `href:` value.

## From 0.7.0

- Use `railroad_diagrams render grammar.ebnf -o grammar.html` for your own grammar. The old command without a subcommand still renders the bundled demo, but warns. Use `railroad_diagrams demo` to keep that behavior without a warning.
- Ruby CLI input executes the named `.rb` file. YAML, JSON, and EBNF inputs are parsed as data and do not execute Ruby code.
- `Document` joins named rules into linked HTML. `Importers::W3cEbnf.parse` and `Importers::YamlGrammar.parse` return documents.

## From 0.8.0 to 1.0.0

- The default SVG number precision remains unrestricted and SVG links still use `xlink:href`. Set `precision:` or `href_mode:` explicitly to change either behavior.
- Supported API names and compatibility guarantees are listed in [API stability](api_stability.md). Internal rendering classes remain visible as Ruby constants for compatibility, but are not extension points.
- Rails view helpers load with `require 'railroad_diagrams/rails'`. Jekyll and Asciidoctor integrations live in the separate gem directories under `integrations/`.
