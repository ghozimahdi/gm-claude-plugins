---
description: "Analyze a GitHub issue/ticket and create a Flutter implementation plan markdown before coding."
argument-hint: "<issue-id>"
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "Agent"]
model: opus
---

Analyze a GitHub issue/ticket and create a detailed Flutter implementation plan BEFORE coding.

Arguments: $ARGUMENTS (GitHub issue ID, e.g., `123` or `issues/123`)

## Step 0: Initialize Serena + Read docs (MANDATORY)

### 0a. Initialize Serena (auto-onboard if needed)

Run in order:

1. Call `mcp__serena__initial_instructions` — load Serena's instructions manual.
2. Call `mcp__serena__check_onboarding_performed` — check whether this project has been onboarded.
3. **If not onboarded:**
   - Probe for analyzable code: `find . -maxdepth 3 -type f -name '*.dart' -not -path '*/.*' | head -1`
   - If a Dart file is found → call `mcp__serena__onboarding` to build the symbol index and project memories (one-time cost per project).
   - If empty → SKIP onboarding, fall back to Glob/Grep/Read. Inform the user: "Serena onboarding skipped — no Dart code detected. Will auto-run the next time /plan or /implement is invoked after code exists."
4. **If already onboarded:** proceed.

Use Serena tools throughout planning for code exploration and symbol lookup. To force re-onboarding (e.g. after a major refactor), run `/serena-refresh`.

### 0b. Project Type Detection

- **Modular**: `packages/` directory exists at project root → multi-package project with melos
- **Single-module**: No `packages/` directory → single `lib/` project

### 0c. Read plugin docs

Read from `${CLAUDE_PLUGIN_ROOT}/docs/` (resolve via `echo $CLAUDE_PLUGIN_ROOT` first):

1. `${CLAUDE_PLUGIN_ROOT}/docs/ARCHITECTURE.md`
2. `${CLAUDE_PLUGIN_ROOT}/docs/NAMING_CONVENTIONS.md`
3. `${CLAUDE_PLUGIN_ROOT}/docs/BLOC_PATTERN.md`
4. `${CLAUDE_PLUGIN_ROOT}/docs/DOMAIN_LAYER.md`
5. `${CLAUDE_PLUGIN_ROOT}/docs/DATA_LAYER.md`
6. `${CLAUDE_PLUGIN_ROOT}/docs/PRESENTATION_LAYER.md`
7. `${CLAUDE_PLUGIN_ROOT}/docs/MAPPERS.md`

Also read relevant project guidelines from `docs/` in the working directory (if present).

Do NOT proceed until docs are read.

### Serena Usage During Planning

**ALWAYS prefer Serena tools over Grep/Glob/Read for exploring the codebase:**

- `mcp__serena__find_symbol` — find existing classes (`{Name}Model`, `{Action}UseCase`, `{Feature}Bloc`, …)
- `mcp__serena__find_declaration` — go to definition of a symbol
- `mcp__serena__find_referencing_symbols` — find all usages of a usecase/model/bloc
- `mcp__serena__find_implementations` — find implementations of a repository contract
- `mcp__serena__get_symbols_overview` — understand structure of a file (bloc events/states, repo methods)
- `mcp__serena__get_diagnostics_for_file` — check existing errors

Use these to:
- Locate existing models, DTOs, mappers, repos, usecases, blocs that the feature touches
- Trace bloc → usecase → repo → datasource dependencies
- Identify existing routes in `app_router.dart` and DI registrations in `injector.dart` / per-package `di.dart`
- For modular projects: identify which packages (`domain_*`, `data_*`, `feature_*`) are affected

## Steps

### 1. Fetch & understand the issue

Extract issue ID from `$ARGUMENTS` (strip `issues/` prefix if present, strip `#` prefix).

Detect the GitHub repo from the local git remote, then fetch:

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh issue view <issue_id> --repo "$REPO" --json title,body,labels,assignees,milestone,comments
```

Read and understand:
- **What** is being requested (feature, bug fix, refactor, etc.)
- **Why** it's needed (business context, user impact)
- **Acceptance criteria** (explicit or implied)
- **Constraints** (deadlines, dependencies, related issues)
- **API/data contracts** referenced (endpoints, schemas, sample payloads)

If the issue references other issues or PRs, fetch those too for context.

### 2. Scope estimation (feeds Step 1.5 of `/implement`)

From the issue, count:
- `pages` — distinct screens to build
- `blocs` — distinct blocs (usually = pages, sometimes shared)
- `useCases` — one per repository method called from blocs
- `features` — distinct feature modules touched
- `estimatedFiles` — rough total (models + DTOs + mappers + repos + datasources + blocs + pages + events + states + tests)

Record these in the plan so `/implement` can decide single-agent vs team mode from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/team-config.json` without recounting.

