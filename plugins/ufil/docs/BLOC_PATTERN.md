# BLoC Pattern Guidelines

This document describes the rules and conventions for implementing BLoC pattern.

## File Structure

Each BLoC consists of 3 files in the `bloc/` folder:

- `{feature}_bloc.dart` - Main BLoC class
- `{feature}_event.dart` - Event definitions
- `{feature}_state.dart` - State definitions

## Bloc File (`{feature}_bloc.dart`)

```dart
import 'package:domain_auth/domain_auth.dart';
import 'package:domain_common/domain_common.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'home_bloc.freezed.dart';
part 'home_event.dart';
part 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetTransactionUseCase _getTransactionUseCase;
  final AddTransactionUseCase _addTransactionUseCase;

  HomeBloc(
    this._getTransactionUseCase,
    this._addTransactionUseCase,
  ) : super(const HomeState()) {
    on<_InitEvent>(_initEvent);
    on<_GetTransactionEvent>(_getTransactionEvent);
    on<_AddTransactionEvent>(_addTransactionEvent);
  }

  Future<void> _initEvent(
    _InitEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(event.state);
  }

  Future<void> _getTransactionEvent(
    _GetTransactionEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Set loading state — use the const default constructor; do NOT pass the
    // previous data. The state class still defines `@Default(...)` for the
    // data field, so the default kicks in.
    emit(
      state.copyWith(
        getTransactionState: const GetTransactionState.loading(),
        alertState: const AlertState.idle(),
      ),
    );

    // Call use case
    final params = GetTransactionParams();
    final result = await _getTransactionUseCase.call(params);

    // Handle result
    switch (result.failure) {
      case NoFailure():
        emit(
          state.copyWith(
            getTransactionState: GetTransactionState.done(
              transactionList: result.transactionList,
            ),
            alertState: const AlertState.done(),
          ),
        );
      default:
        emit(
          state.copyWith(
            getTransactionState: GetTransactionState.error(
              failure: result.failure,
            ),
            alertState: const AlertState.error(),
          ),
        );
    }
  }
}
```

### Bloc Rules

1. Use `@injectable` annotation
2. Use `part` to link event, state, and freezed files
3. Inject use cases via constructor
4. Register event handlers in constructor using `on<EventType>(handler)`
5. **Handler name MUST mirror the event class name in camelCase** — `_InitEvent` → `_initEvent`, `_GetTransactionEvent` → `_getTransactionEvent`, `_SubmittedEvent` → `_submittedEvent`. Never `_onInit` / `_onInitEvent` / `_handleX` — drop the `_on` / `_handle` prefixes; the `Event` suffix on the event class becomes the `Event` suffix on the handler.
6. Event handlers must be `Future<void>` with `(event, emit)` parameters
7. Use `emit(state.copyWith(...))` to update state
8. Always handle `loading`, `error`, and `done` (success) states
9. Use `switch (result.failure) { case NoFailure(): ... default: ... }` for query results — `NoFailure()` is success
10. **Emit sub-states with the minimum payload — let `@Default(...)` handle the rest:**
    - `loading` → use the `const` default constructor (`const GetTransactionState.loading()`). Do NOT pass the previous data; the field's `@Default(...)` kicks in.
    - `done` → pass ONLY the new data (`GetTransactionState.done(transactionList: result.transactionList)`).
    - `error` → pass ONLY `failure` (`GetTransactionState.error(failure: result.failure)`). Do NOT preserve the previous data.
    - The state class itself MUST keep the same shape (every variant declares all fields with `@Default(...)`). Only the *call site* in the bloc shrinks.

## Event File (`{feature}_event.dart`)

```dart
part of 'home_bloc.dart';

@freezed
abstract class HomeEvent with _$HomeEvent {
  const factory HomeEvent.init({
    @Default(HomeState()) HomeState state,
  }) = _InitEvent;

  const factory HomeEvent.getTransaction({
    required DateTime start,
    required DateTime end,
  }) = _GetTransactionEvent;

  const factory HomeEvent.addTransaction({
    required String title,
    required double amount,
  }) = _AddTransactionEvent;
}
```

### Event Rules

1. Add `part of '{feature}_bloc.dart';` at the top
2. Use `@freezed` annotation
3. Each event is a factory constructor
4. **Init event is mandatory** with state parameter
5. Use `@Default()` for parameters with default values
6. Use `required` for parameters without default values

## State File (`{feature}_state.dart`)

