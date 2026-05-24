# UFIL (Ultimate Flutter Intelligent Layer)

A Claude Code plugin for Flutter Clean Architecture + Modularization with Dart MCP & LSP integration.

Supports both **modular** (multi-package + melos) and **single-module** project structures.

## What's Included

### Agents (3)

| Agent            | Role                                                | Model  |
| ---------------- | --------------------------------------------------- | ------ |
| `gm-architect`   | Plans features, designs architecture, creates tasks | Opus   |
| `gm-implementer` | Writes production code following standards          | Sonnet |
| `gm-reviewer`    | Reviews code for architecture violations            | Sonnet |

### Skills (8)

| Skill                 | Description                                                       |
| --------------------- | ----------------------------------------------------------------- |
| `clean-architecture`  | Model, DTO, repository, usecase, datasource patterns              |
| `bloc-pattern`        | Events, states (sub-state unions), BlocProvider, ScreenUtil        |
| `testing-conventions` | bloc_test, mocktail, Result helpers, directory structure           |
| `melos`               | Workspace config, scripts, modular vs single-package usage         |
| `auto-route`          | Modular (RouteProvider) vs non-modular (single AppRouter) routing  |
| `injectable-di`       | Modular (per-package DI + Config) vs non-modular (single injector) |
| `freezed`             | Model, DTO, state, event, failure, params patterns                 |
| `flutter-performance` | Const class vs helper, isolate vs compute, ListView optimization   |

### Commands (17)

| Command             | Description                                                       |
| ------------------- | ----------------------------------------------------------------- |
| `/init-project`     | Scaffold new project (modular or single-module)                   |
| `/generate-module`  | Generate feature module (domain/data/presentation)                |
| `/create-bloc`      | Create a BLoC (3 files: bloc/event/state)                         |
| `/build`            | Run code generation (freezed, injectable, auto_route, etc.)       |
| `/check`            | Static analysis + formatting before commit                        |
| `/test`             | Run tests and report results                                      |
| `/implement`        | Implement a feature following clean architecture                  |
| `/implement-batch`  | Implement multiple features in parallel (auto-scales agents)      |
| `/commit`           | Git commit with Conventional Commits (feat, fix, chore, etc.)     |
| `/create-pr`        | Create GitHub PR with structured summary and test plan            |
| `/ship`             | Tests + review + commit + PR (full pipeline)                      |
| `/review`           | Audit codebase for architecture violations                        |
| `/write-test`       | Write tests for a feature or file                                 |
| `/rtk-activate`     | Install RTK's global Claude Code hook (`rtk init -g`)             |
| `/rtk-deactivate`   | Remove RTK's global Claude Code hook (`rtk init -g --uninstall`)  |
| `/rtk-status`       | Show RTK binary version + whether the hook is currently active    |
| `/keep-alive`       | Prevent macOS from auto-sleeping (toggle on/off/status)           |

### Hooks

- **Pre-commit**: Auto-runs `fvm dart fix --apply` + `fvm dart format` + `fvm dart analyze` before every git commit
- **Post-edit**: Reminds to analyze after editing .dart files
- **SessionStart**: Auto-installs and initializes [rtk-ai/rtk](https://github.com/rtk-ai/rtk) — a CLI proxy that wraps shell commands run via Claude Code's Bash tool to cut LLM token usage 60-90% on `git`, `flutter`, `dart`, `melos`, etc.

### MCP Servers

- **Dart & Flutter MCP Server**: pub.dev search, error analysis, dependency management
- **Serena**: LSP intelligence — go-to-definition, find references, symbols

### LSP Server

- **Dart LSP**: Built-in diagnostics after every edit

### Other

- **.claudeignore**: Template for Flutter projects (skips generated code, build outputs, binary assets)

## Project Types

### Modular (multi-package + melos)

```
project/
├── app/                          # Main Flutter app
├── packages/
│   ├── library/library_common/   # Flavor, AppEnv, AppConfig
│   ├── domain/domain_common/     # Failure model, DataSourceConfig interface
│   ├── domain/domain_<feature>/  # Entities, repos, usecases
│   ├── data/data_common/         # Dio, interceptors, local storage
│   ├── data/data_<feature>/      # DTOs, datasources, repo impls
│   ├── presentation/feature_common/ # Theme, widgets, route providers
│   └── presentation/feature_<feature>/ # Pages, blocs, routes
└── pubspec.yaml                  # Melos workspace
```

### Single-module

```
project/
├── lib/
│   ├── core/                     # DI, router, error, network, theme
│   ├── features/<feature>/       # domain/ + data/ + presentation/
│   ├── common/                   # Shared across features
│   ├── injector.dart
│   ├── app_router.dart
│   └── main.dart
└── pubspec.yaml
```

## Installation

```bash
# From GitHub
/plugin marketplace add ghozimahdi/gm-claude-plugins
/plugin install ufil@gm-claude-plugins

# Or local plugin directory
cd /path/to/your-flutter-project
claude --plugin-dir /path/to/gm-claude-plugins/plugins/ufil
```

## Standards Enforced

- Clean Architecture (Presentation -> Domain -> Data)
- Bloc only (never Cubit or raw setState)
- Freezed for all models, states, events
- `@injectable` for DI (never manual getIt.register\*)
- Dio for networking
- Separate `@lazySingleton` mapper classes (never `.toModel()` on DTO)
- ScreenUtil for all sizing
- Sub-state freezed unions per async action (never flat bool flags)

## Version Detection

This plugin **auto-detects all versions** at project creation time — zero hardcoded dependency versions:

| What | Source | Example |
|------|--------|---------|
| Dart SDK constraint | `fvm dart --version` | `^3.7.0` |
| Flutter version (.fvmrc) | `fvm flutter --version` | `3.41.6` |
| All packages (melos, dio, freezed, etc.) | `fvm dart pub add` (pub.dev) | Always latest |

## Requirements

- **FVM** (required) — `dart pub global activate fvm`, then `fvm install <version> && fvm global <version>`
- Dart SDK 3.6+ (for pub workspaces / melos 7.x)
- Flutter SDK managed through FVM
- Serena (`pip install serena` or `uvx serena`) — for LSP intelligence
- **RTK** — auto-installed on first session

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) before submitting a pull request. All changes must go through the **fork + PR** workflow.

For collaboration inquiries: **ghozi.dev@gmail.com**

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
