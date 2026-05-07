---
description: "Ship a feature — write tests, review code, commit, and create PR."
argument-hint: "[feature-scope]"
allowed-tools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep", "Agent", "Skill"]
---

Ship a feature — write tests, review code, commit, and create PR.

Arguments: $ARGUMENTS (feature scope like "auth" or "tenant")

## Project Type Detection (MUST DO FIRST)
- **Modular**: `packages/` directory exists → multi-package with melos
- **Single-module**: No `packages/` directory → single `lib/` project

## Phase 1 — Write Tests
- Non-modular: create test files in `test/features/<feature>/` mirroring lib structure
- Modular: create test files in each package's `test/` directory
- UseCase tests, repository tests, Bloc tests, DTO tests
- Non-modular: use `bloc_test`, `mocktail`, `Result.ok()`/`Result.error()`, `tOk()`/`tError()` helpers
- Modular: use `bloc_test`, `mocktail`, `Failure.noFailure()`/`Failure.xxx()` return patterns
- Run tests

## Phase 2 — Code Review
- Run `dart fix --apply lib/`
- Run analyzer — fix all issues
- Check: no dynamic, no business logic in UI, freezed everywhere, ScreenUtil for sizing
- Check: Bloc not Cubit, @injectable annotations
- Non-modular: ErrorMapper in repos, Result not Either
- Modular: FailureHandlerMixin in repos, query → `Future<Result>`, action → `Future<Failure>`, `switch` on `result.failure` or `failure`
- Modular: separate mapper classes (NO `.toModel()` on DTO), ResultMapper for queries only

## Phase 3 — Commit
- Stage relevant files only
- Conventional commit: `feat(<scope>): <description>`
- Split tests into separate commit if needed

## Phase 4 — Push & PR
- Push to remote
- Create PR with `gh pr create` — summary, changes checklist, test plan

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
- `${CLAUDE_PLUGIN_ROOT}/docs/BLOC_PATTERN.md` — Bloc events, states, sub-state unions
- `${CLAUDE_PLUGIN_ROOT}/docs/COMMIT_CONVENTION.md` — Commit message format
- `${CLAUDE_PLUGIN_ROOT}/docs/PULL_REQUEST.md` — PR format and template