### 3. Explore the codebase

Based on the issue and project type, explore relevant parts:

**Modular projects** — for each affected feature, check:
- `packages/domain/domain_<feature>/` — existing models, repo contracts, usecases, `di.dart`
- `packages/data/data_<feature>/` — existing DTOs, datasources, repo impls, mappers
- `packages/presentation/feature_<feature>/` — existing blocs, pages, widgets
- `app/lib/injector.dart` — config wiring
- `app/lib/app_router.dart` — route registration
- root `pubspec.yaml` — `workspace:` list (package paths) and `melos:` scripts

**Single-module projects** — check:
- `lib/features/<feature>/domain/` — models, repos, usecases
- `lib/features/<feature>/data/` — DTOs, datasources, repo impls, mappers
- `lib/features/<feature>/presentation/` — blocs, pages, widgets
- `lib/core/` — shared error/result/network
- `lib/injector.dart` — DI registration
- `lib/app_router.dart` — routes

Use the **gm-architect** agent for complex architecture decisions or when planning a feature with 3+ pages or 3+ usecases.

### 4. Create the plan

Resolve the plugin root first: `echo $CLAUDE_PLUGIN_ROOT`

Create a plan markdown file inside the **plugin directory** (NOT the project directory):

```
${CLAUDE_PLUGIN_ROOT}/docs/plans/issue-<issue_id>.md
```

If `${CLAUDE_PLUGIN_ROOT}/docs/plans/` doesn't exist, create it.

**IMPORTANT**: Plans live in the plugin directory so they persist across sessions and are picked up by `/implement`.

### Plan Template

The plan MUST follow this structure:

```markdown
# Issue #<issue_id>: <issue title>

> Source: <GitHub issue URL>
> Created: <date>
> Status: Draft
> Project type: <modular | single-module>

## Summary

<1-3 sentences explaining what needs to be done and why>

## Acceptance Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>

## Scope Estimate

| Metric | Count |
|--------|-------|
| pages | N |
| blocs | N |
| useCases | N |
| features | N |
| estimatedFiles | N |

> Used by `/implement` Step 1.5 to decide single-agent vs team mode.

## Analysis

### Affected Areas

**Modular projects:**

| Package | Files/Components | Impact |
|---------|------------------|--------|
| `domain_<feature>` | models, repo contract, usecases, di.dart | New/Modified |
| `data_<feature>` | DTOs, mappers, datasource, repo impl, di.dart | New/Modified |
| `feature_<feature>` | bloc, events, states, page, widgets, di.dart | New/Modified |
| `app` | injector.dart, app_router.dart | Modified |

**Single-module projects:**

| Layer | Files/Components | Impact |
|-------|------------------|--------|
| Domain | `lib/features/<f>/domain/...` | New/Modified |
| Data | `lib/features/<f>/data/...` | New/Modified |
| Presentation | `lib/features/<f>/presentation/...` | New/Modified |
| App | `lib/injector.dart`, `lib/app_router.dart` | Modified |

### Existing Code Context

<Key findings from Serena-based exploration — existing models, blocs, repos that this feature relates to or reuses>

### Dependencies

- <Related issues, PRs, or features this depends on or blocks>
- <External SDKs/APIs introduced (Dio endpoints, Supabase tables, Firestore collections)>

## Implementation Plan

### 1. Domain Layer

- **Models** (`{Name}Model`, `@freezed`, `@Default()`, no nullable):
  - `<ModelName>` — fields: `<field:type>`
- **Params** (`{Action}Params`, only if ≥4 fields):
  - `<ActionParams>` — fields
- **Result** (`{Action}Result`, `@freezed`):
  - Modular: contains `@Default(Failure.noFailure()) Failure failure` + data
  - Single-module: contains data only (`Result<T>` wraps it)
- **Repository contract** (abstract class):
  - Modular: query → `Future<Result>`, action → `Future<Failure>`
  - Single-module: `Future<Result<T>>`
- **UseCases** (`@lazySingleton`, plain `call()`):
  - `<ActionUseCase>` — returns `<ReturnType>`

### 2. Data Layer

- **DTOs / Responses / Requests** (`@freezed`, nullable, `@JsonKey(name: '...')` on EVERY field):
  - `<Name>Dto`, `<Action>Response`, `<Action>Request`
- **Mappers** (`@lazySingleton`, separate classes — NEVER `.toModel()`):
  - `<Name>ModelMapper` — `mapFromData(<Name>Dto?)`
  - `<Action>ResultMapper` — `mapFromData(<Action>Response?)`
  - `<Action>RequestMapper` — `mapFromDomain(<Action>Params)` (only if request body)
- **Data source** (`@lazySingleton`, Dio only, NO try/catch):
  - `<Name>DataSource` — endpoints/methods
- **Repository impl** (`@LazySingleton(as: Contract)`):
  - Modular: `with FailureHandlerMixin`
  - Single-module: `with ErrorMapper`

### 3. Presentation Layer

- **Events** (`@freezed abstract class`, `Event` suffix on every redirect):
  - `_InitEvent` (MANDATORY, `@Default(<Feature>State()) state`)
  - `_<Action>Event` per async action
- **States** (`@freezed abstract class`, sub-state union per async action):
  - `<Action>IdleState`, `<Action>LoadingState`, `<Action>DoneState`, `<Action>ErrorState`
  - Error state carries `@Default(Failure.noFailure()) Failure failure`
- **Bloc** (`@injectable`, one per page):
  - Injected: `<usecases>`
  - Handlers: `_initEvent`, `_<action>Event` (camelCase of event class)
- **Page** (`@RoutePage()`, `BlocProvider`, ScreenUtil):
  - `<Feature>Page` — dispatches `init` event in `BlocProvider.create`

### 4. DI Wiring

- Modular: add `<Feature>Config extends AppConfig` + `di.dart` per package, register in `app/lib/injector.dart`
- Single-module: add to `lib/injector.dart`

### 5. Routing

- Add route to `app_router.dart` (modular: `app/lib/`; single: `lib/`)

### 6. Tests

- Bloc test (per bloc, all events)
- Repository test (mapper + datasource integration)
- UseCase test (delegates to repo)
- DTO test (`fromJson` / `toJson` round-trip)

## Implementation Order

1. [ ] Domain models + Params + Result
2. [ ] Repository contract + UseCases
3. [ ] DTOs + Mappers
4. [ ] Data source
5. [ ] Repository impl
6. [ ] Bloc events + states
7. [ ] Bloc
8. [ ] Page + Widgets
9. [ ] DI wiring (Config + di.dart) + Route
10. [ ] Code generation (`melos run build` or `dart run build_runner`)
11. [ ] `dart fix --apply` + `dart format` + `dart analyze`
12. [ ] Tests

## Risks & Notes

- <Potential issues, edge cases, shared bloc state concerns>
- <Questions that need clarification from team>
- <Performance concerns (large lists, network bursts, image-heavy pages)>
```

