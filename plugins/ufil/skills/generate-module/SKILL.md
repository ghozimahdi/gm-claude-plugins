---
name: generate-module
description: "Generate a feature module (domain/data/presentation) for modular Flutter projects following GM clean architecture."
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:generate-module`; in Codex invoke it as `$ufil:generate-module`. Resolve
`UFIL_ROOT` to the plugin root containing this skill; Claude Code may provide
`CLAUDE_PLUGIN_ROOT`, while Codex can resolve it from the installed skill path.

Generate a feature module for a Flutter project.

**Script available at `${UFIL_ROOT}/scripts/generate-module.sh`:**
- `generate-module.sh <name> [--modular|--single] [--layer domain|data|presentation|all]`

Run the script first, then follow up with manual wiring below.

Arguments: <requested arguments> (module name like "tenant" or "payment", optionally with --layer flag)

## Steps

### 1. Parse arguments
- Extract module name (e.g., "tenant")
- Extract layer flag: `--layer domain`, `--layer data`, `--layer presentation`, or `--layer all` (default: all)
- Detect if project is modular (check for `packages/` directory) or non-modular

### 2. For MODULAR projects — generate packages

**If --layer domain or all:**
Create `packages/domain/domain_<name>/` with:
- `pubspec.yaml` — depends on `domain_common`
- `lib/domain_<name>.dart` — barrel export
- `lib/src/models/<name>_model.dart` — freezed model with `@Default`, no nullable
- `lib/src/models/get_<name>_list_result.dart` — `@freezed` Result containing `Failure` + data
- `lib/src/repositories/<name>_repository.dart` — abstract class, query → `Future<Result>`, action → `Future<Failure>`
- `lib/src/use_cases/get_<name>_usecase.dart` — `@lazySingleton`, return type matches repo, plain `call()` method
- `lib/src/config/domain_<name>_config.dart` — Config class extending AppConfig
- `lib/src/di/di.dart` — `@injectableInit` setup
- `build.yaml` — freezed for models, injectable for use_cases

**If --layer data or all:**
Create `packages/data/data_<name>/` with:
- `pubspec.yaml` — depends on `data_common`, `domain_<name>`
- `lib/data_<name>.dart` — barrel export
- `lib/src/models/<name>_dto.dart` — freezed DTO with nullable + `@JsonKey`, NO `.toModel()`
- `lib/src/mappers/<name>_model_mapper.dart` — `@lazySingleton` class with `mapFromData(Dto? data)` returning domain model
- `lib/src/data_sources/<name>_remote_datasource.dart` — `@lazySingleton`, Dio calls, NO try/catch
- `lib/src/repositories/<name>_repository_impl.dart` — `@LazySingleton(as:)`, with FailureHandlerMixin, injects mapper
- `lib/src/config/data_<name>_config.dart` — Config class
- `lib/src/di/di.dart` — `@injectableInit` setup
- `build.yaml` — freezed + json_serializable for models, injectable for mappers/datasources/repos

**If --layer presentation or all:**
Create `packages/presentation/feature_<name>/` with:
- `pubspec.yaml` — depends on `feature_common`, `domain_<name>`
- `lib/feature_<name>.dart` — barrel export
- `lib/src/blocs/<name>/<name>_bloc.dart` — `@injectable`, Bloc with events/states
- `lib/src/blocs/<name>/<name>_event.dart` — freezed events
- `lib/src/blocs/<name>/<name>_state.dart` — freezed state with sub-state unions
- `lib/src/pages/<name>_page.dart` — `@RoutePage()`, BlocProvider, ScreenUtil
- `lib/src/config/feature_<name>_route.dart` — `@AutoRouterConfig()`
- `lib/src/config/feature_<name>_config.dart` — Config class
- `lib/src/di/di.dart` — `@injectableInit` setup
- `build.yaml` — freezed for blocs, auto_route + injectable for pages

### 3. For SINGLE-MODULE projects — generate feature folder

Create `lib/features/<name>/` with:
- `domain/models/<name>_model.dart` — `@freezed` Model with `@Default`
- `domain/models/get_<name>_list_params.dart` — `@freezed` Params (only when ≥4 fields; otherwise use named params)
- `domain/models/get_<name>_list_result.dart` — `@freezed` Result (does NOT carry Failure — `Result<T>` wraps it)
- `domain/repositories/<name>_repository.dart` — abstract, returns `Future<Result<T>>`
- `domain/usecases/get_<name>_list_use_case.dart` — `@lazySingleton`, plain `call()` returning `Future<Result<T>>`
- `data/models/<name>_dto.dart` — `@freezed` DTO with nullable + `@JsonKey`, NO `.toModel()`
- `data/models/get_<name>_list_response.dart` — `@freezed` full API response wrapper
- `data/models/create_<name>_request.dart` — `@freezed` request body (when applicable) + `toJson()`
- `data/mappers/<name>_model_mapper.dart` — `@lazySingleton` `{Name}ModelMapper` with `mapFromData(Dto? data)`
- `data/mappers/get_<name>_list_result_mapper.dart` — `@lazySingleton` `{Action}ResultMapper` with `mapFromData(Response? data)`
- `data/mappers/create_<name>_request_mapper.dart` — `@lazySingleton` `{Action}RequestMapper` with `mapFromDomain(Params params)`
- `data/datasources/<name>_remote_data_source.dart` — `{Name}RemoteDataSource`, Dio calls, NO try/catch — returns Response/DTO
- `data/repositories/<name>_repository_impl.dart` — `with ErrorMapper`, injects mapper(s) + datasource, `Result.ok(_resultMapper.mapFromData(response))` / `Result.error(mapToFailure(e))`
- `presentation/blocs/<name>/<name>_bloc.dart` / `_event.dart` / `_state.dart` — sub-state unions, init event mandatory, error carries `Failure failure`
- `presentation/pages/<name>_page.dart`

### 4. Wire up

**Modular:**
- Add new package paths to root `pubspec.yaml` workspace
- Add Config init call to `app/lib/injector.dart`
- Register route in `app/lib/app_router.dart`

**Non-modular:**
- Register route in `lib/app_router.dart`
- Run code generation

### 5. Generate code
- Run `dart fix --apply`
- Run code generation (build_runner)
- Run analyzer — fix all issues
- Run formatter

## Important
- Use **classes** for mapping, **not extensions** — separate `@lazySingleton` mapper class with `mapFromData(Dto? data)`, injected into repo via constructor
- **NEVER `.toModel()` on DTO** — applies to BOTH modular AND single-module
- Use Dio for datasources — baseUrl is set on Dio via NetworkModule
- Datasources inject `Dio` only — no `DataSourceConfig` injection in datasources
- Datasources: NO try/catch — let exceptions propagate, return raw Response/DTO
- Modular repo impls: `with FailureHandlerMixin`, query → injects ResultMapper + datasource returns `Future<Result>`, action → datasource only returns `Future<Failure>`
- Single-module repo impls: `with ErrorMapper`, injects mapper(s) + datasource, calls mapper inside try, `Result.ok(_resultMapper.mapFromData(response))` / `Result.error(mapToFailure(e))`
- Modular bloc: `switch` on `result.failure` (NoFailure = success), error state carries `Failure`
- Single-module bloc: `switch` on Result (Ok/Error), error state carries `Failure` (NOT `String`)
- All sizing with ScreenUtil (.w, .h, .sp, .r)
- Bloc not Cubit

## References

Plugin docs live under the resolved `UFIL_ROOT`.

- `${UFIL_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
- `${UFIL_ROOT}/docs/DOMAIN_LAYER.md` — Domain layer patterns and conventions
- `${UFIL_ROOT}/docs/DATA_LAYER.md` — Data layer patterns, DTOs, datasources
- `${UFIL_ROOT}/docs/PRESENTATION_LAYER.md` — Presentation layer, pages, widgets
- `${UFIL_ROOT}/docs/NAMING_CONVENTIONS.md` — File and class naming standards
- `${UFIL_ROOT}/docs/MAPPERS.md` — Mapper creation rules (apply to BOTH project types)
