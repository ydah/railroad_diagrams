## Change

Describe the issue, change, catalog ID, and compatibility impact. If output changes, summarize the golden diff and add a representative image.

## Checks

- [ ] Regression test fails before the fix and passes afterward
- [ ] `bundle exec rspec` passes
- [ ] Ruby 2.5 syntax and behavior checked
- [ ] `bundle exec rake rbs_inline` and `bundle exec steep check` pass
- [ ] Golden changes committed separately, if output changed
- [ ] CHANGELOG Unreleased updated
- [ ] README and migration guide updated, if a public API changed
