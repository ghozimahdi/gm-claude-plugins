---
name: freezed
description: "GM Freezed patterns — model, DTO, state, event, failure, params for Flutter Clean Architecture"
disable-model-invocation: true
---

## Freezed Patterns (GM Standard)

### Model (Domain Layer) — `@Default`, NO nullable

```dart
@freezed
sealed class PropertyModel with _$PropertyModel {
  const factory PropertyModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String address,
    @Default('') String type,
    @Default(0) int totalUnits,
    @Default(0) int occupiedUnits,
    @Default(0) double monthlyRevenue,
  }) = _PropertyModel;
}
```

Rules:
- ALL fields use `@Default()` — no nullable `?` fields
- `sealed class` with `_$` mixin
- No `fromJson`/`toJson` — models are pure domain objects
- Private constructor `const factory` only

### Model / Params with DateTime — `required DateTime` + `.empty()` factory (MANDATORY)

Any domain freezed class (`*_model.dart`, `*_params.dart`, `*_result.dart`) that has one or more `DateTime` fields MUST:

1. Mark every DateTime as `required DateTime` (never nullable, never `DateTime?`).
2. Provide a `.empty()` factory that supplies `DateTime.now()` for each DateTime field.

```dart
@freezed
abstract class ListingPhotoModel with _$ListingPhotoModel {
  const factory ListingPhotoModel({
    @Default('') String id,
    @Default('') String listingId,
    @Default('') String imageUrl,
    @Default(0) int sortOrder,
    required DateTime createdAt,
  }) = _ListingPhotoModel;

  factory ListingPhotoModel.empty() {
    return ListingPhotoModel(createdAt: DateTime.now());
  }
}
```

Params follow the same rule:

```dart
@freezed
abstract class CreateListingParams with _$CreateListingParams {
  const factory CreateListingParams({
    @Default('') String title,
    required DateTime deadline,
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

Why:
- Enables `@Default(ListingPhotoModel.empty())` in sub-state unions and parent models.
- Removes scattered `DateTime?` and per-callsite null checks in pages/blocs.
- Gives a deterministic zero-value for tests and forms.
- The Request mapper converts the DateTime back to a nullable JSON string via `.toIsoDate()` on `DateTime?` from the canonical `nullable_extensions.dart` (modular: `data_common`, single-module: `lib/core/extensions/`). UI uses `.orDash()` from `dash_extensions.dart` (modular: `feature_common`, single-module: `lib/core/extensions/`) for a `"-"` fallback. See `${CLAUDE_PLUGIN_ROOT}/docs/MAPPERS.md` → Reusable Sanitization Extensions.

Anti-patterns to flag:
- `DateTime? createdAt,` in a domain model — should be `required DateTime createdAt`.
- A `*_model.dart` / `*_params.dart` with `required DateTime` but no `.empty()` factory.
- Construction at call sites: `ListingPhotoModel(createdAt: DateTime.now(), ...)` instead of `.empty().copyWith(...)`.

### DTO (Data Layer) — nullable + `@JsonKey` + `.toModel()`

```dart
@freezed
sealed class PropertyDto with _$PropertyDto {
  const PropertyDto._();

  const factory PropertyDto({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'address') String? address,
    @JsonKey(name: 'property_type') String? type,
    @JsonKey(name: 'total_units') int? totalUnits,
    @JsonKey(name: 'occupied_units') int? occupiedUnits,
    @JsonKey(name: 'monthly_revenue') double? monthlyRevenue,
  }) = _PropertyDto;

  factory PropertyDto.fromJson(Map<String, dynamic> json) {
    return _$PropertyDtoFromJson(json);
  }

  PropertyModel toModel() {
    return PropertyModel(
      id: id ?? '',
      name: name ?? '',
      address: address ?? '',
      type: type ?? '',
      totalUnits: totalUnits ?? 0,
      occupiedUnits: occupiedUnits ?? 0,
      monthlyRevenue: monthlyRevenue ?? 0,
    );
  }
}
```

Rules:
- ALL fields nullable `?`
- `@JsonKey(name: '...')` on EVERY field — even when Dart name matches JSON key
- Private constructor `const PropertyDto._()` needed for `.toModel()` method
- `fromJson` + `toModel()` mapper
- Default `??` values in `toModel()` to match model `@Default`

### Bloc Event — `@freezed abstract class`, `part of` bloc

```dart
// property_detail_event.dart
part of 'property_detail_bloc.dart';

