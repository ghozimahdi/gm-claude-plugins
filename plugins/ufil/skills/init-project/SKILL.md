---
name: init-project
description: "Scaffold a new Flutter project with GM clean architecture. Supports modular (multi-package + melos) and single-module structures."
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:init-project`; in Codex invoke it as `$ufil:init-project`. Resolve
`UFIL_ROOT` to the plugin root containing this skill; Claude Code may provide
`CLAUDE_PLUGIN_ROOT`, while Codex can resolve it from the installed skill path.

Scaffold a new Flutter project with GM clean architecture.

**Prerequisites:** FVM must be installed (`dart pub global activate fvm`) with a global Flutter version set.

**Scripts available at `${UFIL_ROOT}/scripts/`:**

- `init-modular.sh <name> [package]` — scaffold modular project (package defaults to `com.example.app`)
- `init-single.sh <name> [package]` — scaffold single-module project (package defaults to `com.example.app`)

Scripts auto-detect versions:

- **Dart SDK** constraint from `fvm dart --version` (e.g., `^3.7.0`)
- **Flutter version** in `.fvmrc` from `fvm flutter --version` (e.g., `3.41.6`)
- **Melos** `^7.0.0` as dev_dependency with config under `melos:` key

Run the appropriate script first, then follow up with manual adjustments below.

Arguments: <requested arguments>

- `<project-name>` — snake_case project name
- `--package <com.example.app>` — package/bundle ID (optional, defaults to `com.example.app`)
- `--modular` — multi-package with melos (default)
- `--single` — single-module (lib/features/ structure)

## Steps

### 1. Parse arguments

Extract project name, package name, and structure type (modular or single).
If no structure specified, default to `--modular`.
If no `--package` specified, default to `com.example.app`.

### 2. Verify FVM

Before running the script, verify FVM is available:

```bash
fvm flutter --version
```

If FVM is not installed, instruct the user to install it first.

### 3A. MODULAR project scaffold

Run the script:

```bash
bash ${UFIL_ROOT}/scripts/init-modular.sh <project_name> <package_name>
```

Creates:

```
<project_name>/
├── app/                              # Main Flutter app
│   ├── lib/
│   │   ├── main_dev.dart             # Flavor entry: mainCommon(Flavor.dev)
│   │   ├── main_staging.dart         # Flavor entry: mainCommon(Flavor.staging)
│   │   ├── main_prod.dart            # Flavor entry: mainCommon(Flavor.prod)
│   │   ├── main_common.dart          # Shared init: ScreenUtilInit, MaterialApp.router
│   │   ├── app_router.dart           # RootStackRouter with AutoRoute
│   │   ├── injector.dart             # DI orchestrator: init all package configs
│   │   └── injector.config.dart      # (generated)
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── packages/
│   ├── library/
│   │   └── library_common/           # Flavor enum, AppEnv, AppConfig base
│   ├── domain/
│   │   └── domain_common/            # Failure model, DataSourceConfig interface
│   ├── data/
│   │   └── data_common/              # Dio setup, error interceptor, local storage
│   └── presentation/
│       └── feature_common/           # Theme, widgets, localization, route providers
├── .vscode/
│   ├── launch.json                   # Run configs: dev, staging, prod (debug + release)
│   └── settings.json                 # Dart SDK path, editor, file nesting, search exclude
├── pubspec.yaml                      # Pub workspace + melos: scripts + melos dev_dep
├── analysis_options.yaml             # GM lint rules (package:lint/strict.yaml)
├── .fvmrc                            # Auto-detected Flutter version
└── .gitignore
```

### 3B. SINGLE-MODULE project scaffold

Run the script:

```bash
bash ${UFIL_ROOT}/scripts/init-single.sh <project_name> <package_name>
```

Creates:

```
<project_name>/
├── lib/
│   ├── core/
│   │   ├── config/env.dart           # @singleton Envied environment vars
│   │   ├── error/                    # Failures, exceptions, ErrorMapper, ErrorType, ExceptionMapper, FailureMapper
│   │   ├── extensions/               # build_context_extensions.dart (context.l10n)
│   │   ├── network/                  # Dio module (baseUrl from Env), interceptor
│   │   ├── local/local_module.dart   # EncryptedSharedPreferences
│   │   ├── result/result.dart        # Result<T> sealed class
│   │   ├── router/                   # (empty, add routes later)
│   │   ├── theme/app_theme.dart      # AppTheme.lightTheme / darkTheme (Material 3 + ScreenUtil)
│   │   ├── utils/                    # bloc_transformer_mixin.dart (rxdart debounce/switchMap)
│   │   └── widgets/                  # Shared widgets
│   ├── features/
│   │   └── auth/                     # Default scaffolded feature (dummy datasource)
│   │       ├── data/{datasources,repositories}
│   │       ├── domain/{repositories,usecases}
│   │       └── presentation/{blocs/login,pages}
│   ├── common/                       # Shared domain/data/presentation
│   ├── gen/
│   │   ├── colors.gen.dart           # AppColors (FlutterGen-style stub)
│   │   └── l10n/                     # AppLocalizations (generated from lib/l10n/*.arb)
│   ├── l10n/                         # app_en.arb, app_id.arb
│   ├── app_router.dart               # @AutoRouterConfig (LoginRoute as initial)
│   ├── injector.dart                 # @InjectableInit, single getIt
│   └── main.dart                     # MaterialApp.router with theme + l10n delegates
├── assets/
│   ├── colors/colors.xml             # flutter_gen input → AppColors (lib/gen/colors.gen.dart)
│   ├── icons/                        # google_logo.svg, ic_whatsapp.svg samples
│   └── images/                       # (empty, .gitkeep)
├── releases/
│   └── app_icon_512.png              # Bundled icon for flutter_launcher_icons
├── test/
│   └── helpers/
│       └── test_helpers.dart         # tOk(), tError() helpers
├── .vscode/
│   ├── launch.json                   # Run configs: debug, release, profile
│   └── settings.json                 # Dart SDK path, editor, file nesting, search exclude
├── pubspec.yaml                      # SDK constraint + flutter_gen + melos + flutter_launcher_icons
├── l10n.yaml                         # arb-dir: lib/l10n, output-dir: lib/gen/l10n
├── analysis_options.yaml             # GM lint rules (package:lint/strict.yaml — NOT flutter_lints)
├── .env                              # API_BASE_URL etc. (gitignored)
├── .env.example                      # Committed env template
├── .fvmrc                            # Auto-detected Flutter version
└── .gitignore
```

**pubspec.yaml additions** (appended after stripping the default `flutter:` block):

- `flutter_gen` — output `lib/gen/`, integrations `flutter_svg: true`, AppAssets/AppFonts/AppColors
- `melos` — scripts: `build`, `build:watch`, `analyze`, `test`, `test:coverage`, `format`
- `flutter_launcher_icons` — Android+iOS, adaptive background `#2260D3`, image `releases/app_icon_512.png`
- `flutter:` — `uses-material-design: true`, `generate: true`, `assets: [assets/images/, assets/icons/]`
- `flutter_lints` is stripped from dev_dependencies; `lint` is used instead

