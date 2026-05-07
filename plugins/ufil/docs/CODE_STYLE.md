# Code Style Guidelines

This document describes the code style conventions for the project.

## Import Rules

### Import Ordering

Group imports in the following order with a single empty line between groups:

1. Dart core imports
2. Flutter imports
3. Package imports (external packages)
4. Internal package imports (project packages)

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:domain_auth/domain_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:feature_auth/src/blocs/login_bloc.dart';
import 'package:feature_auth/src/config/feature_auth_route.gr.dart';
```

### Import Path Rules

**ALWAYS use full package paths. NEVER use relative imports.**

```dart
// CORRECT
import 'package:domain_agent/domain_agent.dart';
import 'package:data_agent/src/models/customer_dto.dart';
import 'package:feature_auth/src/blocs/login_bloc.dart';

// INCORRECT - Never do this
import '../model/customer_dto.dart';
import './login_bloc.dart';
import 'customer_dto.dart';
```

### Domain Package Imports

Always import the main domain package file, not specific files:

```dart
// CORRECT
import 'package:domain_auth/domain_auth.dart';

// INCORRECT
import 'package:domain_auth/src/models/user_model.dart';
```

## Export Rules

### Main Package File

Every package must have a main export file:

```dart
// domain_auth.dart
export 'src/config/domain_auth_config.dart';
export 'src/models/user_model.dart';
export 'src/models/login_result.dart';
export 'src/repositories/auth_repository.dart';
export 'src/use_cases/login_use_case.dart';
```

### Export Order

1. Config exports
2. Model exports
3. Repository exports
4. Use case exports (domain) / Data source exports (data)
5. Mapper exports (data only)
6. Route exports (presentation only)

## File Structure

### One Class Per File

Each file should contain only one main class (except for closely related types like Params/Result).

```dart
// CORRECT - Separate files
// user_model.dart
@freezed
abstract class UserModel with _$UserModel { ... }

// get_user_result.dart
@freezed
abstract class GetUserResult with _$GetUserResult { ... }

// INCORRECT - Multiple unrelated classes in one file
@freezed
abstract class UserModel with _$UserModel { ... }

@freezed
abstract class ProductModel with _$ProductModel { ... }
```

### File Ending

Every file must end with a single empty line.

## Freezed Conventions

### Domain Models (No JSON)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @Default(0) int id,
    @Default('') String name,
    @Default('') String email,
  }) = _UserModel;
}
```

### DTOs (Data Layer — With JSON)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    @JsonKey(name: "id") int? id,
    @JsonKey(name: "name") String? name,
    @JsonKey(name: "email") String? email,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}
```

## Injectable Annotations

| Annotation | Use Case |
|------------|----------|
| `@injectable` | BLoC classes |
| `@lazySingleton` | Use cases, Mappers, Repositories |
| `@LazySingleton(as: Interface)` | Repository implementations |
| `@Injectable(as: Interface)` | Route provider implementations |

```dart
@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> { ... }

@lazySingleton
class GetUserUseCase { ... }

@lazySingleton
class UserModelMapper { ... }

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository { ... }

@Injectable(as: LoginRouteProvider)
class LoginRouteProviderImpl implements LoginRouteProvider { ... }
```

## Null Safety

### Data Layer (Nullable)

All fields in DTOs must be nullable:

```dart
@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    @JsonKey(name: "id") int? id,       // Nullable
    @JsonKey(name: "name") String? name, // Nullable
  }) = _UserDto;
}
```

### Domain Layer (Non-Nullable with Defaults)

All fields in domain models must be non-nullable with default values:

```dart
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @Default(0) int id,        // Non-nullable with default
    @Default('') String name,  // Non-nullable with default
  }) = _UserModel;
}
```

### Mapper Null Handling

Always handle nulls when mapping:

```dart
UserModel mapFromData(UserDto? data) {
  return UserModel(
    id: data?.id ?? 0,
    name: data?.name ?? '',
  );
}
```

## Documentation

### Public API Documentation

All public members should have documentation (enforced by linter):

```dart
/// Repository interface for authentication operations.
abstract class AuthRepository {
  /// Authenticates user with email and password.
  ///
  /// Returns [LoginResult] with user data on success,
  /// or [Failure] on error.
  Future<LoginResult> login({
    required String email,
    required String password,
  });
}
```

### No Documentation for Generated Files

Do not add documentation to generated file imports:

```dart
part 'user_model.freezed.dart'; // No doc needed
part 'user_data.g.dart';        // No doc needed
```

## Formatting

### Line Length

Maximum line length is 80 characters (enforced by `dart format`).

### Trailing Commas

Use trailing commas for better formatting:

```dart
// CORRECT
const factory UserModel({
  @Default(0) int id,
  @Default('') String name,
  @Default('') String email,
}) = _UserModel;

// Also good for function calls
return UserModel(
  id: data?.id ?? 0,
  name: data?.name ?? '',
  email: data?.email ?? '',
);
```

### Const Constructors

Use `const` when possible:

```dart
// CORRECT
return const UserModel();
emit(const LoginState());

// For non-const
return UserModel(id: userId);
```

## Linting

The project uses `package:lint/strict.yaml` with additional rules:

```yaml
# analysis_options.yaml
include: package:lint/strict.yaml

linter:
  rules:
    public_member_api_docs: error
    avoid_print: error
    prefer_const_constructors: error
    unawaited_futures: error
```

### Excluded Files

Generated files are excluded from analysis:

- `*.freezed.dart`
- `*.g.dart`
- `*.gr.dart`
- `*.config.dart`
- `*.gen.dart`

## Common Commands

```bash
# Format code
melos format

# Apply fixes
melos fix

# Run analysis
melos analyze

# Run all code generation
melos generate:all
```