@freezed
abstract class PropertyDetailEvent with _$PropertyDetailEvent {
  const factory PropertyDetailEvent.init({required String propertyId}) = _InitEvent;
  const factory PropertyDetailEvent.refresh() = _RefreshEvent;
  const factory PropertyDetailEvent.delete() = _DeleteEvent;
}
```

Rules:
- `part of` the bloc file (not a standalone file)
- `@freezed abstract class` (not `sealed class`)
- Default init event: `.init()` → `_InitEvent`
- Private types (`_InitEvent`, `_RefreshEvent`) for pattern matching in Bloc

### Bloc State — Sub-state freezed unions per async action

```dart
// property_detail_state.dart
part of 'property_detail_bloc.dart';

// Main state — composes sub-states
@freezed
abstract class PropertyDetailState with _$PropertyDetailState {
  const factory PropertyDetailState({
    @Default(GetPropertyDetailState.idle()) GetPropertyDetailState propertyDetailState,
    @Default(DeletePropertyDetailState.idle()) DeletePropertyDetailState deletePropertyDetailState,
  }) = _PropertyDetailState;
}

// Sub-state per async action — naming: {Action}{BlocName}State
// All variants share the SAME named params with defaults (uniform shape)
@freezed
abstract class GetPropertyDetailState with _$GetPropertyDetailState {
  const factory GetPropertyDetailState.idle({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure,
  }) = _GetPropertyDetailIdleState;
  const factory GetPropertyDetailState.loading({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure,
  }) = GetPropertyDetailLoadingState;
  const factory GetPropertyDetailState.done({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure,
  }) = GetPropertyDetailDoneState;
  const factory GetPropertyDetailState.error({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure,
  }) = GetPropertyDetailErrorState;
}

@freezed
abstract class DeletePropertyDetailState with _$DeletePropertyDetailState {
  const factory DeletePropertyDetailState.idle({
    @Default(Failure.noFailure()) Failure failure,
  }) = _DeletePropertyDetailIdleState;
  const factory DeletePropertyDetailState.loading({
    @Default(Failure.noFailure()) Failure failure,
  }) = DeletePropertyDetailLoadingState;
  const factory DeletePropertyDetailState.done({
    @Default(Failure.noFailure()) Failure failure,
  }) = DeletePropertyDetailDoneState;
  const factory DeletePropertyDetailState.error({
    @Default(Failure.noFailure()) Failure failure,
  }) = DeletePropertyDetailErrorState;
}
```

Rules:
- `part of` the bloc file
- `@freezed abstract class` (not `sealed class`)
- **NEVER flat bool flags** (`isLoading`, `hasError`) — use sub-state unions
- One sub-state per independent async action
- Sub-state naming: `{Action}{BlocName}State` (e.g., `GetPropertyDetailState`, `DeletePropertyDetailState`)
- All variants share the SAME named params with defaults (`@Default(Failure.noFailure()) Failure failure` always; data fields like `@Default(...) {Type} {field}` for queries)
- `.idle()` variant is private (`_` prefix), `.loading()`/`.done()`/`.error()` are public
- Main state composes sub-states with `@Default({SubState}.idle())`
- Use `state.copyWith(propertyDetailState: ...)` in bloc handlers; pass named args (`done(property: value)`, `error(failure: error)`)

### Failure (Non-Modular — Result<T>)

```dart
// core/error/failures.dart
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  const factory Failure.server({
    @Default('Server error occurred') String message,
    int? statusCode,
  }) = ServerFailure;

  const factory Failure.network([
    @Default('No internet connection') String message,
  ]) = NetworkFailure;

  const factory Failure.cache([
    @Default('Cache error') String message,
  ]) = CacheFailure;

  const factory Failure.auth([
    @Default('Authentication error') String message,
  ]) = AuthFailure;

  const factory Failure.unexpected([
    @Default('An unexpected error occurred') String message,
  ]) = UnexpectedFailure;
}
```

### Failure (Modular — domain_common)

```dart
// packages/domain/domain_common/lib/src/models/failure.dart
@freezed
class Failure with _$Failure {
  const Failure._();

