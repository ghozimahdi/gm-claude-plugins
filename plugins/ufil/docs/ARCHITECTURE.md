# Architecture Overview

This document describes the overall architecture of the project. It supports both **modular** (multi-package + melos) and **single-module** project structures.

---

## Modular Project

The modular project follows Clean Architecture principles with a multi-package structure using Melos as a monorepo tool.

```
┌─────────────────────────────────────────────────────────────┐
│                          APP                                 │
│  (main_*.dart, injector.dart, app_router.dart)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  packages/presentation/feature_*                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ feature_    │  │ feature_    │  │ feature_    │         │
│  │ common      │  │ auth        │  │ dashboard   │         │
│  │ (widgets,   │  │ (login,     │  │ (home,      │         │
│  │  themes,    │  │  register)  │  │  profile)   │         │
│  │  i18n)      │  │             │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  packages/domain/domain_*                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  - Models (business models)                          │   │
│  │  - Use Cases (business logic)                        │   │
│  │  - Repository Interfaces (contracts)                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  packages/data/data_*                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  - DTOs (data transfer objects from API)             │   │
│  │  - Mappers (DTO <-> Model conversion)                │   │
│  │  - Repository Implementations                        │   │
│  │  - Data Sources (API, Local)                         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     LIBRARY LAYER                            │
│  packages/library/library_common                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  - App Config                                        │   │
│  │  - Flavor Configuration                              │   │
│  │  - Environment Variables                             │   │
│  │  - Core Utilities                                    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Package Structure

### Library Layer (`packages/library/`)

**library_common** - Core utilities shared across all packages

```
lib/src/
├── app_config.dart    # Application configuration
├── flavor.dart        # Build flavor enum
└── app_env.dart       # Environment variables
```

### Domain Layer (`packages/domain/`)

**domain_common** - Shared domain logic

```
lib/
├── di/               # Dependency injection modules
├── models/            # Domain models (business entities)
├── use_cases/         # Base use case classes
└── repositories/       # Repository interfaces
```

**domain\_{feature}** - Feature-specific domain

```
lib/
├── di/
├── models/            # Feature models (e.g., UserModel, AuthModel)
├── use_cases/         # Feature use cases (e.g., LoginUseCase)
└── repositories/       # Repository interfaces
```

### Data Layer (`packages/data/`)

**data_common** - Shared data infrastructure

```
lib/
├── di/               # Network module, storage module
├── config/           # API configuration, DataSourceConfig
├── models/            # Base DTOs
├── mappers/           # Base mappers
└── repositories/       # Base repository implementation
```

**data\_{feature}** - Feature-specific data

```
lib/
├── di/
├── models/            # DTOs (e.g., UserDto with fromJson/toJson)
├── mappers/           # Mappers (Dto -> Model conversion)
├── repositories/       # Repository implementations
└── data_sources/      # Datasource classes (Dio calls)
```

### Presentation Layer (`packages/presentation/`)

**feature_common** - Shared UI components

```
lib/
├── generated/        # flutter_gen assets
├── i18n/             # Localization (slang)
├── di/
├── config/           # Theme, routes
├── widgets/           # Reusable widgets
├── routes/            # Route providers (abstract)
└── utils/             # UI utilities
```

**feature\_{feature}** - Feature-specific UI

```
lib/
├── di/
├── blocs/             # BLoC files (bloc, event, state)
├── pages/             # Pages
├── widgets/           # Feature-specific widgets
└── config/           # Feature config and routes
```

## Build Flavors

| Flavor     | Entry Point         | Description    |
| ---------- | ------------------- | -------------- |
| dev        | `main_dev.dart`     | Development    |
| staging    | `main_staging.dart` | Pre-production |
| production | `main_prod.dart`    | Production     |

## Dependencies Flow

```
Presentation → Domain ← Data
     │            │        │
     ▼            ▼        ▼
  feature_*   domain_*  data_*
     │            │        │
     └────────────┴────────┘
              │
              ▼
         library_common
