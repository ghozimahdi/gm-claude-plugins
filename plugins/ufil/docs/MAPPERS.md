# Mapper Guidelines

This document describes the rules and conventions for creating mappers.

**These rules apply to BOTH modular AND single-module projects.** The only difference between project types is what the repository wraps the mapped result in (`Future<Result>` for modular, `Future<Result<T>>` for single-module). The mapper _files_, _naming_, and _signatures_ are identical.

## General Rules

- Mappers live in the **data layer** (modular: `data_<feature>/lib/src/mappers/`, single-module: `lib/features/<feature>/data/mappers/`)
- Each mapper class maps **one model** (single responsibility)
- Use **classes** for mapping, **not extensions** — never `extension XOnDto { Model toModel() => ... }`
- **Never put `.toModel()` directly on a DTO.** This applies to both modular and single-module projects.
- Mapper class is annotated `@lazySingleton`
- Handle null safety properly with `??` defaults
- Keep mapping logic simple — no business rules, no API calls, no async
- **NO private helper methods inside a mapper for value sanitization** (e.g., `_nullIfEmpty`, `_nullIfZero`, `_formatDate`, `_trimOrNull`). Use the canonical `nullable_extensions.dart` — `.orEmpty()` / `.orZero()` / `.orFalse()` to default a nullable, `.orNull()` to collapse empty/zero to null, `.toIsoDate()` for `DateTime?`. Modular: `packages/data/data_common/lib/src/extensions/nullable_extensions.dart`. Single-module: `lib/core/extensions/nullable_extensions.dart`. See [Reusable Sanitization Extensions](#reusable-sanitization-extensions).

## Naming Conventions

### Class naming

| Type               | Convention              | Example                       |
| ------------------ | ----------------------- | ----------------------------- |
| Data to Domain     | `{Name}ModelMapper`     | `CustomerModelMapper`         |
| Response to Result | `{Action}ResultMapper`  | `GetCustomerListResultMapper` |
| Domain to Request  | `{Action}RequestMapper` | `CreateCustomerRequestMapper` |
| Domain to Data     | `{Action}DataMapper`    | `CreateTenantDataMapper`      |

### Method naming — `mapFromData` vs `mapFromDomain`

Mapper methods are named by **which side the parameter comes from**, NOT by what the return type is. Two names only:

| Parameter side             | Return side                | Method name      |
| -------------------------- | -------------------------- | ---------------- |
| Data module (DTO, Response, Entity) | Domain module (Model, Result) | `mapFromData`    |
| Domain module (Params, Input, Model) | Data module (Request, Data, DTO) | `mapFromDomain`  |

Never use direction-named methods like `mapToRequest` / `mapToDto` / `mapToModel` / `mapToInput` — they couple the name to the return type and split the API across mappers. Use `mapFromData` / `mapFromDomain` everywhere.

```dart
// DTO (data) → Model (domain)
@lazySingleton
class CustomerModelMapper {
  CustomerModel mapFromData(CustomerDto? data) { /* ... */ }
}

// Response (data) → Result (domain)
@lazySingleton
class GetCustomerListResultMapper {
  GetCustomerListResult mapFromData(GetCustomerListResponse? response) { /* ... */ }
}

// Params (domain) → Request (data)
@lazySingleton
class CreateCustomerRequestMapper {
  CreateCustomerRequest mapFromDomain(CreateCustomerParams params) { /* ... */ }
}

// Model (domain) → Data class for outgoing payload (data)
@lazySingleton
class UpdateProfileDataMapper {
  UpdateProfileData mapFromDomain(ProfileModel model) { /* ... */ }
}
```

## DTO to Model Mapper

Maps a single DTO to a domain model.

```dart
import 'package:domain_agent/domain_agent.dart';
import 'package:injectable/injectable.dart';

import 'package:data_agent/src/models/customer_dto.dart';

@lazySingleton
class CustomerModelMapper {
  CustomerModel mapFromData(CustomerDto? data) {
    return CustomerModel(
      id: data?.id ?? 0,
      name: data?.name ?? '',
      email: data?.email ?? '',
    );
  }
}
```

## Result Mapper

Maps a response to a result, using entity mappers for nested objects.

```dart
import 'package:domain_agent/domain_agent.dart';
import 'package:injectable/injectable.dart';

import 'package:data_agent/src/mappers/customer_model_mapper.dart';
import 'package:data_agent/src/models/get_customer_list_response.dart';

@lazySingleton
class GetCustomerListResultMapper {
  final CustomerModelMapper _customerModelMapper;

  GetCustomerListResultMapper(this._customerModelMapper);

  GetCustomerListResult mapFromData(GetCustomerListResponse? response) {
    return GetCustomerListResult(
      customers: (response?.data ?? [])
          .map(_customerModelMapper.mapFromData)
          .toList(),
    );
  }
}
```

## Request Mapper

Maps domain params to a data request. Use the canonical `nullable_extensions.dart` for null-collapsing, never private helper methods (see [Reusable Sanitization Extensions](#reusable-sanitization-extensions)).

```dart
import 'package:data_common/data_common.dart'; // exports nullable_extensions.dart
import 'package:domain_agent/domain_agent.dart';
import 'package:injectable/injectable.dart';

import 'package:data_agent/src/models/create_customer_request.dart';

@lazySingleton
class CreateCustomerRequestMapper {
  CreateCustomerRequest mapFromDomain(CreateCustomerParams params) {
    return CreateCustomerRequest(
      name: params.name,
      email: params.email,
      phone: params.phone.orNull(),
      discount: params.discount.orNull(),
      birthDate: params.birthDate.toIsoDate(),
    );
  }
}
```

Forbidden — private helpers duplicated in every mapper:

```dart
// ❌ DO NOT do this — extract to a shared extension instead
@lazySingleton
class CreateCustomerRequestMapper {
  CreateCustomerRequest mapFromDomain(CreateCustomerParams params) {
    return CreateCustomerRequest(
      phone: _nullIfEmpty(params.phone),
      discount: _nullIfZero(params.discount),
      birthDate: _formatDate(params.birthDate),
    );
  }

  String? _nullIfEmpty(String value) {
    if (value.trim().isEmpty) return null;
    return value.trim();
  }

  double? _nullIfZero(double value) {
    if (value <= 0) return null;
    return value;
  }

  String? _formatDate(DateTime? date) { /* ... */ }
}
```

## Complex Nested Mapper

For responses with multiple nested objects:

```dart
import 'package:domain_order/domain_order.dart';
import 'package:injectable/injectable.dart';

import 'package:data_order/src/mappers/order_item_model_mapper.dart';
import 'package:data_order/src/mappers/shipping_model_mapper.dart';
import 'package:data_order/src/models/get_order_detail_response.dart';

@lazySingleton
class GetOrderDetailResultMapper {
  final OrderItemModelMapper _orderItemMapper;
  final ShippingModelMapper _shippingMapper;

  GetOrderDetailResultMapper(
    this._orderItemMapper,
    this._shippingMapper,
  );

  GetOrderDetailResult mapFromData(GetOrderDetailResponse? response) {
    final data = response?.data;
    return GetOrderDetailResult(
      id: data?.id ?? '',
      orderId: data?.orderId ?? '',
      status: data?.orderStatus ?? '',
      items: (data?.items ?? [])
          .map(_orderItemMapper.mapFromData)
          .toList(),
      shipping: _shippingMapper.mapFromData(data?.shipping),
    );
  }
}
```

## Reusable Sanitization Extensions

Two canonical extension files ship with every project — generated by `init-modular.sh` (modular template) and `init-single.sh` (heredoc). Don't duplicate them, don't rewrite them as private mapper helpers (`_nullIfEmpty`, `_nullIfZero`, `_formatDate`, …).

| File                       | Use in                      | Modular path                                                                   | Single-module path                             | Barrel export         |
| -------------------------- | --------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------- | --------------------- |
| `nullable_extensions.dart` | Mappers / repos / use cases | `packages/data/data_common/lib/src/extensions/nullable_extensions.dart`        | `lib/core/extensions/nullable_extensions.dart` | `data_common.dart`    |
| `dash_extensions.dart`     | UI / display only           | `packages/presentation/feature_common/lib/src/extensions/dash_extensions.dart` | `lib/core/extensions/dash_extensions.dart`     | `feature_common.dart` |

`nullable_extensions.dart` sits in `data_common` (layer-agnostic value sanitation). `dash_extensions.dart` sits in `feature_common` (`"-"` is a UI fallback, never a JSON value).

### API at a glance

| Receiver type                                | Call           | Returns    | Behavior                                             |
| -------------------------------------------- | -------------- | ---------- | ---------------------------------------------------- |
| `String?`                                    | `.orEmpty()`   | `String`   | `''` when null, else the value                       |
| `List<T>?`                                   | `.orEmpty()`   | `List<T>`  | `[]` when null, else the list                        |
| `int?`                                       | `.orZero()`    | `int`      | `0` when null, else the value                        |
| `double?`                                    | `.orZero()`    | `double`   | `0.0` when null, else the value                      |
| `bool?`                                      | `.orFalse()`   | `bool`     | `false` when null, else the value                    |
| `bool?`                                      | `.orNull()`    | `bool?`    | `null` when value is `false`, else the value         |
| `String`                                     | `.orNull()`    | `String?`  | `null` when empty, else the value                    |
| `List<T>`                                    | `.orNull()`    | `List<T>?` | `null` when empty, else the list                     |
| `int`                                        | `.orNull()`    | `int?`     | `null` when value is `0`, else the value             |
| `double`                                     | `.orNull()`    | `double?`  | `null` when value is `0`, else the value             |
| `DateTime?`                                  | `.toIsoDate()` | `String?`  | `null` when null, else ISO date `yyyy-MM-dd`         |
| `String?` / `int?` / `double?` / `DateTime?` | `.orDash()`    | `String`   | `"-"` when null/empty/zero, else the value as string |

Mapper rule of thumb:

- **DTO → Model**: `.orEmpty()` / `.orZero()` / `.orFalse()` on the nullable DTO field. Matches the domain model's `@Default(...)` shape.
- **Params → Request**: `.orNull()` to collapse empty/zero so the JSON field is omitted; `.toIsoDate()` for dates.
- **UI / `Text(...)`**: `.orDash()` — always returns a non-null `String`.

### Rules

1. **`nullable_extensions.dart` for data/domain, `dash_extensions.dart` for UI.** Never call `.orDash()` in a mapper or repo (`"-"` would be sent literally to the server). Never call `.orNull()` directly in `Text(...)` (`null` won't render).
2. **Don't duplicate the file.** A copy in a feature package is a bug — import from `data_common` / `feature_common` (modular) or `lib/core/extensions/` (single-module).
3. **Method style with parentheses.** The canonical files use `.orEmpty()` / `.orNull()` / `.orDash()` (methods, not getters). Keep grep-ability consistent.
4. **Add new variants in the canonical file** when a sanitizer is missing — never inline as a private mapper helper.
5. **`.toIsoDate()` and `.orDash()` on `DateTime?` return the ISO calendar date** as a safe default. For human-facing dates use a localized `intl` formatter (e.g., `DateFormat.yMMMd()`).

### Example: Request mapper

```dart
import 'package:data_common/data_common.dart';
import 'package:domain_listing/domain_listing.dart';
import 'package:injectable/injectable.dart';

import 'package:data_listing/src/models/create_listing_request.dart';

@lazySingleton
class CreateListingRequestMapper {
  CreateListingRequest mapFromDomain(CreateListingParams params) {
    final isRequest = params.type == ListingType.request;
    return CreateListingRequest(
      type: params.type.value,
      title: params.title,
      currency: params.currency.isEmpty ? 'AUD' : params.currency,
      description: params.description.orNull(),
      priceAmount: isRequest ? params.priceAmount.orNull() : null,
      pricePerKg: isRequest ? null : params.pricePerKg.orNull(),
      deadline: isRequest ? params.deadline.toIsoDate() : null,
      flightDate: isRequest ? null : params.flightDate.toIsoDate(),
    );
  }
}
```

### Example: Model mapper

```dart
@lazySingleton
class TenantModelMapper {
  TenantModel mapFromData(TenantDto? data) {
    return TenantModel(
      id: data?.id.orEmpty(),
      name: data?.name.orEmpty(),
      score: data?.score.orZero(),
      active: data?.active.orFalse(),
    );
  }
}
```

### Example: UI widget

```dart
import 'package:feature_common/feature_common.dart';
import 'package:flutter/material.dart';

Text(listing.title.orDash())
Text('Price: ${listing.priceAmount.orDash()}')
Text('Deadline: ${listing.deadline.orDash()}')
```

## Import Rules

### Import Ordering

```dart
import 'dart:async';

import 'package:domain_agent/domain_agent.dart';
import 'package:injectable/injectable.dart';

import 'package:data_agent/src/models/customer_dto.dart';
import 'package:data_agent/src/models/get_customer_list_response.dart';
```

Order:

1. Dart core imports
2. Package imports (domain, injectable, etc.)
3. Data package imports

### Required Imports

Every mapper MUST import:

1. The corresponding data model (DTO)
2. The main domain package (e.g., `domain_agent.dart`) - **DO NOT import specific domain files**
3. Injectable package
4. Other mappers if needed as dependencies

## Mapper Reuse Rules

1. Check for existing mappers in:
   - Current data module
   - `data_common` module

2. Reuse existing mappers if they handle the same model types

3. Only create new mappers if no existing mapper matches

## Best Practices

1. Use `@lazySingleton` annotation for dependency injection
2. Inject required mappers in the constructor
3. Handle null cases with null-coalescing operator (`??`)
4. Use proper type casting when needed
5. Keep mapping logic simple and clear
6. Document complex mappings
7. Test mapping logic
8. Handle edge cases
9. Use proper error handling
10. Follow single responsibility principle

## File Formatting

Every generated file **must end with a single empty line** to avoid linter issues.

## Example: Full Mapper Flow

**DTO:**

```dart
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

**Domain Model:**

```dart
@freezed
abstract class UserTagModel with _$UserTagModel {
  const factory UserTagModel({
    @Default('') String id,
    @Default('') String name,
  }) = _UserTagModel;
}
```

**Model Mapper:**

```dart
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

**Result Mapper:**

```dart
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
