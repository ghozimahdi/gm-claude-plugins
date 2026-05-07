# Contributing Guide

## Branch Naming

Format: `issues/<issue_id>`

```
issues/42
issues/58
issues/123
```

Do NOT include descriptions after the issue ID.

## Commit Messages

Format: `[#issue_id] Commit message`

```
[#100] Fix login timeout
[#42] Add notification mailer for status changes
[#58] Update form validation rules
[fix] Fix typo in translation file
```

Rules:
- Use imperative mood: Add, Fix, Update, Refactor, Remove
- If no GitHub issue exists, use `[fix]` tag
- Keep subject under 72 characters

## Pull Requests

### PR Title
Must match commit message format: `[#issue_id] Description`

### PR Guidelines
- Keep PRs small and focused (ideally under 300 lines)
- Use the provided PR template without modifying its structure
- Run `bundle exec rubocop` before submitting
- Run `bin/rails test` before submitting
- All code comments must be in English

### PR Target Rules
- Create branches from `main`
- Open PRs to `main`
- Sub-issues: branch from parent issue → PR to parent issue
- Final PR: parent issue branch → `main`

## Pre-Commit Checklist

1. `bundle exec rubocop` — zero errors
2. `bin/rails test` — all tests pass
3. Code comments in English
4. No service classes (use concerns)
5. Controllers are thin (HTTP only)
6. Query through parent associations
7. Use Rails form helpers (not raw HTML)
8. Hotwire-first (no fetch calls)

## Repository

- GitHub: auto-detected by `gh` from the current git remote (no hardcoded repo)
- Issue tracker: GitHub Issues — use `/github-issue` to create one
