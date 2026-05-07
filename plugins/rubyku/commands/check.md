---
description: "Run RuboCop and code quality checks. Use before committing."
argument-hint: "[file or directory]"
allowed-tools: ["Bash", "Read", "Edit", "Glob", "Grep"]
model: haiku
---

Run code quality checks on the project.

Arguments: $ARGUMENTS (optional file or directory to check, defaults to entire project)

## Steps

1. Run `bundle exec rubocop $ARGUMENTS` (or full project if no args)
2. If offenses found, run `bundle exec rubocop -a $ARGUMENTS` to auto-correct safe offenses
3. If unsafe offenses remain, show them and suggest manual fixes
4. Run `bundle exec brakeman --no-pager -q` for security scan
5. Report results — zero issues expected

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/CODE_OF_CONDUCT.md`
