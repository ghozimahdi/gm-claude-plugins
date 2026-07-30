---
name: write-test
description: "Write tests for a feature or file following GM testing conventions."
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:write-test`; in Codex invoke it as `$ufil:write-test`. Resolve
`UFIL_ROOT` to the plugin root containing this skill; Claude Code may provide
`CLAUDE_PLUGIN_ROOT`, while Codex can resolve it from the installed skill path.

Write tests for a feature or file following GM testing conventions.

Arguments: <requested arguments> (feature name, file path, or "all" to scan for missing tests)

## Steps

### 0. Detect project type
- **Modular**: `packages/` directory exists → multi-package with melos
- **Single-module**: No `packages/` directory → single `lib/` project

### 1. Identify what needs tests
- Non-modular: find blocs, repositories, usecases, and DTOs in `lib/features/<feature>/`
- Modular: find across `packages/domain/domain_<feature>/`, `packages/data/data_<feature>/`, `packages/presentation/feature_<feature>/`
- If `<requested arguments>` is a file path, write tests for that specific file
- If `<requested arguments>` is `all`, scan all features and compare against existing tests to find missing ones

### 2. Read source files
Before writing any test, read the file under test and its related types (state, event, model, params).

### 3. Write tests

**Directory structure (non-modular):**
```
test/features/<feature>/
├── data/           # repository_impl_test.dart, dto_test.dart
├── domain/         # usecase_test.dart
└── presentation/   # bloc_test.dart
```

**Directory structure (modular — per-package):**
```
packages/domain/domain_<feature>/test/    # model_test, usecase_test
packages/data/data_<feature>/test/        # dto_test, repository_impl_test
packages/presentation/feature_<feature>/test/  # bloc_test
```

**Bloc tests**: `blocTest<BlocType, StateType>` from `bloc_test` + `mocktail`
- Test: initial state, success path, error path, each event handler
- Do NOT use `seed()` with async handlers — use `act()` + `skip`
- Non-modular: use `switch` on Result, `tOk()`/`tError()` helpers
- Modular query: return `Future<Result>`. Mock with `Result(items: [...])` for success, `Result(failure: Failure.xxx())` for failure
- Modular action: return `Future<Failure>`. Mock with `Failure.noFailure()` for success, `Failure.xxx()` for failure

**Repository tests**: Mock datasource, test success/error paths
- Non-modular: `switch` on Result
- Modular query: expect Result with data on success, Result with specific `Failure` on error
- Modular action: expect `Failure.noFailure()` on success, specific `Failure` on error

**UseCase tests**: Mock repository, verify delegation

**DTO tests**: `fromJson` valid data, null fields, `toModel` mapping

### 4. Code rules
- No arrow (`=>`) for method/function/getter bodies
- Named parameters need `any(named: 'paramName')` in mocks
- Add `registerFallbackValue(...)` for custom types used with `any()`

### 5. Verify
- Run `dart fix --apply test/`
- Run tests for the feature
- Run analyzer — fix ALL warnings in test files
- Run formatter

## References

- `${UFIL_ROOT}/docs/BLOC_PATTERN.md` — Bloc events, states, sub-state unions
- `${UFIL_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