### 5. Present the plan

After creating the file, display:
- The full plan to the user
- The file path: `${CLAUDE_PLUGIN_ROOT}/docs/plans/issue-<issue_id>.md`
- Ask if the plan looks good or needs adjustments

Tell the user:
```
Plan saved to ${CLAUDE_PLUGIN_ROOT}/docs/plans/issue-<issue_id>.md

When ready to implement, run:
  /implement <issue_id>

`/implement` will load this plan and use the Scope Estimate to decide
single-agent vs team mode (per .claude-plugin/team-config.json).
```

## Important Rules

- **DO NOT write any implementation code** — this is planning only
- **DO explore the codebase thoroughly with Serena** — the plan must be grounded in real symbols/files
- **DO check naming conventions** — class/file suffixes (`UseCase`, `DataSource`, `Mapper`, `Bloc`, …) must follow project standards
- **DO identify ALL affected packages** (modular) or feature folders (single-module)
- **Pages MUST NOT call UseCases directly** — every async action goes through a Bloc, even one-shot ops like logout/refresh/delete
- **Separate mapper classes** — NEVER `.toModel()` on DTO, NEVER extension functions
- **Modular**: query → `Future<Result>` (Failure + data), action → `Future<Failure>`
- **Single-module**: repo returns `Future<Result<T>>` with mapped domain model

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview
- `${CLAUDE_PLUGIN_ROOT}/docs/NAMING_CONVENTIONS.md` — File and class naming
- `${CLAUDE_PLUGIN_ROOT}/docs/DOMAIN_LAYER.md` — Domain patterns
- `${CLAUDE_PLUGIN_ROOT}/docs/DATA_LAYER.md` — Data patterns
- `${CLAUDE_PLUGIN_ROOT}/docs/PRESENTATION_LAYER.md` — Presentation patterns
- `${CLAUDE_PLUGIN_ROOT}/docs/BLOC_PATTERN.md` — Bloc events, states, sub-state unions
- `${CLAUDE_PLUGIN_ROOT}/docs/MAPPERS.md` — Mapper rules
- `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/team-config.json` — team mode thresholds
