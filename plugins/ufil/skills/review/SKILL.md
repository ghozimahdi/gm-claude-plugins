---
name: review
description: "Review the current codebase for architecture violations. Use for code quality audits."
disable-model-invocation: true
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:review`; in Codex invoke it as `$ufil:review`. Resolve `UFIL_ROOT` to the
plugin root containing this skill; Claude Code may provide
`CLAUDE_PLUGIN_ROOT`, while Codex can resolve it from the installed skill path.

Review the current codebase for architecture violations.

## Project Type Detection (MUST DO FIRST)
- **Modular**: `packages/` directory exists → multi-package with melos
- **Single-module**: No `packages/` directory → single `lib/` project

## Shared Checks (Both Types)

1. **Wrong patterns:**
   - Cubit instead of Bloc
   - equatable instead of freezed
   - Manual DI registration instead of @injectable
   - Presentation layer importing from data layer directly
   - Specific exception catches in repositories (should be generic `catch (e)`)
   - try/catch in datasources
   - Arrow (`=>`) in method/function/getter bodies
   - Flat bool flags (isLoading, hasError) instead of sub-state freezed unions
   - Local UI state when Bloc exists
   - DTO mapper as extension instead of `.toModel()` method
   - DTO field without `@JsonKey(name: '...')`

2. **Missing requirements:**
   - Models with nullable fields (should use @Default)
   - DTOs with non-nullable fields (should be nullable)
   - Pages without ScreenUtil
   - Bloc without @injectable annotation
   - Missing BlocProvider

## Non-Modular Specific Checks

- Either/fpdart instead of Result<T>
- flutter_secure_storage or SharedPreferences instead of encrypt_shared_preferences
- Repository impl without `with ErrorMapper`
- Missing `Result.ok()` / `Result.error()` wrapping

## Modular Specific Checks

- Using Result<T> pattern (should use Result model with Failure + data)
- Query method returning `Future<Failure>` instead of `Future<Result>` (if method needs to return data, must use Result)
- Missing Result model in domain (every repo method needs `@freezed` Result containing `Failure` + data)
- Using ErrorMapper (should use FailureHandlerMixin)
- Using `.toModel()` on DTO (should use separate `@lazySingleton` mapper class)
- Using `try/on Failure catch` in Bloc (should `switch` on `result.failure`)
- Missing error chain (AppException + DioErrorInterceptor + FailureHandlerMixin) in `data_common`
- Single injector.dart for all packages (each package needs own `di.dart`)
- Missing Config class in a package
- DI initialization out of order (must be domain -> data -> presentation)
- encrypt_shared_preferences in modular (modular uses SharedPreferences via `data_common`)

## Report Format

| File | Line | Issue | Severity | Fix |

Run analyzer at the end to confirm zero issues.

## References

- `${UFIL_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
- `${UFIL_ROOT}/docs/BLOC_PATTERN.md` — Bloc events, states, sub-state unions
- `${UFIL_ROOT}/docs/CODE_STYLE.md` — Import ordering and code formatting
- `${UFIL_ROOT}/docs/NAMING_CONVENTIONS.md` — File and class naming standards
- `${UFIL_ROOT}/docs/DATA_LAYER.md` — Data layer patterns, DTOs, datasources
- `${UFIL_ROOT}/docs/DOMAIN_LAYER.md` — Domain layer patterns and conventions
