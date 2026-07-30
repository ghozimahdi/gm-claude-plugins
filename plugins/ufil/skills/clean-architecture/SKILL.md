---
name: clean-architecture
description: "GM Clean Architecture patterns — modular (Failure + FailureHandlerMixin) vs non-modular (Result plus ErrorMapper) for Flutter"
---

Resolve `UFIL_ROOT` to the plugin root containing this skill. Claude Code may
provide `CLAUDE_PLUGIN_ROOT`; Codex can resolve it from the installed skill
path.

## Clean Architecture Patterns (GM Standard)

### Layer Rules

- **Presentation → Domain → Data** flow only. Never access data layer from presentation.
- Domain layer has NO dependencies on data or presentation.
- Presentation uses UseCases, never imports from data layer directly.
- **Pages MUST NOT call UseCases directly.** Only Blocs depend on UseCases — pages depend on Blocs. UseCases are injected into the Bloc via the constructor (`@injectable` Bloc + `@lazySingleton` UseCase). Pages dispatch events with `context.read<TBloc>().add(...)` and read state with `BlocBuilder`/`BlocConsumer`/`BlocSelector`/`BlocListener`. A page that imports a UseCase or calls `getIt<XUseCase>()` is ALWAYS wrong, even for one-shot ops like logout/refresh/delete — there is NO "too simple to need a bloc" exception.

### Model (Domain) — `@freezed` + `@Default`, NO nullable

```dart
@freezed
sealed class TenantModel with _$TenantModel {
  const factory TenantModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String phone,
  }) = _TenantModel;
}
```

### DTO (Data) — `@freezed` + nullable + `@JsonKey`, NO `.toModel()`

```dart
@freezed
abstract class TenantDto with _$TenantDto {
  const factory TenantDto({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'phone_number') String? phone,
  }) = _TenantDto;

  factory TenantDto.fromJson(Map<String, dynamic> json) {
    return _$TenantDtoFromJson(json);
  }
}
```

### Mapper (Data) — separate `@lazySingleton` class (BOTH project types)

```dart
@lazySingleton
class TenantModelMapper {
  TenantModel mapFromData(TenantDto? data) {
    return TenantModel(
      id: data?.id ?? '',
      name: data?.name ?? '',
      phone: data?.phone ?? '',
    );
  }
}
```

### Datasource — NO try/catch, raw Dio calls (baseUrl set via NetworkModule)

```dart
@lazySingleton
class TenantRemoteDatasource {
  const TenantRemoteDatasource(this._dio);
  final Dio _dio;

  Future<List<TenantDto>> getTenants({required String propertyId}) async {
    final response = await _dio.get(
      '/tenants',
      queryParameters: {'property_id': propertyId},
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => TenantDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
```

---

### Single-module — `Result<T>` + `ErrorMapper` + separate mapper classes

#### Repository Contract (Domain) — returns `Future<Result<T>>` where T is a mapped Result/Model

```dart
abstract class TenantRepository {
  Future<Result<GetTenantsResult>> getTenants({required String propertyId});
}
```

#### Repository Impl (Data) — `with ErrorMapper`, injects mapper, generic `catch (e)`

```dart
@LazySingleton(as: TenantRepository)
class TenantRepositoryImpl with ErrorMapper implements TenantRepository {
  TenantRepositoryImpl(this._datasource, this._resultMapper);
  final TenantRemoteDataSource _datasource;
  final GetTenantsResultMapper _resultMapper;

  @override
  Future<Result<GetTenantsResult>> getTenants({required String propertyId}) async {
    try {
      final response = await _datasource.getTenants(propertyId: propertyId);
      return Result.ok(_resultMapper.mapFromData(response));
    } catch (e) {
      return Result.error(mapToFailure(e));
    }
  }
}
```

The mapper runs inside the repo before `Result.ok(...)`. `Result<T>` always wraps a *mapped* domain type (Model or Result), never a DTO/Response.

#### UseCase — `@lazySingleton`, returns `Future<Result<T>>`

```dart
@lazySingleton
class GetTenantsUseCase {
  GetTenantsUseCase(this._repository);
  final TenantRepository _repository;

  Future<Result<GetTenantsResult>> call({required String propertyId}) {
    return _repository.getTenants(propertyId: propertyId);
  }
}
```

#### Result Pattern — always `switch`, error variant carries `Failure failure`

```dart
final result = await _getTenantsUseCase(propertyId: id);
switch (result) {
  case Ok(:final value):
    emit(state.copyWith(tenantsState: GetTenantsState.done(result: value)));
  case Error(:final error):
    emit(state.copyWith(tenantsState: GetTenantsState.error(failure: error)));
}
```

