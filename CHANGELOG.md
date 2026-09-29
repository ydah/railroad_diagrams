# Changelog

## Unreleased

### Fixed

- Correct node walking, diagram descriptions, and public output methods.
- Make repeated SVG formatting stable and fix standalone CSS, comment connections, group labels, escaping, numeric output, centering, and choice validation.
- Render MultipleChoice contents and correct text layout and default formatting.
- Run the packaged demo from any directory and reject unsupported CLI formats.
- Preserve repeated spaces in SVG labels and style MultipleChoice labels.
- Handle Style items, empty diagrams, non-string labels, and invalid diagram options.

### Added

- Golden output and XML well-formedness checks.
- String-returning SVG and text APIs, flexible output writers, and a shared error hierarchy.
- Unicode 16.0 display-width tables and international text examples.

### Changed

- Invalid `AlternatingSequence` arity now raises `ArgumentError` via `InvalidArgument`.
- Comments retain their legacy CSS class and also carry `comment`.

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
