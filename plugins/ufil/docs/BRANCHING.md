# Branching Strategy

This document describes the branching model and workflow for the project.

## Branch Structure

```
main (production)
 │
 ├── develop (development/integration)
 │    │
 │    └── TICKET-ID  (e.g., PROP-123)
 │
 └── staging (pre-production)
```

## Branch Types

| Branch      | Purpose                             | Deploys To  |
| ----------- | ----------------------------------- | ----------- |
| `main`      | Production-ready code               | Production  |
| `staging`   | Pre-production testing              | Staging     |
| `develop`   | Integration branch for development  | Development |
| `TICKET-ID` | Feature/fix work per ticket         | —           |

## Branch Naming

Feature/fix branches use the **ticket ID** directly:

```
TICKET-ID
```

### Examples

```
PROP-123
PROP-456
PROP-789
```

Simple and clear — each branch is one ticket.

## Workflow

### 1. Start New Work

```bash
git checkout develop
git pull origin develop
git checkout -b PROP-123
```

### 2. Develop & Commit

```bash
# ... write code ...
git add <files>
git commit -m "feat (PROP-123): add tenant list page"

# ... more work ...
git commit -m "feat (PROP-123): add tenant detail page"
```

### 3. Push & Create PR

```bash
git push -u origin PROP-123
gh pr create --base develop --title "feat (PROP-123): add tenant list with pagination"
```

### 4. Code Review & Merge

- PR reviewed by team
- Squash merge into `develop`
- Branch auto-deleted after merge

### 5. Deploy to Staging

```bash
# Merge develop → staging
git checkout staging
git pull origin staging
git merge develop
git push origin staging
```

### 6. Deploy to Production

```bash
# Merge staging → main
git checkout main
git pull origin main
git merge staging
git push origin main
git tag v1.2.0
git push origin v1.2.0
```

## Hotfix (Urgent Production Fix)

For urgent production bugs, branch from `main` directly:

```bash
git checkout main
git pull origin main
git checkout -b PROP-999
# ... fix ...
git commit -m "fix (PROP-999): handle crash on null amount"
git push -u origin PROP-999
gh pr create --base main --title "fix (PROP-999): handle crash on null amount"
```

After merge to `main`:

```bash
# Sync back to develop and staging
git checkout develop && git merge main && git push
git checkout staging && git merge main && git push
```

## Merge Strategy

| From         | To          | Strategy         | Command                |
| ------------ | ----------- | ---------------- | ---------------------- |
| `TICKET-ID`  | `develop`   | **Squash merge** | `gh pr merge --squash` |
| `develop`    | `staging`   | **Merge commit** | `git merge develop`   |
| `staging`    | `main`      | **Merge commit** | `git merge staging`   |
| `TICKET-ID`  | `main`      | **Squash merge** | Hotfix only            |

### Why Squash for Feature Branches

- Keeps `develop` history clean — one commit per ticket
- PR title becomes the commit message
- Individual WIP commits preserved in PR history

### Why Merge Commit for Promotions

- Preserves the merge point for easy rollback
- Clear audit trail of what was promoted

## Keeping Branches Up to Date

```bash
# Update feature branch with latest develop
git checkout PROP-123
git fetch origin
git rebase origin/develop
git push --force-with-lease
```

## Branch Protection Rules

### `main`

- Require PR review (at least 1 approval)
- Require status checks to pass (CI/CD)
- No direct pushes
- No force pushes

### `staging`

- Require status checks to pass
- Only merge from `develop` or hotfix

### `develop`

- Require PR review (at least 1 approval)
- Require status checks to pass
- No direct pushes

## Clean Up

After PR merged, delete the ticket branch:

```bash
# Or let GitHub auto-delete (recommended)
git branch -d PROP-123
git push origin --delete PROP-123
```

## Flow Diagram

```
PROP-123 ──squash──→ develop ──merge──→ staging ──merge──→ main
PROP-456 ──squash──┘                                        │
                                                            │
PROP-999 (hotfix) ──────────────────────────squash──────────┘
                                                            │
                                        sync back ←─────────┘
```

## Quick Reference

```bash
# Start new work
git checkout develop && git pull && git checkout -b PROP-123

# Commit
git commit -m "feat (PROP-123): description"

# Push & PR
git push -u origin PROP-123
gh pr create --base develop --title "feat (PROP-123): description"

# Promote to staging
git checkout staging && git pull && git merge develop && git push

# Promote to production
git checkout main && git pull && git merge staging && git push && git tag v1.x.x
```
