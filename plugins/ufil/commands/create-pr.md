---
description: "Create a GitHub pull request with structured summary and changes."
argument-hint: "[base-branch] (default: develop)"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

Create a GitHub pull request with structured description.

Arguments: $ARGUMENTS (optional base branch, defaults to `develop`)

## Steps

### 1. Gather context

- Run `git status` to check for uncommitted changes — warn if any exist
- Run `git branch --show-current` to get current branch name (this is the ticket ID)
- Determine base branch: use `$ARGUMENTS` if provided, otherwise `develop`
- Run `git log <base>..HEAD --oneline` to see all commits in this branch
- Run `git diff <base>...HEAD --stat` to see files changed summary
- Run `git diff <base>...HEAD` to see full diff
- Check if remote tracking branch exists, push if needed (`git push -u origin <branch>`)

### 2. Analyze changes

Read through all commits and the full diff to understand:
- What feature/fix/refactor was implemented
- Which files were changed
- Whether there are breaking changes

### 3. Generate PR title

Follow commit format:
```
<type> (TICKET-ID): <short description>
```

- Short, under 72 characters
- Use ticket ID from branch name
- If multiple commits with different types, use the most significant one
- If single commit, reuse its message as the title

### 4. Generate PR body

Use this template:

```markdown
## Related Issue

- [TICKET-ID](https://your-org.atlassian.net/browse/TICKET-ID)

## Summary

- <primary change description>
- <secondary change if applicable>

## Changes

- [ ] `file_path.dart` — <what changed>
- [ ] `file_path.dart` — <what changed>

## Notes

<!-- Optional: migration steps, breaking changes, screenshots -->
```

Rules for the body:
- **Related Issue** — extract ticket ID from branch name, link to JIRA/Linear
- **Summary** — 1-3 bullet points, WHAT and WHY
- **Changes** — flat checklist with actual file paths, only files that changed
- **Notes** — optional, for migration steps, breaking changes, screenshots. Put `N/A` if none

### 5. Create the PR

- Use `gh pr create` with the title and body
- If the current branch has no upstream, push first: `git push -u origin <branch>`
- After creation, display the PR URL

### 6. Post-create

- Show the PR URL for easy access
- If there were uncommitted changes warned in step 1, remind to commit and push them

## Examples

**Feature PR:**
```
Title: feat (PROP-123): add tenant list with pagination

## Related Issue

- [PROP-123](https://your-org.atlassian.net/browse/PROP-123)

## Summary

- Add tenant list page with infinite scroll pagination
- Implements full clean architecture stack: model, DTO, repository, usecase, bloc, page

## Changes

- [x] `tenant_model.dart` — new freezed model
- [x] `tenant_repository.dart` — contract with getTenants
- [x] `tenant_dto.dart` — nullable fields, @JsonKey, toModel()
- [x] `tenant_remote_datasource.dart` — GET /tenants
- [x] `tenant_repository_impl.dart` — with ErrorMapper
- [x] `tenant_bloc.dart` — started/loadMore events
- [x] `tenant_page.dart` — PagedSliverList with BlocProvider

## Notes

N/A
```

**Bug fix PR:**
```
Title: fix (PROP-456): handle null amount in checkout response

## Related Issue

- [PROP-456](https://your-org.atlassian.net/browse/PROP-456)

## Summary

- Fix crash when API returns null amount for pending payments

## Changes

- [x] `payment_dto.dart` — add null safety in toModel()
- [x] `checkout_page.dart` — add empty state for zero amount

## Notes

N/A
```

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/PULL_REQUEST.md` — PR format and template
- `${CLAUDE_PLUGIN_ROOT}/docs/COMMIT_CONVENTION.md` — Commit message format
- `${CLAUDE_PLUGIN_ROOT}/docs/BRANCHING.md` — Git branching strategy
