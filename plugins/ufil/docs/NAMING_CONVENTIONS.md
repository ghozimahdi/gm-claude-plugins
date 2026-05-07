# Naming Conventions

This document describes the naming conventions used in the project.

## File Naming

All files use `snake_case`:

| Type           | Pattern                               | Example                     |
| -------------- | ------------------------------------- | --------------------------- |
| Page           | `{name}_page.dart`                    | `login_page.dart`           |
| Widget         | `{name}_widget.dart` or `{name}.dart` | `summary_item.dart`         |
| BLoC           | `{name}_bloc.dart`                    | `login_bloc.dart`           |
| Event          | `{name}_event.dart`                   | `login_event.dart`          |
| State          | `{name}_state.dart`                   | `login_state.dart`          |
| Model (Domain) | `{name}_model.dart`                   | `user_model.dart`           |
| DTO (Data)     | `{name}_dto.dart`                     | `user_dto.dart`             |
| Response       | `{action}_response.dart`              | `get_user_response.dart`    |
| Request        | `{action}_request.dart`               | `create_user_request.dart`  |
| Params         | `{action}_params.dart`                | `get_user_params.dart`      |
| Result         | `{action}_result.dart`                | `get_user_result.dart`      |
| Mapper         | `{name}_mapper.dart`                  | `user_model_mapper.dart`    |
| Repository     | `{name}_repository.dart`              | `auth_repository.dart`      |
| Data Source    | `{name}_data_source.dart`             | `auth_data_source.dart`     |
| Use Case       | `{action}_use_case.dart`              | `get_user_use_case.dart`    |
| Config         | `{module}_config.dart`                | `domain_auth_config.dart`   |
| Route          | `{module}_route.dart`                 | `feature_auth_route.dart`   |
| Route Provider | `{name}_route_provider.dart`          | `login_route_provider.dart` |

## Class Naming

All classes use `PascalCase`:

| Type                 | Pattern                   | Example                  |
| -------------------- | ------------------------- | ------------------------ |
| Page                 | `{Name}Page`              | `LoginPage`              |
| Widget               | `{Name}`                  | `SummaryItem`            |
| BLoC                 | `{Name}Bloc`              | `LoginBloc`              |
| Event                | `{Name}Event`             | `LoginEvent`             |
| State                | `{Name}State`             | `LoginState`             |
| Domain Model         | `{Name}Model`             | `UserModel`              |
| DTO                  | `{Name}Dto`               | `UserDto`                |
| Response             | `{Action}Response`        | `GetUserResponse`        |
| Request              | `{Action}Request`         | `CreateUserRequest`      |
| Params               | `{Action}Params`          | `GetUserParams`          |
| Result               | `{Action}Result`          | `GetUserResult`          |
| Mapper               | `{Name}Mapper`            | `UserModelMapper`        |
| Repository Interface | `{Name}Repository`        | `AuthRepository`         |
| Repository Impl      | `{Name}RepositoryImpl`    | `AuthRepositoryImpl`     |
| Data Source          | `{Name}DataSource`        | `AuthDataSource`         |
| Use Case             | `{Action}UseCase`         | `GetUserUseCase`         |
| Config               | `{Module}Config`          | `DomainAuthConfig`       |
| Route Provider       | `{Name}RouteProvider`     | `LoginRouteProvider`     |
| Route Provider Impl  | `{Name}RouteProviderImpl` | `LoginRouteProviderImpl` |

## Variable and Method Naming

All variables and methods use `camelCase`:

```dart
// Variables
final String userName = '';
final int userId = 0;
final bool isLoggedIn = false;

// Methods
Future<UserModel> getUserById(int id);
void updateUserProfile(UserModel user);
bool validateEmail(String email);
```

## Package Naming

| Layer        | Pattern            | Example          |
| ------------ | ------------------ | ---------------- |
| Library      | `library_{name}`   | `library_common` |
| Domain       | `domain_{feature}` | `domain_auth`    |
| Data         | `data_{feature}`   | `data_auth`      |
| Presentation | `feature_{name}`   | `feature_auth`   |

## BLoC Sub-State Naming

| Type            | Pattern                | Example                      |
| --------------- | ---------------------- | ---------------------------- |
| Sub-state class | `{Action}State`        | `GetTransactionState`        |
| Loading state   | `{Action}LoadingState` | `GetTransactionLoadingState` |
| Idle state      | `{Action}IdleState`    | `GetTransactionIdleState`    |
| Done state      | `{Action}DoneState`    | `GetTransactionDoneState`    |
| Error state     | `{Action}ErrorState`   | `GetTransactionErrorState`   |

## Mapper Naming

| Direction         | Pattern                 | Example                       |
| ----------------- | ----------------------- | ----------------------------- |
| Data → Domain     | `{Name}ModelMapper`     | `CustomerModelMapper`         |
| Response → Result | `{Action}ResultMapper`  | `GetCustomerListResultMapper` |
| Params → Request  | `{Action}RequestMapper` | `CreateCustomerRequestMapper` |
| Params → Dto      | `{Action}DtoMapper`     | `CreateTenantDtoMapper`       |

## JSON Key Naming

Use `@JsonKey` with the exact API field name:

```dart
@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    @JsonKey(name: "_id") String? id,           // API uses _id
    @JsonKey(name: "user_name") String? userName, // API uses user_name
    @JsonKey(name: "email") String? email,        // API uses email
    @JsonKey(name: "createdAt") DateTime? createdAt, // API uses createdAt
  }) = _UserDto;
}
```

## Constants Naming

```dart
// File: constants.dart
const String kApiBaseUrl = 'https://api.example.com';
const int kDefaultPageSize = 20;
const Duration kAnimationDuration = Duration(milliseconds: 300);
```

## Enum Naming

```dart
// File: user_status.dart
enum UserStatusEnum {
  active,
  inactive,
  pending,
  suspended,
}

// Usage
@Default(UserStatusEnum.pending) UserStatus status,
```

## Private Members

Prefix private members with underscore:

```dart
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final GetUserUseCase _getUserUseCase;  // Private field

  Future<void> _submittedEvent(...) { }    // Bloc event handler — camelCase of event class name (`_SubmittedEvent` → `_submittedEvent`). Never `_onSubmitted` / `_onSubmittedEvent`.
}
```

## Generated Files

Generated files follow patterns:

| Type              | Pattern                |
| ----------------- | ---------------------- |
| Freezed           | `{name}.freezed.dart`  |
| JSON Serializable | `{name}.g.dart`        |
| Injectable        | `di.config.dart`       |
| Auto Route        | `{name}_route.gr.dart` |
