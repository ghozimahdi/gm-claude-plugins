---
description: "Ship a feature — run tests, review code, commit, and create PR."
argument-hint: "[feature-scope]"
allowed-tools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep", "Agent", "Skill"]
---

Ship a feature — run tests, review code, commit, and create PR.

Arguments: $ARGUMENTS (feature scope or leave empty)

## Phase 1 — Test

- Run `bin/rails test` (all tests)
- If tests fail, fix them before proceeding
- Run `bundle exec rubocop` — fix all offenses

## Phase 2 — Code Review

Use the **rubyku-reviewer** agent to audit:
- Architecture violations (thin controllers, no service classes, associations)
- Naming conventions (boolean, datetime, enum)
- Frontend compliance (Hotwire-first, no fetch, form helpers)
- Code quality (English comments, I18n, validations)
- Fix any critical/warning issues found

## Phase 3 — Commit

- Stage relevant files only
- Extract issue ID from branch name (`issues/42` → `#42`)
- Commit format: `[#42] Imperative description`
- Split into multiple commits if changes span different concerns

## Phase 4 — Push & PR

- Push to remote: `git push -u origin <branch>`
- Create PR with `gh pr create`:
  - Title: `[#42] Description`
  - Body: Related Issue, Summary, Changes checklist, Notes
  - Target: `main` (or parent issue branch for sub-issues)

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/CONTRIBUTING.md`
- `${CLAUDE_PLUGIN_ROOT}/docs/ARCHITECTURE.md`
- `${CLAUDE_PLUGIN_ROOT}/docs/CODE_OF_CONDUCT.md`
