---
name: melos
description: "GM Melos workspace patterns — config under melos: key in pubspec.yaml, pub workspaces, scripts for modular and single-package projects"
disable-model-invocation: true
---

## Melos Patterns (GM Standard)

### Installation

```bash
dart pub global activate melos
```

### Modular Project — Full Workspace (Melos 7.x + Pub Workspaces)

Melos config lives under the `melos:` key in root `pubspec.yaml`.
Pub workspaces use the `workspace:` key (Dart SDK 3.6.0+).

```yaml
# pubspec.yaml (root)
name: my_app_workspace
publish_to: 'none'

environment:
  sdk: ^3.7.0   # auto-detected from fvm dart --version

workspace:
  - app
  - packages/library/*
  - packages/domain/*
  - packages/data/*
  - packages/presentation/*

dev_dependencies:
  melos: ^7.0.0

melos:
  sdkPath: .fvm/flutter_sdk  # Use FVM Flutter SDK — no 'fvm' prefix needed in scripts

  scripts:
    build:
      run: dart run build_runner build --delete-conflicting-outputs
      exec:
        orderDependents: true
        concurrency: 1
      packageFilters:
        dependsOn: build_runner

    analyze:
      run: flutter analyze --no-pub
      exec:
        concurrency: 1

    test:
      run: flutter test --no-pub --coverage
      exec:
        concurrency: 1
      packageFilters:
        dirExists: test

    format:
      run: dart format lib test --set-exit-if-changed
      exec:
        concurrency: 1

    fix:
      run: dart fix --apply lib
      exec:
        concurrency: 1

    # Layer-specific generation
    generate:domain:
      run: dart run build_runner build --delete-conflicting-outputs
      exec:
        orderDependents: true
        concurrency: 1
      packageFilters:
        scope: "domain_*"
        dependsOn: build_runner

    generate:data:
      run: dart run build_runner build --delete-conflicting-outputs
      exec:
        orderDependents: true
        concurrency: 1
      packageFilters:
        scope: "data_*"
        dependsOn: build_runner

    generate:presentation:
      run: dart run build_runner build --delete-conflicting-outputs
      exec:
        orderDependents: true
        concurrency: 1
      packageFilters:
        scope: "feature_*"
        dependsOn: build_runner

    generate:all:
      run: |
        melos run generate:domain &&
        melos run generate:data &&
        melos run generate:presentation &&
        melos run build

    # Flavor run
    run_app:dev:
      run: flutter run --target lib/main_dev.dart
      exec:
        concurrency: 1
      packageFilters:
        scope: app

    run_app:staging:
      run: flutter run --target lib/main_staging.dart
      exec:
        concurrency: 1
      packageFilters:
        scope: app

    run_app:production:
      run: flutter run --target lib/main_prod.dart
      exec:
        concurrency: 1
      packageFilters:
        scope: app
```

Each package must include `resolution: workspace` in its `pubspec.yaml`.

### Non-Modular Project — Script Runner Only

```yaml
# pubspec.yaml (root) — no workspace, just scripts
name: my_app
# ... normal pubspec ...

dev_dependencies:
  melos: # latest from pub.dev

melos:
  sdkPath: .fvm/flutter_sdk

  scripts:
    build:
      run: dart run build_runner build --delete-conflicting-outputs

    analyze:
      run: flutter analyze --no-pub

    test:
      run: flutter test --no-pub

    format:
      run: dart format lib test

    fix:
      run: dart fix --apply lib
```

### Package Naming Convention (Modular)

```
packages/
├── library/
│   └── library_common        # Shared utilities (flavor, app_env, app_config)
├── domain/
│   ├── domain_common          # Common domain (Failure model, DataSourceConfig interface)
│   └── domain_<feature>       # Feature domain (entities, repos, usecases)
├── data/
│   ├── data_common            # Common data (Dio, local storage, error mapping)
│   └── data_<feature>         # Feature data (datasources, repo impls, DTOs)
└── presentation/
    ├── feature_common         # Shared UI (theme, widgets, localization, route providers)
    └── feature_<feature>      # Feature UI (pages, blocs, routes)
```

### build.yaml Per Module

```yaml
# domain module
targets:
  $default:
    builders:
      freezed:
        generate_for:
          - lib/src/models/**
      injectable_generator|injectable_builder:
        generate_for:
          - lib/src/use_cases/**
          - lib/src/di/di.dart

# data module
targets:
  $default:
    builders:
      freezed:
        generate_for:
          - lib/src/data_sources/**
          - lib/src/models/**
      json_serializable:
        generate_for:
          - lib/src/models/**
      injectable_generator|injectable_builder:
        generate_for:
          - lib/src/data_sources/**
          - lib/src/repositories/**
          - lib/src/di/di.dart

# presentation/feature module
targets:
  $default:
    builders:
      freezed:
        generate_for:
          - lib/src/blocs/**
      auto_route_generator|auto_route_generator:
        generate_for:
          - lib/src/config/**
          - lib/src/pages/**
      injectable_generator|injectable_builder:
        generate_for:
          - lib/src/blocs/**
          - lib/src/pages/**
          - lib/src/di/di.dart
```

### analysis_options.yaml

One file at the root is sufficient for the entire workspace. The Dart analyzer walks up the directory tree, so all packages inherit the root `analysis_options.yaml` automatically. No need for per-package copies.

### Key Rules
- Set `sdkPath: .fvm/flutter_sdk` in melos config — this means **no `fvm` prefix needed** in melos scripts
- For commands outside melos (hooks, manual CLI), still use `fvm` prefix
- `orderDependents: true` for build to respect package dependency order
- `concurrency: 1` for code generation to avoid conflicts
- Use `packageFilters` to scope scripts to specific packages
- Layer generation order: domain -> data -> presentation -> app
- Melos config under `melos:` key in root `pubspec.yaml` (not separate melos.yaml)
- Each package needs `resolution: workspace` in its pubspec.yaml
- Add melos as dev_dependency in root pubspec.yaml (version resolved from pub.dev)

### References

- `${CLAUDE_PLUGIN_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