```dart
part of 'home_bloc.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(GetTransactionState.idle()) GetTransactionState getTransactionState,
    @Default(AddTransactionState.idle()) AddTransactionState addTransactionState,
    @Default(AlertState.idle()) AlertState alertState,
    @Default(-1) int selectedId,
    @Default('') String title,
    @Default(0.0) double amount,
  }) = _HomeState;
}

// All variants share the SAME named params with defaults (uniform shape)
@freezed
abstract class GetTransactionState with _$GetTransactionState {
  const factory GetTransactionState.idle({
    @Default([]) List<TransactionModel> transactionList,
    @Default(Failure.noFailure()) Failure failure,
  }) = _GetTransactionIdleState;

  const factory GetTransactionState.loading({
    @Default([]) List<TransactionModel> transactionList,
    @Default(Failure.noFailure()) Failure failure,
  }) = GetTransactionLoadingState;

  const factory GetTransactionState.done({
    @Default([]) List<TransactionModel> transactionList,
    @Default(Failure.noFailure()) Failure failure,
  }) = GetTransactionDoneState;

  const factory GetTransactionState.error({
    @Default([]) List<TransactionModel> transactionList,
    @Default(Failure.noFailure()) Failure failure,
  }) = GetTransactionErrorState;
}

@freezed
abstract class AddTransactionState with _$AddTransactionState {
  const factory AddTransactionState.idle({
    @Default(Failure.noFailure()) Failure failure,
  }) = _AddTransactionIdleState;
  const factory AddTransactionState.loading({
    @Default(Failure.noFailure()) Failure failure,
  }) = AddTransactionLoadingState;
  const factory AddTransactionState.done({
    @Default(Failure.noFailure()) Failure failure,
  }) = AddTransactionDoneState;
  const factory AddTransactionState.error({
    @Default(Failure.noFailure()) Failure failure,
  }) = AddTransactionErrorState;
}

@freezed
abstract class AlertState with _$AlertState {
  const factory AlertState.idle() = _AlertIdleState;
  const factory AlertState.error() = AlertErrorState;
  const factory AlertState.done() = AlertDoneState;
}
```

### State Rules

1. Add `part of '{feature}_bloc.dart';` at the top
2. Use `@freezed` annotation
3. **Use single main state class** - `HomeState`
4. All variables must be **non-nullable with default values**
5. **Each use case call needs its own sub-state class** - `GetTransactionState`, `AddTransactionState`
6. Sub-states have **uniform shape**: same named params with `@Default(...)` across `idle` / `loading` / `done` / `error` variants
7. **`.idle()` variant is private** (`_` prefix); `.loading()` / `.done()` / `.error()` are public
8. Always include `@Default(Failure.noFailure()) Failure failure` for sub-states whose action can fail
9. **Preserve data** by passing named args when emitting (e.g., `error(transactionList: state.x.transactionList, failure: result.failure)`)

### Handling Non-Defaultable Fields (DateTime)

For fields that cannot have default const values:

```dart
@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(TransactionState.idle()) TransactionState transactionState,
    @Default(-1) int selectedId,
    required DateTime transactionDate,  // Cannot use @Default
  }) = _HomeState;

  factory HomeState.empty() => HomeState(
    transactionDate: DateTime.now(),
  );
}
```

## Naming Conventions

| Type            | Convention       | Example               |
| --------------- | ---------------- | --------------------- |
| Bloc class      | `{Feature}Bloc`  | `HomeBloc`            |
| Event class     | `{Feature}Event` | `HomeEvent`           |
| State class     | `{Feature}State` | `HomeState`           |
| Sub-state class | `{Action}State`  | `GetTransactionState` |
| File names      | snake_case       | `home_bloc.dart`      |

## Best Practices

1. **Always use freezed** for event and state classes
2. **Use default values** in the state
3. **Separate sub-states** for async processes
4. **Use dependency injection** for use cases in the Bloc
5. **Async event handlers** must handle `loading`, `error`, and `done` states
6. **Use copyWith** to update the state
7. **Always use full package import paths**
8. **Emit lean sub-states** — `loading` uses `const X.loading()` (no args), `error` passes only `failure`, `done` passes only the new data. Do NOT preserve the previous data on `loading`/`error` at the call site; the state class's `@Default(...)` already provides safe fallbacks if a consumer reads them.
9. **Reset alert state** before making new API calls (`alertState: const AlertState.idle()`)
10. **Uniform sub-state shape** — every variant (`idle`/`loading`/`done`/`error`) has the same named params with defaults, so data and `failure` getters are always available regardless of the current variant
