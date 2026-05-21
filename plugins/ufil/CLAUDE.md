# UFIL (Ultimate Flutter Intelligent Layer)

This plugin provides GM's standardized Flutter development environment for Claude Code.
Supports both **modular** (multi-package + melos) and **single-module** project structures.

## What's Included

- **3 Agents**: Architect, Implementer, Reviewer
- **8 Skills**: clean-architecture, bloc-pattern, testing-conventions, melos, auto-route, injectable-di, freezed, flutter-performance
- **18 Commands**: init-project, generate-module, create-bloc, build, check, test, plan, implement, implement-batch, ship, review, write-test, commit, create-pr, rtk-activate, rtk-deactivate, rtk-status, serena-refresh
- **Team Config**: `.claude-plugin/team-config.json` — thresholds + max parallel agents. `/implement` auto-detects ticket scope and switches to team mode (architect → parallel implementers in worktrees) when thresholds are exceeded. Tune without editing command files.
- **Hooks**: Auto dart fix + format + analyze before git commit
- **MCP Servers**: Dart & Flutter MCP Server + Serena LSP (auto-onboards on first `/plan`, `/implement`, or `/implement-batch` when Dart code is detected; manual refresh via `/serena-refresh`)
- **Dart LSP**: Code intelligence (go-to-definition, find references, diagnostics)
- **RTK auto-install**: [rtk-ai/rtk](https://github.com/rtk-ai/rtk) CLI proxy installed and globally registered on first session — cuts Claude Code token usage 60-90% on `git`, `flutter`, `dart`, `melos`, etc.
- **.claudeignore**: Template for Flutter projects

## Project Types

| Type              | Structure                                              | DI                                 | Error Handling                                                                         | Mappers                                                           |
| ----------------- | ------------------------------------------------------ | ---------------------------------- | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| **Modular**       | `app/` + `packages/{library,domain,data,presentation}` | Per-package di.dart + Config class | Query: Result model (Failure + data) / Action: `Future<Failure>` + FailureHandlerMixin | Separate `@lazySingleton` mapper classes (NO `.toModel()` on DTO) |
| **Single-module** | `lib/{core,features,common}`                           | Single injector.dart               | `Result<T>` + ErrorMapper                                                              | Separate `@lazySingleton` mapper classes (NO `.toModel()` on DTO) |

## Standards

- Clean Architecture (Presentation -> Domain -> Data)
- Bloc for state management (never Cubit)
- **Pages MUST NOT call UseCases directly** — every async action (even logout/refresh/delete) goes through a Bloc. Pages only dispatch events and read state. Importing a UseCase or calling `getIt<XUseCase>()` from a page is ALWAYS wrong, no exceptions.
- Freezed for all models, states, events
- Injectable for DI (never manual getIt.register\*)
- Dio for networking — baseUrl set via NetworkModule, not in datasources
- **BOTH project types**: separate `@lazySingleton` mapper classes (`{Name}ModelMapper`, `{Action}ResultMapper`, `{Action}RequestMapper`) — NEVER `.toModel()` on DTO, NEVER extension functions
- Modular: query → `Future<Result>` (Result contains `Failure` + data), action → `Future<Failure>` directly
- Modular error chain: DioException → DioErrorInterceptor → AppException → FailureHandlerMixin → Failure
- Single-module: repository returns `Future<Result<T>>` where `T` is the mapped domain model/output (mapper runs inside repo before wrapping in `Result.ok(...)`)
- Single-module error chain: DioException → DioErrorInterceptor → AppException → ErrorMapper mixin → Failure → wrapped in `Result.error(failure)`
- ScreenUtil for responsive sizing
- **Colors MUST use generated `AppColors` from `flutter_gen`** — NEVER `Color(0xFF...)`, NEVER `Colors.red`/`Colors.blue`/`Colors.grey`, NEVER inline hex. Source of truth is `colors.xml` (Android-style XML consumed by flutter_gen → `colors.gen.dart`). Applies to BOTH project types — modular reads from `packages/presentation/feature_common/assets/colors/colors.xml` (regen via `melos run generate:assets`); single-module reads from `assets/colors/colors.xml` (regen via `dart run build_runner build -d`). Adding a new color = edit `colors.xml` first, regenerate, then use `AppColors.xxx`.
- Single-module: encrypt_shared_preferences for local storage
- Modular: SharedPreferences via `@preResolve` LocalModule in data_common

## Usage

```bash
# Quick start (local plugin directory)
cd /path/to/your-flutter-project
claude --plugin-dir /path/to/gm-claude-plugins/plugins/ufil

# Or add via marketplace (local)
/plugin marketplace add /path/to/gm-claude-plugins

# Or from GitHub
/plugin marketplace add ghozimahdi/gm-claude-plugins

# Install from marketplace
/plugin install ufil@gm-claude-plugins

# Scaffold new project
/init-project my_app --package com.example.app --modular
/init-project my_app --package com.example.app --single

# Generate feature module
/generate-module tenant
/generate-module payment --layer domain

# Create a single BLoC (3 files: bloc/event/state)
/create-bloc home
/create-bloc home --actions get_transaction,add_transaction --alert
/create-bloc property_detail --with-failure --actions get_property_detail,delete_property

# Plan a ticket BEFORE implementing (uses Serena, saves plan markdown)
/plan 123
/plan issues/456

# Implement using the saved plan (auto-detects scope + team mode)
/implement 123

# Commit with Conventional Commits
/commit
/commit fix login timeout issue

# Implement multiple features in parallel (auto-scales agents)
/implement-batch tenant payment
/implement-batch auth tenant notification

# Create pull request
/create-pr
/create-pr develop

# Manage RTK token-saving hook
/rtk-status
/rtk-activate
/rtk-deactivate

# Force Serena re-onboarding after a large refactor or branch switch
/serena-refresh
```

## Serena Onboarding Behavior

Serena's project index (symbols, references, memories) is bootstrapped lazily:

- **`/init-project`** does NOT run onboarding — the scaffold is freshly generated and Serena would index boilerplate that the user is about to rewrite.
- **`/plan`, `/implement`, `/implement-batch`** check `mcp__serena__check_onboarding_performed` on every invocation:
  - Onboarded → proceed.
  - Not onboarded AND Dart files detected → call `mcp__serena__onboarding` once (transparent to the user; takes <1 min on most projects).
  - Not onboarded AND no Dart files → skip onboarding, fall back to Glob/Grep/Read, notify the user that it will retry next time.
- **`/serena-refresh`** forces re-onboarding when the index goes stale (large refactor, package restructuring, project-type switch).

The plugin intentionally does NOT ship a pre-built `.serena/` folder — onboarding data is project-specific (symbols, file paths, memories about THIS codebase), so a generic seed would be useless or actively misleading.
