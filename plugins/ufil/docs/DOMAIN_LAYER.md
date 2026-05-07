# Domain Layer Guidelines

This document describes the rules and conventions for the Domain layer.

## Directory Structure

Each feature must have its own domain package (e.g., `domain_auth`, `domain_agent`).

```
domain_{feature}/
├── lib/
│   ├── domain_{feature}.dart     # Main export file
│   ├── src/
│   │   ├── config/
│   │   │   └── domain_{feature}_config.dart
│   │   ├── di/
│   │   │   └── di.dart
│   │   ├── models/
│   │   │   ├── {entity}_model.dart
│   │   │   ├── {action}_params.dart
│   │   │   └── {action}_result.dart
│   │   ├── repositories/
│   │   │   └── {feature}_repository.dart
│   │   └── use_cases/
│   │       └── {action}_use_case.dart
```

## Models

### General Rules

- Use Freezed for immutable models
- Naming: `{entity}_model.dart` (e.g., `agent_model.dart`)
- Must use the `@freezed` annotation
- Do **NOT** use `fromJson` or `JsonKey` annotations (these are only for the data layer)
- Keep business logic in the model
- No external dependencies

### Field Rules

**For fields that can have default values:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';

@freezed
abstract class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    @Default(0) int id,
    @Default('') String name,
    @Default([]) List<String> tags,
    @Default(false) bool isActive,
  }) = _TransactionModel;
}
```

**For fields that cannot have default values (DateTime) — `required DateTime` + `.empty()` factory (MANDATORY):**

When ANY field on a domain data class is a `DateTime`, the field MUST be `required DateTime` (never nullable, never `DateTime?`) AND the class MUST expose a `.empty()` factory so callers can construct a zero-value instance without knowing about `DateTime.now()`.

This rule applies to BOTH `*_model.dart` AND `*_params.dart` files (and any other freezed data class in the domain layer that has DateTime fields, e.g., `*_result.dart` when it embeds DateTime directly).

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';

@freezed
abstract class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    @Default(0) int id,
    @Default('') String description,
    required DateTime createdAt, // ✅ required — never DateTime?
    required DateTime updatedAt,
    @Default(0.0) double amount,
  }) = _TransactionModel;

  /// Zero-value instance — use in `@Default(TransactionModel.empty())` slots,
  /// bloc sub-states, and tests. Never construct a TransactionModel manually
  /// with `DateTime.now()` at call sites.
  factory TransactionModel.empty() {
    return TransactionModel(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
```

Same shape for `*_params.dart`:

```dart
@freezed
abstract class CreateListingParams with _$CreateListingParams {
  const factory CreateListingParams({
    @Default('') String title,
    required DateTime deadline,  // ✅ required, not DateTime?
    required DateTime flightDate,
    @Default(0.0) double priceAmount,
  }) = _CreateListingParams;

  factory CreateListingParams.empty() {
    return CreateListingParams(
      deadline: DateTime.now(),
      flightDate: DateTime.now(),
    );
  }
}
```

Rules:

1. **No `DateTime?` in the domain layer.** Nullable DateTime fields belong to the data layer (DTOs / Responses), not domain.
2. **Always pair `required DateTime` with a `.empty()` factory.** Without `.empty()`, the model can't be used as a default in sub-state unions (`@Default(TransactionModel.empty())`) or as a starting value for forms.
3. **`.empty()` uses `DateTime.now()`** as the sentinel — keep it deterministic-enough for `==`/equatable. The bloc replaces the empty instance with real data on `done`.
4. **No factory body shortcuts** — use `{ return ...; }`, never arrow (`=>`) for the `.empty()` factory, to comply with the project's no-arrow rule.
5. When a Request mapper needs to send the DateTime as a nullable JSON string, use `.toIsoDate()` on `DateTime?` from the canonical `nullable_extensions.dart` — modular: `packages/data/data_common/lib/src/extensions/nullable_extensions.dart`, single-module: `lib/core/extensions/nullable_extensions.dart`. Do NOT add per-mapper `_formatDate` helpers. For UI display use `.orDash()` from the separate `dash_extensions.dart` (modular: `feature_common`, single-module: `lib/core/extensions/`). See `${CLAUDE_PLUGIN_ROOT}/docs/MAPPERS.md` → Reusable Sanitization Extensions.

