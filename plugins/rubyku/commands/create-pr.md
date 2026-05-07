---
description: "Create a GitHub pull request with structured summary and changes."
argument-hint: "[base-branch] (default: main)"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

Create a GitHub pull request with structured description.

Arguments: $ARGUMENTS (optional base branch, defaults to `main`)

## Steps

### 1. Gather context

- Run `git status` — warn if uncommitted changes exist
- Run `git branch --show-current` — get current branch (contains issue ID)
- Determine base branch: `$ARGUMENTS` if provided, otherwise `main`
- Run `git log <base>..HEAD --oneline` — all commits in this branch
- Run `git diff <base>...HEAD --stat` — files changed summary
- Run `git diff <base>...HEAD` — full diff
- Push if needed: `git push -u origin <branch>`

### 2. Analyze changes

Read through all commits and the full diff to understand:
- What feature/fix/refactor was implemented
- Which files were changed
- Whether there are breaking changes

### 3. Generate PR title

Format: `[#issue_id] Short description`

- Short, under 72 characters
- Extract issue ID from branch name (`issues/42` → `#42`)
- If single commit, reuse its message as title

### 4. Generate PR body

```markdown
## Related Issue

- #issue_id

## Summary

- Primary change description
- Secondary change if applicable

## Changes

- [ ] `file_path.rb` — what changed
- [ ] `file_path.rb` — what changed

## Notes

<!-- Optional: migration steps, breaking changes -->
N/A
```

### 5. Create the PR

```bash
gh pr create \
  --title "[#42] Add notification mailer for status changes" \
  --body "$(cat <<'EOF'
## Related Issue

- #42

## Summary

- Add email notifications for record status changes

## Changes

- [ ] `app/models/record/notifications.rb` — concern for notification logic
- [ ] `app/mailers/record_mailer.rb` — mailer templates

## Notes

N/A
EOF
)"
```

### 6. Post-create

- Show the PR URL
- Remind about uncommitted changes if any

## PR Target Rules

- Default: PR to `main`
- Sub-issues: PR to parent issue branch
- Final: parent issue branch → `main`

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/CONTRIBUTING.md`
