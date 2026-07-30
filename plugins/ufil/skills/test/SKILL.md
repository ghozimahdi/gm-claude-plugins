---
name: test
description: "Run all tests and report results. Use after implementing features."
disable-model-invocation: true
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:test`; in Codex invoke it as `$ufil:test`.

Run all tests and report results.

Steps:
1. If `<requested arguments>` is provided, run tests for that feature: `fvm flutter test test/features/<requested arguments>/`
2. Otherwise, run all tests: `fvm flutter test` (or `melos run test` if melos is available)
3. If tests fail, show the failing test names and error messages
4. Suggest fixes for each failing test
