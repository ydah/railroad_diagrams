# Contributing

Bug reports and patches are welcome. Include a small Ruby reproduction, the output format, and the expected result. For a rendering change, add a regression spec first, then run `bundle exec rake golden:update` and review the changed golden files. Commit golden changes separately from code changes.

Run `bin/setup` once and `bundle exec rake` before submitting a change. Check compatibility with Ruby 2.5 if you change library syntax. Public API changes need a README and [migration guide](docs/migration.md) update.

Versions follow SemVer. While the gem is at 0.x, breaking changes receive at least one minor release of deprecation notice; removal is deferred to 2.0.
