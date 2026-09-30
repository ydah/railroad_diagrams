# Changelog

## Unreleased

## 1.0.0 - 2026-09-30

### Added

- Build a gallery of node examples in every bundled theme and publish it with GitHub Pages.
- Run a browser-only Ruby playground with shareable examples and bundled offline runtime assets.
- Document the supported 1.x API with examples and a stability guide.
- Add a Rails view helper and separate Jekyll and Asciidoctor adapter projects with sample sites.

### Changed

- Begin the documented 1.x compatibility guarantee for the stable Ruby API.

## 0.8.0 - 2026-09-30

### Added

- Import W3C EBNF and safe YAML grammar definitions, with useful source locations on parse errors.
- Render Ruby DSL, JSON, YAML, and EBNF inputs from the CLI, with subcommands, per-rule output, text character sets, and file watching.
- Simplify grammar trees and report undefined references, duplicate definitions, unused rules, and repeated alternatives.
- Render multi-rule grammar documents with linked references, search, text alternatives, and lint findings.

### Deprecated

- Warn when the CLI demo is invoked without its `demo` subcommand.

## 0.7.0 - 2026-09-30

### Added

- A builder DSL, coercion for strings, symbols, arrays, and nil, and structural JSON/YAML serialization.
- Complex diagrams, blocks, counted repeats, separated lists, exclusions, character classes, and special tokens.
- Tree traversal, structural equality, DSL-style inspection, and width-limited SVG wrapping.

### Changed

- Preserve `Optional` and `ZeroOrMore` as distinct subclasses while keeping their existing diagram layout.
- Accept keyword arguments for links, titles, labels, and skip choices; positional forms now warn.

## 0.6.0 - 2026-09-30

### Added

- Built-in themes for classic, dark, automatic, print, and high-contrast rendering.
- Accessible diagram titles and descriptions, Japanese labels, and safe links with configurable SVG link attributes.
- Standalone HTML, Markdown text output, square-corner text, and optional Start and End markers.
- Inline SVG styles, custom node IDs and data attributes, and optional debug bounds.

### Fixed

- Keep linked labels single and declare the SVG link namespace when needed.
- Safely serialize CSS that contains XML or style terminators.

## 0.5.0 - 2026-09-30

### Added

- Per-call SVG rendering options for arc radius, alignment, measurement, number precision, and path optimization.
- Immutable text character sets, including square Unicode corners.
- A rendering benchmark and warning-only CI comparison.
- Concrete dimensions and branch paths for composite nodes in the test suite.

### Fixed

- Render shared nodes repeatedly without changing their SVG children or text character set.
- Keep optional-sequence bypass lines separate from deep final branches.
- Reduce text rendering time for large diagrams.

## 0.4.0 - 2026-09-30

### Fixed

- Correct node walking, diagram descriptions, and public output methods.
- Make repeated SVG formatting stable and fix standalone CSS, comment connections, group labels, escaping, numeric output, centering, and choice validation.
- Render MultipleChoice contents and correct text layout and default formatting.
- Run the packaged demo from any directory and reject unsupported CLI formats.
- Preserve repeated spaces in SVG labels and style MultipleChoice labels.
- Handle Style items, empty diagrams, non-string labels, and invalid diagram options.
- Keep text tracks clear around short alternating branches and tall horizontal-choice branches.
- Restore spacing around nested Sequence and Stack nodes to match upstream.

### Added

- Golden output, XML well-formedness, and SVG coordinate bounds checks.
- String-returning SVG and text APIs, flexible output writers, and a shared error hierarchy.
- Unicode 16.0 display-width tables and international text examples.
- CI checks minimum line and branch coverage.
- RuboCop checks Ruby 2.5 syntax and new style violations.
- Upstream parity compares 67 examples against a pinned Python renderer.
- README node gallery, reproducible preview images, a runnable quick start, migration notes, and contribution templates.
- Lrama API contract and integration smoke checks.

### Changed

- Invalid `AlternatingSequence` arity now raises `ArgumentError` via `InvalidArgument`.
- Comments retain their legacy CSS class and also carry `comment`.

### Deprecated

- `DiagramItem#to_str` now warns; use `#inspect` for debug output.

## 0.3.0 - 2025-02-24

- Fix some error when using ascii and unicode mode.

## 0.2.1 - 2025-02-01

- Fix an error for bundle install from Ruby 2.5.

## 0.2.0 - 2025-02-01

- Fix an error for standalone mode.
- Support Ruby 2.5 ~ 3.4.
- Change default style.

## 0.1.0 - 2025-02-01

- Initial release.
