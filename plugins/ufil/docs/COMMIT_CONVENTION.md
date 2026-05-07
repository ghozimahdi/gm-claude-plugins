# Commit Convention

This document describes the commit message format and rules for the project.

## Format

```
<type> (TICKET-ID): <description>

[optional body]
```

Ticket ID (JIRA/Linear/GitHub Issue) is **required** in every commit.

## Types

| Type       | When to Use                                          |
| ---------- | ---------------------------------------------------- |
| `feat`     | New feature or capability                            |
| `fix`      | Bug fix                                              |
| `refactor` | Code restructure without behavior change             |
| `chore`    | Maintenance (deps update, config, CI, scripts)       |
| `docs`     | Documentation only                                   |
| `style`    | Formatting, whitespace, semicolons (no logic change) |
| `test`     | Adding or updating tests                             |
| `perf`     | Performance improvement                              |
| `ci`       | CI/CD pipeline changes                               |
| `build`    | Build system or external dependency changes          |
| `revert`   | Revert a previous commit                             |

## Subject Line Rules

- Max **72 characters**
- Use **imperative mood**: "add", "fix", "remove", "update" (NOT "added", "fixes", "removed")
- **Lowercase** after colon
- **No period** at end

```
# Good
feat (PROP-123): add tenant list page with pagination
fix (PROP-456): handle null amount in checkout DTO
refactor (PROP-789): extract token refresh into interceptor
chore (PROP-100): bump freezed to 3.0.0
test (PROP-404): add bloc tests for detail page

# Bad
feat: add tenant list page                        # missing ticket ID
feat (PROP-123): Added the tenant list page.      # past tense, period
Fix PROP-456: payment null amount bug             # wrong format
```

## Body (Optional)

Explain **WHY**, not what (the diff shows what):

```
feat (PROP-123): add tenant list page with pagination

Implements infinite scroll using PagingState in TenantBloc
with PagedSliverList in the UI.
```

```
fix (PROP-456): handle null amount in checkout DTO

The API returns null for amount when payment is pending.
Added @Default(0) fallback in toModel() mapper.
```

## Breaking Changes

Add `!` after type:

```
feat! (PROP-999): replace token storage with secure enclave

BREAKING CHANGE: Old tokens will be invalidated after this update.
Users must re-login.
```

## Pre-Commit Checklist

Before committing `.dart` files, the following are run automatically via hooks:

1. `fvm dart fix --apply lib/`
2. `fvm dart format lib test`
3. `fvm dart analyze lib test`

If any step fails, the commit is blocked. Fix the issues and re-commit.

## Staging Rules

- Stage only files that belong to the **same logical change**
- **NEVER** stage files containing secrets (`.env`, credentials, API keys)
- If changes span multiple concerns, **split into multiple commits**
- Prefer staging specific files over `git add -A`

## Examples

### New feature

```
feat (PROP-123): add tenant list page with pagination

Implements infinite scroll using PagingState in TenantBloc
with PagedSliverList in the UI.
```

### Bug fix

```
fix (PROP-456): handle null amount in checkout DTO

The API returns null for amount when payment is pending.
Added @Default(0) fallback in toModel() mapper.
```

### Refactor

```
refactor (PROP-789): extract token refresh into interceptor

Moves token refresh logic from AuthRepositoryImpl into
a dedicated DioInterceptor for reuse across all API calls.
```

### Dependency update

```
chore (PROP-100): bump freezed to 3.0.0 and run build
```

### Tests

```
test (PROP-404): add bloc tests for detail and delete flows
```

### Multiple commits for same ticket

```
feat (PROP-123): add tenant model and repository contract
feat (PROP-123): add DTO, datasource, and repository impl
feat (PROP-123): add bloc, page, and route
```