#### Feature Directory Structure

```
lib/features/<name>/
├── data/
│   ├── datasources/<name>_remote_datasource.dart
│   ├── models/<name>_dto.dart
│   └── repositories/<name>_repository_impl.dart
├── domain/
│   ├── models/<name>_model.dart
│   ├── repositories/<name>_repository.dart
│   └── usecases/get_<name>_usecase.dart
└── presentation/
    ├── blocs/<name>/{<name>_bloc.dart, <name>_event.dart, <name>_state.dart}
    ├── pages/<name>_page.dart
    └── widgets/<name>_widget.dart
```

---

### Modular — `Failure` + `FailureHandlerMixin`

#### Error Handling Chain

Modular projects use a 3-layer chain in `data_common`:

1. **DioErrorInterceptor** — converts `DioException` → `AppException`
2. **AppException** — custom exception hierarchy extending `DioException`
3. **FailureHandlerMixin** — `mapToFailure(Object error)` maps `AppException`/`DioException` → `Failure`

```dart
// packages/data/data_common/lib/src/network/app_exception.dart
class AppException extends DioException {
  final int? statusCode;
  AppException({required String message, this.statusCode})
      : super(requestOptions: RequestOptions(), message: message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super(message: 'Unauthorized access', statusCode: 401);
}

class NoConnectionException extends AppException {
  NoConnectionException() : super(message: 'No internet connection');
}

class TimeoutException extends AppException {
  TimeoutException() : super(message: 'Request timed out');
}

class ForbiddenException extends AppException {
  ForbiddenException() : super(message: 'Access forbidden', statusCode: 403);
}

class ServerException extends AppException {
  ServerException() : super(message: 'Internal server error', statusCode: 500);
}

class ClientException extends AppException {
  ClientException({required super.message, super.statusCode}) : super();
}
```

```dart
// packages/data/data_common/lib/src/network/dio_error_interceptor.dart
class DioErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw TimeoutException();
      case DioExceptionType.connectionError:
        throw NoConnectionException();
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        if (statusCode == 401) throw UnauthorizedException();
        if (statusCode == 403) throw ForbiddenException();
        if (statusCode >= 400 && statusCode < 500) {
          throw ClientException(message: 'Request failed', statusCode: statusCode);
        }
        if (statusCode >= 500) throw ServerException();
        throw AppException(message: 'Unknown error', statusCode: statusCode);
      default:
        throw AppException(message: err.message ?? 'Unknown error');
    }
  }
}
```

#### Result Model (Domain) — `@freezed`, contains `Failure` + data

```dart
// packages/domain/domain_tenant/lib/src/models/get_tenants_result.dart
@freezed
abstract class GetTenantsResult with _$GetTenantsResult {
  const factory GetTenantsResult({
    @Default(Failure.noFailure()) Failure failure,
    @Default([]) List<TenantModel> items,
  }) = _GetTenantsResult;
}
```

#### Repository Contract (Domain)

```dart
abstract class TenantRepository {
  Future<GetTenantsResult> getTenants({required String propertyId});  // Query → Result
  Future<Failure> deleteTenant(String id);                             // Action → Failure
}
```

- **Query**: returns `Future<Result>` — Result with data on success, Result with failure on error
- **Action**: returns `Future<Failure>` — `Failure.noFailure()` on success, specific `Failure` on error
- No `Result<T>` wrapper in modular projects

#### FailureHandlerMixin (data_common) — `mapToFailure()` returns Failure

```dart
// packages/data/data_common/lib/src/mixins/failure_handler_mixin.dart
mixin FailureHandlerMixin {
  Failure mapToFailure(Object error) {
    if (kDebugMode) { debugPrint(error.toString()); }

    if (error is AppException) {
      return _mapAppExceptionToFailure(error);
    } else if (error is DioException) {
      return _mapDioExceptionToFailure(error);
    } else {
      return Failure.unexpectedError(message: error.toString());
    }
  }

  Failure _mapAppExceptionToFailure(AppException exception) {
    switch (exception.runtimeType) {
      case const (UnauthorizedException): return const Failure.unauthorized();
      case const (ServerException):       return const Failure.serverFailure();
      case const (ClientException):       return const Failure.requestFailure();
      case const (TimeoutException):      return const Failure.timeout();
      case const (NoConnectionException): return const Failure.noConnection();
      case const (ForbiddenException):    return const Failure.forbidden();
      default:
        return Failure.unexpectedError(
          message: exception.message ?? exception.toString(),
        );
    }
  }

  Failure _mapDioExceptionToFailure(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure.timeout();
      case DioExceptionType.connectionError:
        return const Failure.noConnection();
      default:
        return Failure.unexpectedError(
          message: exception.message ?? 'Unknown Dio error',
        );
    }
  }
}
```

