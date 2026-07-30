---
name: check
description: "Run static analysis and formatting to ensure code quality. Use before committing."
disable-model-invocation: true
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:check`; in Codex invoke it as `$ufil:check`. Resolve `UFIL_ROOT` to the
plugin root containing this skill; Claude Code may provide
`CLAUDE_PLUGIN_ROOT`, while Codex can resolve it from the installed skill path.

Run static analysis and formatting to ensure code quality.

Steps:
1. Run `fvm dart fix --apply lib/`
2. Run `fvm dart analyze lib test` (or `melos run analyze` if melos is available)
3. Fix any remaining issues
4. Run `fvm dart format lib test` (or `melos run format` if melos is available)

Report the result — zero issues expected.

## References

- `${UFIL_ROOT}/docs/CODE_STYLE.md` — Import ordering and code formatting
