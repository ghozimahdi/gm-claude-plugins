# JSON to Dart Conversion Guidelines

This document describes the rules for converting JSON API responses to Dart models.

## Generation Process

### 1. Response Class Generation

- Generate response class with name `{Action}Response` (e.g., `GetUserTagResponse`)
- Check if similar response class exists in:
  1. Current data module (e.g., `data_order`)
  2. `data_common` module
- If exists, reuse existing class

### 2. Data Class Generation

- For each nested object, generate data class with name `{Name}Dto` (e.g., `UserTagDto`)
- Check if similar data class exists before creating
- For nested objects within data classes, follow the same process

### 3. Domain Model Generation

- Generate domain model with name `{Name}Model` (e.g., `UserTagModel`)
- Check if similar model exists in domain modules
- Reuse existing models when possible

### 4. Mapper Generation

- Generate mappers for converting between data and domain models
- Check if similar mappers exist before creating

## Data Layer Models

### Response Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:data_order/src/models/user_tag_dto.dart';

part 'get_user_tag_response.freezed.dart';
part 'get_user_tag_response.g.dart';

@freezed
class GetUserTagResponse with _$GetUserTagResponse {
  const factory GetUserTagResponse({
    @JsonKey(name: "success") bool? success,
    @JsonKey(name: "data") List<UserTagDto>? data,
  }) = _GetUserTagResponse;

  factory GetUserTagResponse.fromJson(Map<String, dynamic> json) =>
      _$GetUserTagResponseFromJson(json);
}
```

### Data Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_tag_dto.freezed.dart';
part 'user_tag_dto.g.dart';

@freezed
class UserTagDto with _$UserTagDto {
  const factory UserTagDto({
    @JsonKey(name: "_id") String? id,
    @JsonKey(name: "name") String? name,
  }) = _UserTagDto;

  factory UserTagDto.fromJson(Map<String, dynamic> json) =>
      _$UserTagDtoFromJson(json);
}
```

### Data Model Rules

1. Each model MUST be in its own file
2. Must include both `.freezed.dart` and `.g.dart` parts
3. Must use `@freezed` annotation
4. Must include `fromJson` factory constructor
5. All fields must be nullable (`Type?`)
6. Use `@JsonKey(name: "json_field_name")` for all fields

## Domain Layer Models

### Domain Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_tag_model.freezed.dart';

@freezed
abstract class UserTagModel with _$UserTagModel {
  const factory UserTagModel({
    @Default('') String id,
    @Default('') String name,
  }) = _UserTagModel;
}
```

### Result Model

```dart
import 'package:domain_common/domain_common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:domain_order/src/models/user_tag_model.dart';

part 'get_user_tag_result.freezed.dart';

@freezed
abstract class GetUserTagResult with _$GetUserTagResult {
  const factory GetUserTagResult({
    @Default(false) bool success,
    @Default([]) List<UserTagModel> tags,
    @Default(Failure.noFailure()) Failure failure,
  }) = _GetUserTagResult;
}
```

### Domain Model Rules

1. Each model MUST be in its own file
2. Must include `.freezed.dart` part (NO `.g.dart`)
3. Must use `@freezed` annotation
4. **Do NOT use** `fromJson` or `@JsonKey`
5. All fields must use `@Default()` annotation
6. All fields must be non-nullable

## Default Values Reference

| Type       | Default Value                      |
| ---------- | ---------------------------------- |
| `int`      | `@Default(0)`                      |
| `double`   | `@Default(0.0)`                    |
| `String`   | `@Default('')`                     |
| `bool`     | `@Default(false)`                  |
| `List<T>`  | `@Default([])`                     |
| `DateTime` | Use `required` + `empty()` factory |
| `Enum`     | `@Default(EnumType.value)`         |
| `Object`   | `@Default(ObjectType())`           |
| `Failure`  | `@Default(Failure.noFailure())`    |

## Mappers

### DTO to Model Mapper

```dart
import 'package:domain_order/domain_order.dart';
import 'package:injectable/injectable.dart';

import 'package:data_order/src/models/user_tag_dto.dart';

@lazySingleton
class UserTagModelMapper {
  UserTagModel mapFromData(UserTagDto? data) {
    return UserTagModel(
      id: data?.id ?? '',
      name: data?.name ?? '',
    );
  }
}
```

### Result Mapper

```dart
import 'package:domain_order/domain_order.dart';
import 'package:injectable/injectable.dart';

import 'package:data_order/src/mappers/user_tag_model_mapper.dart';
import 'package:data_order/src/models/get_user_tag_response.dart';

@lazySingleton
class GetUserTagResultMapper {
  final UserTagModelMapper _userTagModelMapper;

  GetUserTagResultMapper(this._userTagModelMapper);

  GetUserTagResult mapFromData(GetUserTagResponse? response) {
    return GetUserTagResult(
      success: response?.success ?? false,
      tags: (response?.data ?? [])
          .map(_userTagModelMapper.mapFromData)
          .toList(),
    );
  }
}
```

## Complex JSON Example

### JSON Response

```json
{
  "success": true,
  "data": {
    "_id": "68235e46e252e84e62c9dcce",
    "orderId": "ORD-001",
    "trackingStatus": {
      "status": "pending",
      "message": "Order is being processed"
    }
  }
}
```

### Generated Models

**Data Models:**

- `GetOrderDetailResponse` - Root response
- `OrderDetailDto` - Main data object
- `TrackingStatusDto` - Nested object

**Domain Models:**

- `GetOrderDetailResult` - Result with failure
- `OrderDetailModel` - Business model
- `TrackingStatusModel` - Nested business model

**Mappers:**

- `TrackingStatusModelMapper` - Maps `TrackingStatusDto` → `TrackingStatusModel`
- `OrderDetailModelMapper` - Maps `OrderDetailDto` → `OrderDetailModel` (uses `TrackingStatusModelMapper`)
- `GetOrderDetailResultMapper` - Maps response → result (uses `OrderDetailModelMapper`)
