---
name: injectable-di
description: "GM Injectable DI patterns — modular (per-package di.dart + Config class) vs non-modular (single injector.dart)"
---

Resolve `UFIL_ROOT` to the plugin root containing this skill. Claude Code may
provide `CLAUDE_PLUGIN_ROOT`; Codex can resolve it from the installed skill
path.

## Injectable / GetIt DI Patterns (GM Standard)

### Non-Modular — Single Injector

```dart
// lib/injector.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injector.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());
  getIt.init();
}
```

All registrations go to single `injector.config.dart` (auto-generated).

### Modular — Per-Package DI + Config Class

**Each package has its own `di.dart`:**
```dart
// packages/domain/domain_auth/lib/src/di/di.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'di.config.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection({required String env}) {
  getIt.init(environment: env);
}
```

**Each package has a Config class (singleton + AsyncMemoizer):**
```dart
// packages/domain/domain_auth/lib/src/config/domain_auth_config.dart
import 'package:library_common/library_common.dart';

class DomainAuthConfig extends AppConfig {
  DomainAuthConfig._();
  static final DomainAuthConfig _instance = DomainAuthConfig._();
  static DomainAuthConfig getInstance() {
    return _instance;
  }

  @override
  Future<bool> config({required String env}) async {
    configureInjection(env: env);
    return true;
  }
}
```

**AppConfig base class (library_common):**
```dart
// packages/library/library_common/lib/src/app_config.dart
import 'package:async/async.dart';

abstract class AppConfig {
  final _asyncMemoizer = AsyncMemoizer<bool>();

  Future<bool> config({required String env});

  Future<bool> init({required String env}) {
    return _asyncMemoizer.runOnce(() => config(env: env));
  }
}
```

**App orchestrates all packages:**
```dart
// app/lib/injector.dart
@InjectableInit()
Future<void> configureDependencies({required String environment}) async {
  getIt.registerSingleton<AppRouter>(AppRouter());

  // Initialize in dependency order: domain → data → presentation
  await DomainCommonConfig.getInstance().config(env: environment);
  DomainAuthConfig.getInstance().config(env: environment);

  await DataCommonConfig.getInstance().config(env: environment);
  DataAuthConfig.getInstance().config(env: environment);

  await FeatureCommonConfig.getInstance().config(env: environment);
  FeatureAuthConfig.getInstance().config(env: environment);
  FeatureDashboardConfig.getInstance().config(env: environment);

  getIt.init(environment: environment);
}
```

### Annotation Rules

```dart
// Bloc/Cubit — @injectable (new instance per page)
@injectable
class PropertyDetailBloc extends Bloc<PropertyDetailEvent, PropertyDetailState> {
  PropertyDetailBloc(this._getPropertyDetail) : super(const PropertyDetailState());
  final GetPropertyDetailUsecase _getPropertyDetail;
}

// App-level Bloc — @lazySingleton (shared across app)
@lazySingleton
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> { ... }

// Repository impl — @LazySingleton(as: Contract)
@LazySingleton(as: PropertyRepository)
class PropertyRepositoryImpl with ErrorMapper implements PropertyRepository { ... }

// Datasource — @lazySingleton
@lazySingleton
class PropertyRemoteDatasource {
  const PropertyRemoteDatasource(this._dio);
  final Dio _dio;
}

// UseCase — @lazySingleton
@lazySingleton
class GetPropertyDetailUsecase {
  const GetPropertyDetailUsecase(this._repository);
  final PropertyRepository _repository;
}

// External deps — @module
@module
abstract class NetworkModule {
  @lazySingleton
  Dio get dio {
    return Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }
}

// Non-modular: encrypt_shared_preferences
@module
abstract class LocalModule {
  @lazySingleton
  EncryptedSharedPreferences get prefs {
    return EncryptedSharedPreferences.getInstance();
  }
}

// Modular: SharedPreferences via @preResolve (requires async configureInjection)
// @module
// abstract class LocalModule {
//   @preResolve
//   Future<SharedPreferences> get sharedPreferences =>
//       SharedPreferences.getInstance();
// }
```

### Environment-Based DI (Modular)

```dart
// DataSourceConfig — interface in domain_common
abstract interface class DataSourceConfig {
  abstract final String baseUrl;
}

// Per-environment implementations in data_common
@LazySingleton(as: DataSourceConfig, env: [Environment.dev, Environment.test])
class DevDataSourceConfig implements DataSourceConfig {
  @override
  String get baseUrl {
    return 'https://dev-api.example.com';
  }
}

@LazySingleton(as: DataSourceConfig, env: [Environment.prod])
class ProdDataSourceConfig implements DataSourceConfig {
  @override
  String get baseUrl {
    return 'https://api.example.com';
  }
}

// NetworkModule — injects DataSourceConfig to set baseUrl on Dio
@module
abstract class NetworkModule {
  @Singleton(env: [Environment.prod])
  Dio dioProd(DataSourceConfig config) {
    final dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(milliseconds: 20000),
      sendTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
    ));
    dio.interceptors.add(DioErrorInterceptor());
    if (kDebugMode) {
      dio.interceptors.addAll([
        LogInterceptor(requestBody: true, responseBody: true),
        ChuckerDioInterceptor(),
      ]);
    }
    return dio;
  }

  @Singleton(env: [Environment.dev, Environment.test])
  Dio dioDev(DataSourceConfig config) {
    final dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(milliseconds: 20000),
      sendTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
    ));
    dio.interceptors.addAll([
      LogInterceptor(requestBody: true, responseBody: true),
      ChuckerDioInterceptor(),
      DioErrorInterceptor(),
    ]);
    return dio;
  }
}
```

### Providing Blocs in Widget Tree

```dart
// Feature-level: new instance per page
BlocProvider(
  create: (_) => getIt<PropertyDetailBloc>()
    ..add(PropertyDetailEvent.started(propertyId: id)),
  child: const PropertyDetailPage(),
)

// App-level: singleton at root
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<ThemeBloc>()..add(const ThemeEvent.initialized())),
    BlocProvider(create: (_) => getIt<LocaleBloc>()..add(const LocaleEvent.initialized())),
    BlocProvider(create: (_) => getIt<AuthStatusBloc>()..add(const AuthStatusEvent.started())),
  ],
  child: const MyApp(),
)
```

### Key Rules
- **NEVER** manual `getIt.registerFactory()` — only `@injectable` annotations + `@module`
- Feature blocs: `@injectable` (factory — new instance each time)
- App-level blocs: `@lazySingleton` (shared singleton)
- Datasources, repositories, usecases: `@lazySingleton`
- External deps (Dio, SharedPreferences): `@module` class
- Modular: initialize in order domain → data → presentation → app
- Run `build_runner build` after adding annotations

### References

- `${UFIL_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