```

**Rules:**

- Presentation layer can only depend on Domain layer
- Data layer can only depend on Domain layer
- Domain layer has no dependencies on other layers
- All layers can depend on Library layer

## Key Principles

1. **Separation of Concerns** - Each layer has a specific responsibility
2. **Dependency Inversion** - High-level modules don't depend on low-level modules
3. **Single Responsibility** - Each class/module has one reason to change
4. **Interface Segregation** - Repository interfaces in Domain, implementations in Data
5. **Modular Design** - Features are isolated in their own packages

---

## Single-Module Project

The single-module project follows the same Clean Architecture principles but within a single `lib/` directory structure.

### Clean Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          APP                                 │
│  (main.dart, injector.dart, app_router.dart)                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  lib/features/<feature>/presentation/                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ blocs/      │  │ pages/      │  │ widgets/    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  lib/features/<feature>/domain/                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  - Models (business objects)                         │   │
│  │  - Use Cases (business logic)                        │   │
│  │  - Repository Interfaces (contracts)                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  lib/features/<feature>/data/                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  - DTOs (data transfer objects from API)             │   │
│  │  - Repository Implementations                        │   │
│  │  - Data Sources (API, Local)                         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       CORE LAYER                             │
│  lib/core/                                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  - Error Handling (Failure, Result<T>, ErrorMapper)  │   │
│  │  - Network (Dio, interceptors)                       │   │
│  │  - Local Storage (EncryptedSharedPreferences)        │   │
│  │  - Config (Environment via envied)                   │   │
│  │  - Theme, Utils, Widgets                             │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Project Structure

```
project/
├── lib/
│   ├── core/
│   │   ├── config/                   # Env config (envied)
│   │   ├── error/                    # Failure, exceptions, ErrorMapper
│   │   ├── network/                  # Dio, interceptors
│   │   ├── local/                    # EncryptedSharedPreferences
│   │   ├── result/                   # Result<T> sealed class
│   │   ├── router/
│   │   ├── theme/
│   │   ├── utils/
│   │   ├── widgets/
│   │   └── extensions/
│   ├── features/
│   │   └── <feature>/
│   │       ├── domain/
│   │       │   ├── models/           # @freezed models
│   │       │   ├── repositories/     # Abstract contracts
│   │       │   └── usecases/
│   │       ├── data/
│   │       │   ├── models/           # @freezed DTOs
│   │       │   ├── datasources/
│   │       │   └── repositories/     # Implementations
│   │       └── presentation/
│   │           ├── blocs/
│   │           ├── pages/
│   │           └── widgets/
│   ├── common/                       # Shared across features
│   ├── injector.dart                 # Single DI entry point
│   ├── app_router.dart               # Single router
│   └── main.dart
├── test/
│   └── helpers/
│       └── test_helpers.dart         # tOk(), tError()
├── pubspec.yaml
├── analysis_options.yaml
├── .env
└── .fvmrc
```

### Error Handling — Result<T>

Single-module projects use a `Result<T>` sealed class:

```dart
// core/result/result.dart
sealed class Result<T> {
  const Result();
  const factory Result.ok(T value) = Ok<T>._;
  const factory Result.error(Failure error) = Error<T>._;
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error._(this.error);
  final Failure error;
}
```

```dart
// core/error/failures.dart
@freezed
sealed class Failure with _$Failure {
  const Failure._();
  const factory Failure.server({
    @Default('Server error occurred') String message,
    int? statusCode,
  }) = ServerFailure;
  const factory Failure.network([@Default('No internet connection') String message]) = NetworkFailure;
  const factory Failure.cache([@Default('Cache error') String message]) = CacheFailure;
  const factory Failure.validation({
    @Default('Validation error') String message,
    @Default({}) Map<String, String> errors,
  }) = ValidationFailure;
  const factory Failure.auth([@Default('Authentication error') String message]) = AuthFailure;
  const factory Failure.unexpected([@Default('An unexpected error occurred') String message]) = UnexpectedFailure;
}
```

```dart
// core/error/error_mapper.dart
mixin ErrorMapper {
  Failure mapToFailure(Object error) {
    if (error is AppException) { return _mapAppException(error); }
    if (error is DioException) { return _mapDioException(error); }
    return Failure.unexpected('Unexpected error: $error');
  }
}
```

### Repository Pattern

```dart
// Domain — contract (returns Future<Result<T>>)
abstract class TenantRepository {
  Future<Result<List<TenantModel>>> getTenantList();
  Future<Result<TenantModel>> getTenantDetail(String id);
}