### Model Reuse Rules

1. Before creating new models, check for existing models in:
   - Current domain module (e.g., `domain_order`)
   - `domain_common` module
   - Other domain modules that might have similar models

2. Reuse existing models if:
   - The model has the same fields and structure
   - The model is in `domain_common` and is meant to be shared
   - The model is in another module but has the exact same purpose

3. Model checking process:
   - Check field names and types
   - Check default values
   - Check nested object structures
   - If all match, reuse the existing model

## Repository Interfaces

- Naming: `{feature}_repository.dart`
- Define abstract methods for data operations
- Return domain models or failures
- Use domain models for params/result
- No implementation details

```dart
abstract class AgentRepository {
  Future<GetAgentListResult> getAgentList(GetAgentListParams input);
  Future<GetCustomerListResult> getCustomerList(String customerId);
}
```

## Use Cases

- Naming: `{action}_use_case.dart` (e.g., `get_agent_list_use_case.dart`)
- Use `@lazySingleton` for dependency injection
- Follow the single responsibility principle
- Handle business logic
- Return domain models or failures
- Use repository interfaces

```dart
import 'package:domain_agent/src/models/get_agent_list_params.dart';
import 'package:domain_agent/src/models/get_agent_list_result.dart';
import 'package:domain_agent/src/repositories/agent_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetAgentListUseCase {
  final AgentRepository repository;

  GetAgentListUseCase(this.repository);

  Future<GetAgentListResult> call(GetAgentListParams input) {
    return repository.getAgentList(input);
  }
}
```

## Params/Result Models

### Params Rules

**If the params has only 1 field:**
- Do NOT create a params class
- Use the field type directly

```dart
// Repository
Future<GetCustomerListResult> getCustomerList(String id);

// Use Case
Future<GetCustomerListResult> call(String id) {
  return repository.getCustomerList(id);
}
```

**If the params has 2-3 fields:**
- Do NOT create a params class
- Use required named parameters directly

```dart
// Repository
Future<GetAgentListResult> getAgentList({
  required int page,
  required String searchText,
});

// Use Case
Future<GetAgentListResult> call({
  required int page,
  required String searchText,
}) {
  return repository.getAgentList(
    page: page,
    searchText: searchText,
  );
}
```

**If the params has more than 3 fields:**
- MUST create a params class

```dart
@freezed
abstract class GetAgentListParams with _$GetAgentListParams {
  const factory GetAgentListParams({
    @Default(1) int page,
    @Default([]) List<String> selectedDistrictIds,
    @Default([]) List<String> selectedHdbTownIds,
    @Default([]) List<String> selectedAreaSpecializations,
    @Default('') String searchText,
  }) = _GetAgentListParams;
}
```

### Result Rules

Result models should have default values for model and failure:

```dart
import 'package:domain_agent/src/models/customer_model.dart';
import 'package:domain_common/domain_common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_agent_list_result.freezed.dart';

@freezed
abstract class GetAgentListResult with _$GetAgentListResult {
  const factory GetAgentListResult({
    @Default([]) List<CustomerModel> customers,
    @Default(Failure.noFailure()) Failure failure,
  }) = _GetAgentListResult;
}
```

## Export Rules

Every new file created in the domain layer MUST be exported in the main `domain_{feature}.dart` file:

```dart
// domain_agent.dart
export 'src/config/domain_agent_config.dart';
export 'src/models/customer_model.dart';
export 'src/models/get_customer_list_result.dart';
export 'src/repositories/agent_repository.dart';
export 'src/use_cases/get_customer_list_use_case.dart';
```

Export order should follow:
1. Config exports
2. Model exports
3. Repository exports
4. Use case exports

## Import Rules

- All imports MUST use full package paths
- Never use relative imports

```dart
// Correct
import 'package:domain_agent/src/models/customer_model.dart';
import 'package:domain_agent/src/repositories/agent_repository.dart';
import 'package:injectable/injectable.dart';

// Incorrect
import '../model/customer_model.dart';
import './customer_model.dart';
```