  const factory Failure.noFailure() = NoFailure;
  const factory Failure.unexpectedError({
    @Default('An unexpected error occurred') String message,
  }) = UnexpectedErrorFailure;

  // Network
  const factory Failure.timeout() = TimeoutFailure;
  const factory Failure.noConnection() = NoConnectionFailure;
  const factory Failure.serverFailure() = ServerFailure;
  const factory Failure.requestFailure() = RequestFailure;

  // Auth
  const factory Failure.userNotLoggedIn() = UserNotLoggedInFailure;
  const factory Failure.tokenExpired() = TokenExpiredFailure;
  const factory Failure.unauthorized() = UnauthorizedFailure;

  // App-Specific
  const factory Failure.permissionDenied() = PermissionDeniedFailure;
  const factory Failure.forceUpdateRequired() = ForceUpdateFailure;
  const factory Failure.businessLogicFailure({
    @Default('Business logic validation failed') String message,
  }) = BusinessLogicFailure;
}
```

### Params (Domain Layer) — for complex method arguments

```dart
@freezed
sealed class AddPropertyParams with _$AddPropertyParams {
  const factory AddPropertyParams({
    required String name,
    required String address,
    required String type,
    required String category,
    @Default('') String description,
    @Default('') String photoUrl,
  }) = _AddPropertyParams;
}
```

Rules:
- Use for usecase/repository methods with 3+ parameters
- `required` for mandatory fields, `@Default` for optional
- Keep in domain layer alongside models

### When to Use Freezed

| Type | Freezed? | Location |
|------|----------|----------|
| Model | Yes — `@Default`, no nullable | `domain/models/` |
| DTO | Yes — nullable, `@JsonKey`, `.toModel()` | `data/models/` |
| Bloc Event | Yes — named constructors | `presentation/blocs/` |
| Bloc State | Yes — sub-state unions | `presentation/blocs/` |
| Failure | Yes — union type | `core/error/` or `domain_common/models/` |
| Params | Yes — for complex args | `domain/models/` |
| Enums | No — plain Dart enum | `domain/models/` |

### Code Generation

After adding/modifying freezed classes:
```bash
# Non-modular
dart run build_runner build --delete-conflicting-outputs

# Modular (all packages)
melos run build

# Modular (specific layer)
melos run generate:domain
```

Generated files: `*.freezed.dart`, `*.g.dart` — add to `.gitignore` or `.claudeignore`

### References

- `${CLAUDE_PLUGIN_ROOT}/docs/DOMAIN_LAYER.md` — Domain layer model patterns, `required DateTime` + `.empty()` factory rule
- `${CLAUDE_PLUGIN_ROOT}/docs/DATA_LAYER.md` — Data layer DTO patterns
- `${CLAUDE_PLUGIN_ROOT}/docs/BLOC_PATTERN.md` — Bloc event and state patterns
- `${CLAUDE_PLUGIN_ROOT}/docs/MAPPERS.md` — Mapper rules + Reusable Sanitization Extensions (`nullable_extensions.dart` in `data_common`/`core`, `dash_extensions.dart` in `feature_common`/`core`)
