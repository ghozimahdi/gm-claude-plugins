---
description: "Run static analysis and formatting to ensure code quality. Use before committing."
argument-hint: ""
allowed-tools: ["Bash", "Read", "Edit", "Glob", "Grep"]
model: haiku
---

Run static analysis and formatting to ensure code quality.

Steps:
1. Run `fvm dart fix --apply lib/`
2. Run `fvm dart analyze lib test` (or `melos run analyze` if melos is available)
3. Fix any remaining issues
4. Run `fvm dart format lib test` (or `melos run format` if melos is available)

Report the result — zero issues expected.

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/CODE_STYLE.md` — Import ordering and code formatting
