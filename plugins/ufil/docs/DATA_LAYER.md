# Data Layer Guidelines

This document describes the rules and conventions for the Data layer.

## Directory Structure

Each feature must have its own data package (e.g., `data_auth`, `data_agent`).

```
data_{feature}/
├── lib/
│   ├── data_{feature}.dart       # Main export file
│   ├── src/
│   │   ├── config/
│   │   │   └── data_{feature}_config.dart
│   │   ├── data_sources/
│   │   │   └── {feature}_data_source.dart
│   │   ├── di/
│   │   │   └── di.dart
│   │   ├── mappers/
│   │   │   ├── {entity}_model_mapper.dart
│   │   │   └── {action}_result_mapper.dart
│   │   ├── models/
│   │   │   ├── {name}_dto.dart
│   │   │   ├── {action}_response.dart
│   │   │   └── {action}_request.dart
│   │   └── repositories/
│   │       └── {feature}_repository_impl.dart
```

## Models (DTOs)

### File Structure

- Each model MUST be in its own file
- NO multiple classes in a single model file
- Must include both `.freezed.dart` and `.g.dart` parts

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_dto.freezed.dart';
part 'customer_dto.g.dart';
```

### Model Structure

- Must use `@freezed` annotation
- Must extend generated class with `_$` prefix
- Must include `fromJson` factory constructor
- All fields must be nullable and use `@JsonKey` annotation

```dart
@freezed
class CustomerDto with _$CustomerDto {
  const factory CustomerDto({
    @JsonKey(name: "id") int? id,
    @JsonKey(name: "name") String? name,
    @JsonKey(name: "email") String? email,
  }) = _CustomerDto;

  factory CustomerDto.fromJson(Map<String, dynamic> json) =>
      _$CustomerDtoFromJson(json);
}
```

### Response Model Example

```dart
@freezed
class GetCustomerListResponse with _$GetCustomerListResponse {
  const factory GetCustomerListResponse({
    @JsonKey(name: "success") bool? success,
    @JsonKey(name: "data") List<CustomerDto>? data,
  }) = _GetCustomerListResponse;

  factory GetCustomerListResponse.fromJson(Map<String, dynamic> json) =>
      _$GetCustomerListResponseFromJson(json);
}
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Response models | `{Action}Response` | `GetCustomerListResponse` |
| Data models (DTOs) | `{Name}Dto` | `CustomerDto` |
| Request models | `{Action}Request` | `GetCustomerListRequest` |

### Field Rules

- All fields must be nullable (`Type?`)
- Use `@JsonKey` with `name` parameter for JSON field mapping
- For nested objects, create separate data models
- For lists, use `List<Type>?`

### Model Reuse Rules

1. Before creating new models, check for existing models in:
   - Current data module (e.g., `data_order`)
   - `data_common` module
   - Other data modules that might have similar models

2. Reuse existing models if:
   - The model has the same fields and structure
   - The model is in `data_common` and is meant to be shared

## Data Source

### Structure

- Must be a concrete class with `@lazySingleton` annotation
- Must inject `Dio` only (baseUrl is already configured on Dio via `NetworkModule`)
- Methods make raw Dio calls — NO try/catch (let exceptions propagate to repository)
- NO retrofit — use Dio directly

```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:data_agent/src/models/get_customer_list_response.dart';
import 'package:data_agent/src/models/create_customer_request.dart';
import 'package:data_agent/src/models/create_customer_response.dart';

@lazySingleton
class AgentDataSource {
  const AgentDataSource(this._dio);
  final Dio _dio;

  Future<GetCustomerListResponse> getCustomerList({
    required int page,
    required String search,
  }) async {
    final response = await _dio.get(
      '/api/customers',
      queryParameters: {'page': page, 'search': search},
    );
    return GetCustomerListResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CreateCustomerResponse> createCustomer(
    CreateCustomerRequest request,
  ) async {
    final response = await _dio.post(
      '/api/customers',
      data: request.toJson(),
    );
    return CreateCustomerResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
```