// Data — implementation (with ErrorMapper)
@LazySingleton(as: TenantRepository)
class TenantRepositoryImpl with ErrorMapper implements TenantRepository {
  const TenantRepositoryImpl(this._datasource);
  final TenantRemoteDatasource _datasource;

  @override
  Future<Result<List<TenantModel>>> getTenantList() async {
    try {
      final response = await _datasource.getTenantList();
      return Result.ok(response.map((dto) => dto.toModel()).toList());
    } catch (e) {
      return Result.error(mapToFailure(e));
    }
  }
}
```

### Datasource Pattern

Single-module datasources inject `Dio` only:

```dart
@lazySingleton
class TenantRemoteDatasource {
  const TenantRemoteDatasource(this._dio);
  final Dio _dio;

  Future<List<TenantDto>> getTenantList() async {
    final response = await _dio.get('/tenants');
    final list = response.data as List<dynamic>;
    return list.map((e) => TenantDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
```

### Dependency Injection

Single entry point:

```dart
// lib/injector.dart
@InjectableInit()
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());
  getIt.init();
}
```

### Environment Config

Uses `envied` with `.env` file:

```dart
@Envied(path: '.env', obfuscate: true, useConstantCase: true)
abstract class Env {
  @EnviedField(defaultValue: '')
  static final String apiBaseUrl = _Env.apiBaseUrl;
}
```

### Local Storage

Always use `encrypt_shared_preferences`, never plain `SharedPreferences`:

```dart
@module
abstract class LocalModule {
  @lazySingleton
  EncryptedSharedPreferences get encryptedPrefs {
    return EncryptedSharedPreferences.getInstance();
  }
}
```

### Test Helpers

```dart
// test/helpers/test_helpers.dart
Result<T> tOk<T>(T value) { return Result.ok(value); }
Result<T> tError<T>([String message = 'Something went wrong']) {
  return Result.error(Failure.unexpected(message));
}
```

### Code Generation

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

---

## Quick Comparison

| Aspect                   | Modular                                                | Single-Module                      |
| ------------------------ | ------------------------------------------------------ | ---------------------------------- |
| **Structure**            | `app/` + `packages/{library,domain,data,presentation}` | `lib/{core,features,common}`       |
| **Error handling**       | `Failure` model + `FailureHandlerMixin`                | `Result<T>` + `ErrorMapper`        |
| **Repo return (query)**  | `Future<Result>` (Result = Failure + data)             | `Future<Result<T>>`                |
| **Repo return (action)** | `Future<Failure>` (noFailure on success)               | `Future<Result<void>>`             |
| **Success (query)**      | `Result(items: [...])` (failure defaults to noFailure) | `Result.ok(value)`                 |
| **Success (action)**     | `Failure.noFailure()`                                  | `Result.ok(null)`                  |
| **Error indicator**      | `Result(failure: Failure.xxx())` or `mapToFailure(e)`  | `Result.error(failure)`            |
| **DTO mapping**          | Separate `@lazySingleton` mapper class                 | `.toModel()` on DTO itself         |
| **DI**                   | Per-package `di.dart` + `Config` class                 | Single `injector.dart`             |
| **Routing**              | Per-feature router + `RouteProvider`                   | Single `AppRouter`                 |
| **Flavors**              | `main_dev.dart`, `main_staging.dart`, `main_prod.dart` | Single `main.dart` + envied `.env` |
| **Local storage**        | `SharedPreferences` (via `data_common`)                | `encrypt_shared_preferences`       |
| **Melos**                | Workspace manager + scripts                            | Script runner only                 |
| **Datasource**           | `Dio` (baseUrl set via `NetworkModule`)                | `Dio` only                         |
