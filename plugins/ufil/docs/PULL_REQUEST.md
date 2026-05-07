# Pull Request Convention

This document describes the pull request format, template, and rules for the project.

## PR Title

Follow the same commit format:

```
<type> (TICKET-ID): <short description>
```

- Max **72 characters**
- If multiple commits with different types, use the most significant one
- If single commit, reuse its message as the title

```
# Good
feat (PROP-123): add tenant list with pagination
fix (PROP-456): handle checkout timeout
refactor (PROP-789): extract token refresh logic

# Bad
Tenant list                              # no type, no ticket
feat: add stuff                          # no ticket, too vague
feat (PROP-123): Add Tenant List Page.   # uppercase, period
```

## PR Body Template

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

## Body Rules

1. **Related Issue** — required, link to JIRA/Linear/GitHub Issue
2. **Summary** — 1-3 bullet points, WHAT and WHY
3. **Changes** — checklist with actual file paths, only include changed files
4. **Notes** — optional, for migration steps, breaking changes, screenshots

## PR Size Guidelines

| Size    | Files Changed | Recommendation                         |
| ------- | ------------- | -------------------------------------- |
| Small   | 1-5           | Ideal — easy to review                 |
| Medium  | 6-15          | Acceptable — one feature across layers |
| Large   | 16-30         | Split if possible                      |
| X-Large | 30+           | Must split                             |

## Examples

### New Feature PR

```
Title: feat (PROP-123): add tenant list with pagination

## Related Issue

- [PROP-123](https://your-org.atlassian.net/browse/PROP-123)

## Summary

- Add tenant list page with infinite scroll pagination
- Implements full clean architecture stack: model, DTO, repository, usecase, bloc, page

## Changes

- [x] `tenant_model.dart` — new freezed model with id, name, phone, unit fields
- [x] `tenant_repository.dart` — contract with getTenants(propertyId, page)
- [x] `get_tenants_usecase.dart` — delegates to repository
- [x] `tenant_dto.dart` — nullable fields, @JsonKey mapping, toModel()
- [x] `tenant_remote_datasource.dart` — GET /tenants with pagination params
- [x] `tenant_repository_impl.dart` — with ErrorMapper, maps DTO list to models
- [x] `tenant_bloc.dart` — handles started/loadMore events with PagingState
- [x] `tenant_page.dart` — PagedSliverList with BlocProvider

## Notes

N/A
```

### Bug Fix PR

```
Title: fix (PROP-456): handle null amount in checkout response

## Related Issue

- [PROP-456](https://your-org.atlassian.net/browse/PROP-456)

## Summary

- Fix crash when API returns null amount for pending payments
- Added @Default(0) fallback in PaymentDto.toModel()

## Changes

- [x] `payment_dto.dart` — add null safety in toModel() for amount field
- [x] `checkout_page.dart` — add empty state for zero amount

## Notes

N/A
```

### Refactor PR

```
Title: refactor (PROP-789): extract token refresh into dio interceptor

## Related Issue

- [PROP-789](https://your-org.atlassian.net/browse/PROP-789)

## Summary

- Move token refresh logic from AuthRepositoryImpl into a dedicated DioInterceptor
- Enables automatic token refresh for all API calls, not just auth endpoints

## Changes

- [x] `token_refresh_interceptor.dart` — new interceptor with refresh logic
- [x] `network_module.dart` — add TokenRefreshInterceptor to Dio
- [x] `auth_repository_impl.dart` — remove manual token refresh code

## Notes

N/A
```

### Multiple Tickets PR

```
Title: feat (PROP-123): add tenant and payment modules

## Related Issue

- [PROP-123](https://your-org.atlassian.net/browse/PROP-123)
- [PROP-124](https://your-org.atlassian.net/browse/PROP-124)

## Summary

- Add tenant list and detail pages
- Add payment checkout flow

## Changes

- [x] `tenant_model.dart` — tenant model
- [x] `tenant_bloc.dart` — tenant bloc with list/detail
- [x] `payment_model.dart` — payment model
- [x] `checkout_page.dart` — checkout page

## Notes

PROP-124 depends on PROP-123 tenant module being merged first.
```