### Dio Method Mapping

| HTTP Method | Dio Call | Example |
|-------------|----------|---------|
| GET | `_dio.get(path)` | `_dio.get('/customers')` |
| POST | `_dio.post(path, data: body)` | `_dio.post('/customers', data: request.toJson())` |
| PUT | `_dio.put(path, data: body)` | `_dio.put('/customers/\$id', data: request.toJson())` |
| PATCH | `_dio.patch(path, data: body)` | `_dio.patch('/customers/\$id', data: request.toJson())` |
| DELETE | `_dio.delete(path)` | `_dio.delete('/customers/\$id')` |

### Parameter Passing

| Type | How | Example |
|------|-----|---------|
| Query params | `queryParameters:` | `_dio.get('/items', queryParameters: {'page': 1})` |
| Path params | String interpolation | `_dio.get('/items/\$id')` |
| Request body | `data:` with `.toJson()` | `_dio.post('/items', data: request.toJson())` |
| Form data | `FormData.fromMap()` | `_dio.post('/upload', data: FormData.fromMap({...}))` |
| Multipart | `FormData` + `MultipartFile` | `FormData.fromMap({'file': await MultipartFile.fromFile(path)})` |

## Repository Implementation

### Structure

- Must implement domain repository interface
- Must have fields for ALL required mappers
- Must inject ALL required mappers in constructor
- Must handle errors using try-catch blocks
- Must return domain models or failures

```dart
import 'package:domain_agent/domain_agent.dart';
import 'package:domain_common/domain_common.dart';
import 'package:injectable/injectable.dart';

import 'package:data_agent/src/data_sources/agent_data_source.dart';
import 'package:data_agent/src/mappers/get_customer_list_result_mapper.dart';

@LazySingleton(as: AgentRepository)
class AgentRepositoryImpl implements AgentRepository {
  final AgentDataSource _dataSource;
  final GetCustomerListResultMapper _getCustomerListResultMapper;

  AgentRepositoryImpl(
    this._dataSource,
    this._getCustomerListResultMapper,
  );

  @override
  Future<GetCustomerListResult> getCustomerList({
    required int page,
    required String searchText,
  }) async {
    try {
      final response = await _dataSource.getCustomerList(page, searchText);
      return _getCustomerListResultMapper.mapFromData(response);
    } catch (e) {
      return GetCustomerListResult(
        failure: Failure.unexpectedError(message: e.toString()),
      );
    }
  }
}
```

### Error Handling

- Use `Failure.unexpectedError(message: e.toString())` for errors
- Include proper error messages
- Handle null cases properly

## Import Rules

### Import Ordering

Group imports in the following order:
1. Dart core imports (e.g., `dart:async`)
2. Package imports (e.g., `package:domain_agent/domain_agent.dart`)
3. Data package imports (e.g., `package:data_agent/src/models/...`)

Each group must be separated by a single empty line.

```dart
import 'dart:async';

import 'package:domain_agent/domain_agent.dart';
import 'package:injectable/injectable.dart';

import 'package:data_agent/src/models/customer_dto.dart';
import 'package:data_agent/src/mappers/customer_model_mapper.dart';
```

### Import Path Rules

- NEVER use relative imports
- ALWAYS use full package paths

```dart
// Correct
import 'package:data_agent/src/models/customer_dto.dart';

// Incorrect
import '../model/customer_dto.dart';
import './customer_model_mapper.dart';
```

## Configuration

### DI Setup (`di.dart`)

```dart
import 'package:data_agent/src/di/di.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> configureInjection({required String env}) async =>
    getIt.init(environment: env);
```

### Config Class

```dart
import 'package:data_agent/src/di/di.dart';
import 'package:library_common/library_common.dart';

class DataAgentConfig extends AppConfig {
  DataAgentConfig._();

  factory DataAgentConfig.getInstance() => _instance;

  static final DataAgentConfig _instance = DataAgentConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
```
