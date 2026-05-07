---
description: "Run all tests and report results. Use after implementing features."
argument-hint: "[feature-name]"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
model: haiku
---

Run all tests and report results.

Steps:
1. If `$ARGUMENTS` is provided, run tests for that feature: `fvm flutter test test/features/$ARGUMENTS/`
2. Otherwise, run all tests: `fvm flutter test` (or `melos run test` if melos is available)
3. If tests fail, show the failing test names and error messages
4. Suggest fixes for each failing test