**Default login (auth feature dummy datasource):** `demo@example.com` / `password`

### 4. Post-scaffold

1. Run `fvm flutter create` (for modular: `fvm flutter create app --org <package>`)
2. Add all dependencies to pubspec.yaml
3. Run `fvm flutter pub get` / `fvm dart pub get`
4. Run code generation
5. Run `fvm dart fix --apply`
6. Run analyzer
7. Run formatter

## Key Differences

| Aspect         | Modular                              | Single                       |
| -------------- | ------------------------------------ | ---------------------------- |
| Error handling | Failure return + FailureHandlerMixin | Result<T> + ErrorMapper      |
| DI             | Per-package di.dart + Config class   | Single injector.dart         |
| Routing        | RouteProvider abstraction            | Single AppRouter             |
| Flavors        | dev/staging/prod entry points        | Single main.dart (or envied) |
| Network        | Dio (env-specific modules)           | Dio or Supabase              |
| Build          | Per-package build.yaml               | Single build_runner          |
| Melos          | melos: scripts in root pubspec.yaml  | Optional melos for scripts   |

## Important

- FVM is **required** — all flutter/dart commands use `fvm` prefix
- SDK version auto-detected — never hardcode
- Use Dio for datasources, NOT retrofit — baseUrl is set on Dio via NetworkModule
- Datasources inject `Dio` only — no `DataSourceConfig` injection in datasources
- ScreenUtil for all sizing
- Bloc not Cubit
- Injectable for DI, never manual registration
- Freezed for all models/states/events
- Melos ^7.0.0 with config under `melos:` key in pubspec.yaml

## References

- `${UFIL_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
- `${UFIL_ROOT}/docs/VSCODE_SETUP.md` — VS Code auto-generated configuration
- `${UFIL_ROOT}/docs/NAMING_CONVENTIONS.md` — File and class naming standards
