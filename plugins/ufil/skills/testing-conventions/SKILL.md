---
name: testing-conventions
description: "GM testing patterns — modular (per-package tests, Failure mocking) vs non-modular (Result helpers), bloc_test, mocktail for Flutter + Clean Architecture"
disable-model-invocation: true
---

## Testing Conventions (GM Standard)

### Directory Structure

#### Non-Modular
```
test/features/<feature>/
├── data/           # repository_impl_test.dart, dto_test.dart
├── domain/         # usecase_test.dart
└── presentation/   # bloc_test.dart
```

#### Modular — per-package `test/`
```
packages/
├── domain/domain_<feature>/
│   └── test/
│       ├── models/         # model_test.dart
│       ├── usecases/       # usecase_test.dart
│       └── helpers/
│           └── test_data.dart
├── data/data_<feature>/
│   └── test/
│       ├── datasources/    # datasource_test.dart
│       ├── models/         # dto_test.dart
│       ├── repositories/   # repository_impl_test.dart
│       └── helpers/
│           └── test_data.dart
└── presentation/feature_<feature>/
    └── test/
        ├── blocs/          # bloc_test.dart
        └── helpers/
            └── test_data.dart
```
Each package has its own `test/` directory. Shared test utilities (e.g. mock factories, common fixtures) go in a dedicated `test/helpers/` within each package.

---

### Bloc Test Pattern

#### Non-Modular — Result helpers
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTenantsUsecase extends Mock implements GetTenantsUsecase {}

void main() {
  late MockGetTenantsUsecase mockUsecase;
  late TenantsBloc bloc;

  setUp(() {
    mockUsecase = MockGetTenantsUsecase();
    bloc = TenantsBloc(mockUsecase);
  });

  tearDown(() {
    bloc.close();
  });

  blocTest<TenantsBloc, TenantsState>(
    'emits [loading, done] when init succeeds',
    build: () {
      when(() => mockUsecase(propertyId: any(named: 'propertyId')))
          .thenAnswer((_) async => tOk([tTenantModel]));
      return bloc;
    },
    act: (bloc) => bloc.add(const TenantsEvent.init(propertyId: '1')),
    expect: () => [
      const TenantsState(tenantsState: GetTenantsState.loading()),
      TenantsState(tenantsState: GetTenantsState.done(items: [tTenantModel])),
    ],
  );

  blocTest<TenantsBloc, TenantsState>(
    'emits [loading, error] when init fails',
    build: () {
      when(() => mockUsecase(propertyId: any(named: 'propertyId')))
          .thenAnswer((_) async => tError(const Failure.serverFailure()));
      return bloc;
    },
    act: (bloc) => bloc.add(const TenantsEvent.init(propertyId: '1')),
    expect: () => [
      const TenantsState(tenantsState: GetTenantsState.loading()),
      const TenantsState(tenantsState: GetTenantsState.error(failure: Failure.serverFailure())),
    ],
  );
}
```

#### Modular — Failure return pattern
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:domain_common/domain_common.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTenantsUsecase extends Mock implements GetTenantsUsecase {}

void main() {
  late MockGetTenantsUsecase mockUsecase;
  late TenantsBloc bloc;

  setUp(() {
    mockUsecase = MockGetTenantsUsecase();
    bloc = TenantsBloc(mockUsecase);
  });

  tearDown(() {
    bloc.close();
  });

  blocTest<TenantsBloc, TenantsState>(
    'emits [loading, done] when init succeeds',
    build: () {
      when(() => mockUsecase(propertyId: any(named: 'propertyId')))
          .thenAnswer((_) async => const Failure.noFailure());
      return bloc;
    },
    act: (bloc) => bloc.add(const TenantsEvent.init(propertyId: '1')),
    expect: () => [
      const TenantsState(tenantsState: GetTenantsState.loading()),
      TenantsState(tenantsState: GetTenantsState.done(items: [tTenantModel])),
    ],
  );

  blocTest<TenantsBloc, TenantsState>(
    'emits [loading, error] when init fails with server failure',
    build: () {
      when(() => mockUsecase(propertyId: any(named: 'propertyId')))
          .thenAnswer((_) async => const Failure.serverFailure());
      return bloc;
    },
    act: (bloc) => bloc.add(const TenantsEvent.init(propertyId: '1')),
    expect: () => [
      const TenantsState(tenantsState: GetTenantsState.loading()),
      const TenantsState(tenantsState: GetTenantsState.error(failure: Failure.serverFailure())),
    ],
  );

  blocTest<TenantsBloc, TenantsState>(
    'emits [loading, error] when init fails with no connection',
    build: () {
      when(() => mockUsecase(propertyId: any(named: 'propertyId')))
          .thenAnswer((_) async => const Failure.noConnection());
      return bloc;
    },
    act: (bloc) => bloc.add(const TenantsEvent.init(propertyId: '1')),
    expect: () => [
      const TenantsState(tenantsState: GetTenantsState.loading()),
      const TenantsState(tenantsState: GetTenantsState.error(failure: Failure.noConnection())),
    ],
  );
}
```
Key difference: modular mocks use `.thenAnswer((_) async => Failure.xxx())` (returning Failure) instead of `.thenAnswer(() => tError(...))` (returning Result).

