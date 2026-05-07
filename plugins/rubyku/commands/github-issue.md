---
description: "Create a GitHub issue in the current repository."
argument-hint: "<brief summary>"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

Create a GitHub issue in the current GitHub repository (auto-detected by `gh` from the local git remote).

Arguments: $ARGUMENTS (brief summary for the issue title)

## Steps

1. If `$ARGUMENTS` is provided, use it as the issue title
2. Determine issue type from context:
   - Bug report — something broken
   - Feature request — new functionality
   - Improvement — enhance existing feature
3. Generate a well-structured issue body
4. Create using `gh issue create` (the repo is auto-detected from the current git checkout):

```bash
gh issue create \
  --title "Issue title" \
  --body "$(cat <<'EOF'
## Description

Brief explanation.

## Requirements / Steps to Reproduce

- Requirement or step 1
- Requirement or step 2

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Technical Notes (Optional)

Files to modify, architectural considerations.
EOF
)"
```

5. Report the created issue number and URL
