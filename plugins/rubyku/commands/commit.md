---
description: "Create a git commit using project format: [#issue_id] Message"
argument-hint: "[message or leave empty for auto-detect]"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
model: haiku
---

Create a git commit using the project's commit format.

Arguments: $ARGUMENTS (optional commit message or hint)

## Commit Format

```
[#issue_id] Commit message
```

### Examples

```
[#100] Fix login timeout
[#42] Add notification mailer for status changes
[#58] Update form validation rules
[fix] Fix typo in translation file
```

## Steps

### 1. Analyze changes

- Run `git status` to see all changed/untracked files
- Run `git diff --staged` to see staged changes
- Run `git diff` to see unstaged changes
- Run `git branch --show-current` to get current branch (contains issue ID)

### 2. Stage files

- Stage only files that belong to the same logical change
- **NEVER** stage files containing secrets (`.env`, credentials, API keys)
- If changes span multiple concerns, suggest splitting into multiple commits
- Prefer staging specific files over `git add -A`

### 3. Determine issue ID

- Extract from branch name: `issues/42` → issue ID is `42`
- If `$ARGUMENTS` contains an issue ID, use it
- If no issue ID found, use `[fix]` tag

### 4. Write commit message

- **Format**: `[#issue_id] <imperative verb> <what changed>`
- Use imperative mood: Add, Fix, Update, Refactor, Remove
- Keep under 72 characters
- No period at end

### 5. Pre-commit checks

- Run `bundle exec rubocop <staged_files>` for .rb files
- Fix any offenses before committing
- Run `bin/rails test` for relevant test files

### 6. Commit

- Create the commit
- Show the commit hash and summary

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/CONTRIBUTING.md`