---

### Key Rules
- Do NOT use `seed()` with async event handlers — use `act()` + `skip` instead
- Non-modular: use `tOk()` and `tError()` helpers for Result test data
- Modular query usecases: return `Future<Result>`. Mock with `.thenAnswer((_) async => GetTenantListResult(items: [...]))` for success, `.thenAnswer((_) async => GetTenantListResult(failure: Failure.xxx()))` for failure
- Modular action usecases: return `Future<Failure>`. Mock with `.thenAnswer((_) async => const Failure.noFailure())` for success, `.thenAnswer((_) async => const Failure.serverFailure())` for failure
- Use `switch` pattern matching on Result (non-modular), never `fold`
- Named parameters need `any(named: 'paramName')` in mocks
- Use `wait: Duration(milliseconds: 300)` for blocs with internal `add()` calls
- Add `registerFallbackValue(...)` for custom types used with `any()`
- No arrow (`=>`) for method/function/getter bodies

---

### Repository Test Pattern

#### Non-Modular — switch on Result
```dart
test('returns Ok with models on success', () async {
  when(() => mockDatasource.getTenants(propertyId: any(named: 'propertyId')))
      .thenAnswer((_) async => [tTenantDto]);

  final result = await repository.getTenants(propertyId: '1');

  switch (result) {
    case Ok(:final value):
      expect(value.length, 1);
      expect(value.first.id, tTenantModel.id);
    case Error():
      fail('Expected Ok');
  }
});

test('returns Error when datasource throws', () async {
  when(() => mockDatasource.getTenants(propertyId: any(named: 'propertyId')))
      .thenThrow(Exception('network error'));

  final result = await repository.getTenants(propertyId: '1');

  switch (result) {
    case Ok():
      fail('Expected Error');
    case Error(:final error):
      expect(error, isA<Failure>());
  }
});
```

#### Modular — returns Failure (noFailure on success, specific Failure on error)
```dart
test('returns noFailure on success', () async {
  when(() => mockDatasource.getTenants(propertyId: any(named: 'propertyId')))
      .thenAnswer((_) async => [tTenantDto]);

  final result = await repository.getTenants(propertyId: '1');

  expect(result, isA<NoFailure>());
});

test('returns ServerFailure when datasource throws ServerException', () async {
  when(() => mockDatasource.getTenants(propertyId: any(named: 'propertyId')))
      .thenThrow(ServerException());

  final result = await repository.getTenants(propertyId: '1');

  expect(result, isA<ServerFailure>());
});

test('returns NoConnectionFailure when datasource throws NoConnectionException', () async {
  when(() => mockDatasource.getTenants(propertyId: any(named: 'propertyId')))
      .thenThrow(NoConnectionException());

  final result = await repository.getTenants(propertyId: '1');

  expect(result, isA<NoConnectionFailure>());
});
```
Modular repository tests verify that `FailureHandlerMixin.mapToFailure()` correctly maps `AppException` subtypes to specific `Failure` variants.

---

### UseCase Test Pattern
```dart
test('delegates to repository', () async {
  // Non-modular:
  when(() => mockRepository.getTenants(propertyId: any(named: 'propertyId')))
      .thenAnswer((_) async => tOk([tTenantModel]));
  final result = await usecase(propertyId: '1');
  expect(result, tOk([tTenantModel]));

  // Modular:
  // when(() => mockRepository.getTenants(propertyId: any(named: 'propertyId')))
  //     .thenAnswer((_) async => const Failure.noFailure());
  // final result = await usecase(propertyId: '1');
  // expect(result, isA<NoFailure>());

  verify(() => mockRepository.getTenants(propertyId: '1')).called(1);
});
```

### DTO Test Pattern
```dart
test('fromJson parses valid data', () {
  final json = {'id': '1', 'name': 'Test', 'phone_number': '08123'};
  final dto = TenantDto.fromJson(json);
  expect(dto.id, '1');
  expect(dto.name, 'Test');
});

test('toModel maps correctly', () {
  final dto = TenantDto(id: '1', name: 'Test');
  final model = dto.toModel();
  expect(model.id, '1');
  expect(model.name, 'Test');
});

test('fromJson handles null fields', () {
  final json = <String, dynamic>{};
  final dto = TenantDto.fromJson(json);
  expect(dto.id, isNull);
});
```

### Running Tests

```bash
# Non-modular
flutter test

# Modular — all packages
melos run test

# Modular — specific package
cd packages/data/data_tenant && flutter test

# Modular — specific test file
cd packages/presentation/feature_tenant && flutter test test/blocs/tenant_list_bloc_test.dart
```

### References

- `${CLAUDE_PLUGIN_ROOT}/docs/BLOC_PATTERN.md` — Bloc events, states, sub-state unions
- `${CLAUDE_PLUGIN_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview, modular vs single-module