#### Repository Impl (Data) — injects **ResultMapper** + datasource, returns Result

```dart
@LazySingleton(as: TenantRepository)
class TenantRepositoryImpl with FailureHandlerMixin implements TenantRepository {
  const TenantRepositoryImpl(this._datasource, this._resultMapper);
  final TenantRemoteDatasource _datasource;
  final GetTenantsResultMapper _resultMapper;

  @override
  Future<GetTenantsResult> getTenants({required String propertyId}) async {
    try {
      final response = await _datasource.getTenants(propertyId: propertyId);
      return _resultMapper.mapFromData(response);
    } catch (e) {
      return GetTenantsResult(failure: mapToFailure(e));
    }
  }
}
```

Repository does NOT manually map DTOs — pass the full `response` to `resultMapper.mapFromData(response)`. The ResultMapper handles all DTO → model conversion.

#### UseCase — `@lazySingleton`, returns `Future<Result>`

```dart
@lazySingleton
class GetTenantsUsecase {
  const GetTenantsUsecase(this._repository);
  final TenantRepository _repository;

  Future<GetTenantsResult> call({required String propertyId}) {
    return _repository.getTenants(propertyId: propertyId);
  }
}
```

#### Failure Handling — `switch` on `result.failure`

```dart
final result = await _getTenantsUsecase(propertyId: id);
switch (result.failure) {
  case NoFailure():
    emit(state.copyWith(tenantsState: GetTenantsState.done(items: result.items)));
  default:
    emit(state.copyWith(tenantsState: GetTenantsState.error(failure: result.failure)));
}
```

#### Package Directory Structure

```
packages/
├── library/library_common/                     # AppConfig, shared utilities
├── domain/
│   ├── domain_common/                          # Failure model, shared contracts
│   │   └── lib/src/{models/failure.dart, mixins/}
│   └── domain_<feature>/
│       └── lib/src/{models/, repositories/, usecases/, di/, config/}
├── data/
│   ├── data_common/                            # FailureHandlerMixin, NetworkModule
│   │   └── lib/src/mixins/failure_handler_mixin.dart
│   └── data_<feature>/
│       └── lib/src/{datasources/, models/, repositories/, di/, config/}
└── presentation/
    ├── feature_common/                         # Shared widgets, RouteProviders
    └── feature_<feature>/
        └── lib/src/{blocs/<feature>_list/, pages/, widgets/, di/, config/}
```

### Key Rules

- **BOTH project types** use separate `@lazySingleton` mapper classes (`{Name}ModelMapper`, `{Action}ResultMapper`, `{Action}RequestMapper`). NEVER `.toModel()` on DTO.
- Single-module: `Result<T>` + `ErrorMapper` — repos wrap mapped Result/Model in `Result`, bloc uses `switch` on `Result<T>`.
- Modular: `FailureHandlerMixin` — query repos return `Future<Result>` (contains Failure + data), action repos return `Future<Failure>` directly. Bloc: query → `switch` on `result.failure`, action → `switch` on `failure`.
- Modular error chain: `DioException → DioErrorInterceptor → AppException → FailureHandlerMixin → Failure`.
- Single-module error chain: `DioException → DioErrorInterceptor → AppException → ErrorMapper mixin → Failure → wrapped in Result.error`.
- Datasources never catch exceptions — let errors propagate to repository layer.
- One UseCase per action, `@lazySingleton`, plain `call()` method.
- Sub-state error variant carries `@Default(Failure.noFailure()) Failure failure` in BOTH project types.

### References

Plugin docs live under the resolved `UFIL_ROOT`.

- `${UFIL_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
- `${UFIL_ROOT}/docs/DOMAIN_LAYER.md` — Domain layer patterns and conventions
- `${UFIL_ROOT}/docs/DATA_LAYER.md` — Data layer patterns, DTOs, datasources
- `${UFIL_ROOT}/docs/PRESENTATION_LAYER.md` — Presentation layer, pages, widgets
- `${UFIL_ROOT}/docs/NAMING_CONVENTIONS.md` — File and class naming standards
- `${UFIL_ROOT}/docs/MAPPERS.md` — Mapper creation rules (apply to BOTH project types)
