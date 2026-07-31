---
name: commit
description: "Create a git commit using Conventional Commits format with ticket ID."
argument-hint: "[message]"
disable-model-invocation: true
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:commit`; in Codex invoke it as `$ufil:commit`. Resolve `UFIL_ROOT` to the
plugin root containing this skill; Claude Code may provide
`CLAUDE_PLUGIN_ROOT`, while Codex can resolve it from the installed skill path.

Create a git commit using **Conventional Commits** format with ticket ID.

Arguments: <requested arguments> (optional commit message or scope hint)

## Commit Format

```
<type> (TICKET-ID): <description>

[optional body]
```

### Types

| Type         | When to use                                              |
| ------------ | -------------------------------------------------------- |
| `feat`       | New feature or capability                                |
| `fix`        | Bug fix                                                  |
| `refactor`   | Code restructure without behavior change                 |
| `chore`      | Maintenance (deps update, config, CI, scripts)           |
| `docs`       | Documentation only                                       |
| `style`      | Formatting, whitespace, semicolons (no logic change)     |
| `test`       | Adding or updating tests                                 |
| `perf`       | Performance improvement                                  |
| `ci`         | CI/CD pipeline changes                                   |
| `build`      | Build system or external dependency changes              |
| `revert`     | Revert a previous commit                                 |

### Ticket ID

- **Required** — every commit must include the ticket ID (JIRA/Linear/GitHub Issue)
- Extract from current branch name if branch is named with ticket ID (e.g., `PROP-123`)
- If `<requested arguments>` contains a ticket ID, use it
- Ask the user if no ticket ID can be determined

### Examples

```
feat (PROP-123): add tenant list page with pagination
fix (PROP-456): handle null amount in checkout DTO
refactor (PROP-789): extract token refresh into interceptor
chore (PROP-100): bump freezed to 3.0.0
test (PROP-404): add bloc tests for detail page
```

## Steps

### 1. Analyze changes

- Run `git status` to see all changed/untracked files
- Run `git diff --staged` to see staged changes
- Run `git diff` to see unstaged changes
- Run `git branch --show-current` to get current branch name (may contain ticket ID)
- If nothing is staged, identify which files should be staged based on the logical unit of work

### 2. Stage files

- Stage only files that belong to the same logical change
- **NEVER** stage files that contain secrets (`.env`, credentials, API keys)
- If changes span multiple concerns, suggest splitting into multiple commits
- Prefer staging specific files over `git add -A`

### 3. Determine commit type and ticket ID

- Auto-detect type from the changes if no `<requested arguments>` provided:
  - New files in `features/` or new entity/bloc/page -> `feat`
  - Modified existing logic to fix behavior -> `fix`
  - Restructured without behavior change -> `refactor`
  - Only test files changed -> `test`
  - Only pubspec.yaml / dependency changes -> `chore`
  - Only docs/comments -> `docs`
- Extract ticket ID from branch name (e.g., branch `PROP-123` -> ticket `PROP-123`)
- If `<requested arguments>` is provided, use it as the description (still auto-detect type if not specified)

### 4. Write commit message

- **Subject line**: `<type> (TICKET-ID): <imperative verb> <what changed>` (max 72 chars)
  - Use imperative mood: "add", "fix", "remove", "update" (not "added", "fixes")
  - Lowercase after colon
  - No period at end
- **Body** (if needed): explain WHY, not what (the diff shows what)

### 5. Commit

- Run `dart fix --apply lib/` before committing (if .dart files are staged)
- Run `dart format lib test` (if .dart files are staged)
- Run `dart analyze lib test` (if .dart files are staged)
- Create the commit
- Show the commit hash and summary

## References

- `${UFIL_ROOT}/docs/COMMIT_CONVENTION.md` — Full commit message format and rules
- `${UFIL_ROOT}/docs/BRANCHING.md` — Git branching strategy
