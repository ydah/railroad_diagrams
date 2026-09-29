# Changelog

## Unreleased

### Added

- Built-in themes for classic, dark, automatic, print, and high-contrast rendering.
- Accessible diagram titles and descriptions, Japanese labels, and safe links with configurable SVG link attributes.
- Standalone HTML, Markdown text output, square-corner text, and optional Start and End markers.

### Fixed

- Keep linked labels single and declare the SVG link namespace when needed.
- Safely serialize CSS that contains XML or style terminators.

## 0.5.0 - 2026-09-30

### Added

- Per-call SVG rendering options for arc radius, alignment, measurement, number precision, and path optimization.
- Immutable text character sets, including square Unicode corners.
- A rendering benchmark and warning-only CI comparison.

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
- Concrete dimensions and branch paths for composite nodes in the test suite.
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
