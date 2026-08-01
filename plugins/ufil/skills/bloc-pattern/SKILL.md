---
name: bloc-pattern
description: "GM Bloc state management patterns — part/part-of structure, sub-state unions (idle/loading/error/done), modular (Failure) vs non-modular (Result switch)"
---

Resolve `UFIL_ROOT` to the plugin root containing this skill. Claude Code may
provide `CLAUDE_PLUGIN_ROOT`; Codex can resolve it from the installed skill
path.

## Bloc Patterns (GM Standard)

### File Structure — `part` / `part of` (3 files per bloc)

The bloc file is the main library. Event and state files use `part of`:

```
blocs/
└── property_detail/
    ├── property_detail_bloc.dart    ← main file (has part directives)
    ├── property_detail_event.dart   ← part of bloc
    └── property_detail_state.dart   ← part of bloc
```

### Events — `@freezed abstract class`, `part of` bloc

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

### States — sub-state unions per async action (NOT flat bool flags)

#### Non-Modular — error carries `Failure`

```dart
// property_detail_state.dart
part of 'property_detail_bloc.dart';

@freezed
abstract class PropertyDetailState with _$PropertyDetailState {
  const factory PropertyDetailState({
    @Default(GetPropertyDetailState.idle()) GetPropertyDetailState propertyDetailState,
    @Default(DeletePropertyDetailState.idle()) DeletePropertyDetailState deletePropertyDetailState,
  }) = _PropertyDetailState;
}

@freezed
abstract class GetPropertyDetailState with _$GetPropertyDetailState {
  const factory GetPropertyDetailState.idle({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure
  }) = _GetPropertyDetailIdleState;
  const factory GetPropertyDetailState.loading({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure
  }) = GetPropertyDetailLoadingState;
  const factory GetPropertyDetailState.done({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure
  }) = GetPropertyDetailDoneState;
  const factory GetPropertyDetailState.error({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure
  }) = GetPropertyDetailErrorState;
}

@freezed
abstract class DeletePropertyDetailState with _$DeletePropertyDetailState {
  const factory DeletePropertyDetailState.idle({
    @Default(Failure.noFailure()) Failure failure
  }) = _DeletePropertyDetailIdleState;
  const factory DeletePropertyDetailState.loading({
    @Default(Failure.noFailure()) Failure failure
  }) = DeletePropertyDetailLoadingState;
  const factory DeletePropertyDetailState.done({
    @Default(Failure.noFailure()) Failure failure
  }) = DeletePropertyDetailDoneState;
  const factory DeletePropertyDetailState.error({
    @Default(Failure.noFailure()) Failure failure
  }) = DeletePropertyDetailErrorState;
}
```

#### Modular — error carries `Failure` object

```dart
// property_detail_state.dart
part of 'property_detail_bloc.dart';

@freezed
abstract class PropertyDetailState with _$PropertyDetailState {
  const factory PropertyDetailState({
    @Default(GetPropertyDetailState.idle()) GetPropertyDetailState propertyDetailState,
    @Default(DeletePropertyDetailState.idle()) DeletePropertyDetailState deletePropertyDetailState,
  }) = _PropertyDetailState;
}

@freezed
abstract class GetPropertyDetailState with _$GetPropertyDetailState {
  const factory GetPropertyDetailState.idle({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure
  }) = _GetPropertyDetailIdleState;
  const factory GetPropertyDetailState.loading({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure
  }) = GetPropertyDetailLoadingState;
  const factory GetPropertyDetailState.done({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure
  }) = GetPropertyDetailDoneState;
  const factory GetPropertyDetailState.error({
    @Default(PropertyModel()) PropertyModel property,
    @Default(Failure.noFailure()) Failure failure
  }) = GetPropertyDetailErrorState;
}

@freezed
abstract class DeletePropertyDetailState with _$DeletePropertyDetailState {
  const factory DeletePropertyDetailState.idle({
    @Default(Failure.noFailure()) Failure failure
  }) = _DeletePropertyDetailIdleState;
  const factory DeletePropertyDetailState.loading({
    @Default(Failure.noFailure()) Failure failure
  }) = DeletePropertyDetailLoadingState;
  const factory DeletePropertyDetailState.done({
    @Default(Failure.noFailure()) Failure failure
  }) = DeletePropertyDetailDoneState;
  const factory DeletePropertyDetailState.error({
    @Default(Failure.noFailure()) Failure failure
  }) = DeletePropertyDetailErrorState;
}
```

Carrying `Failure` preserves type information so the UI can switch on failure type (e.g. show retry for `NoConnectionFailure`, redirect for `UnauthorizedFailure`).

### Sub-State Naming Convention

| Part                 | Pattern                                        | Example                                               |
| -------------------- | ---------------------------------------------- | ----------------------------------------------------- |
| Sub-state class      | `{Action}{BlocName}State`                      | `GetPropertyDetailState`, `DeletePropertyDetailState` |
| `.idle()` variant    | `_` prefix (private)                           | `_GetPropertyDetailIdleState`                         |
| `.loading()` variant | No prefix (public)                             | `GetPropertyDetailLoadingState`                       |
| `.done()` variant    | No prefix (public)                             | `GetPropertyDetailDoneState`                          |
| `.error()` variant   | No prefix (public)                             | `GetPropertyDetailErrorState`                         |
| State field name     | `{blocName}State` or `{action}{BlocName}State` | `propertyDetailState`, `deletePropertyDetailState`    |

---

### Non-Modular — Bloc with `Result<T>`

```dart
// property_detail_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'property_detail_bloc.freezed.dart';
part 'property_detail_event.dart';
part 'property_detail_state.dart';

@injectable
class PropertyDetailBloc extends Bloc<PropertyDetailEvent, PropertyDetailState> {
  PropertyDetailBloc(this._getPropertyDetail, this._deleteProperty)
      : super(const PropertyDetailState()) {
    on<_InitEvent>(_initEvent);
    on<_DeleteEvent>(_deleteEvent);
  }

  final GetPropertyDetailUsecase _getPropertyDetail;
  final DeletePropertyUsecase _deleteProperty;

  Future<void> _initEvent(_InitEvent event, Emitter<PropertyDetailState> emit) async {
    emit(
      state.copyWith(
        propertyDetailState: const GetPropertyDetailState.loading(),
      ),
    );
    final result = await _getPropertyDetail(propertyId: event.propertyId);
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            propertyDetailState: GetPropertyDetailState.done(property: value),
          ),
        );
      case Error(:final error):
        emit(
          state.copyWith(
            propertyDetailState: GetPropertyDetailState.error(failure: error),
          ),
        );
    }
  }

  Future<void> _deleteEvent(_DeleteEvent event, Emitter<PropertyDetailState> emit) async {
    emit(state.copyWith(deletePropertyDetailState: const DeletePropertyDetailState.loading()));
    final result = await _deleteProperty(propertyId: event.propertyId);
    switch (result) {
      case Ok():
        emit(state.copyWith(deletePropertyDetailState: const DeletePropertyDetailState.done()));
      case Error(:final error):
        emit(
          state.copyWith(
            deletePropertyDetailState: DeletePropertyDetailState.error(failure: error),
          ),
        );
    }
  }
}
```

### Modular — Bloc with `switch` on returned `Failure`

```dart
// packages/presentation/feature_property/lib/src/blocs/property_detail/property_detail_bloc.dart
import 'package:domain_common/domain_common.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'property_detail_bloc.freezed.dart';
part 'property_detail_event.dart';
part 'property_detail_state.dart';

@injectable
class PropertyDetailBloc extends Bloc<PropertyDetailEvent, PropertyDetailState> {
  PropertyDetailBloc(this._getPropertyDetail, this._deleteProperty)
      : super(const PropertyDetailState()) {
    on<_InitEvent>(_initEvent);
    on<_DeleteEvent>(_deleteEvent);
  }

  final GetPropertyDetailUsecase _getPropertyDetail;
  final DeletePropertyUsecase _deleteProperty;

  Future<void> _initEvent(_InitEvent event, Emitter<PropertyDetailState> emit) async {
    emit(
      state.copyWith(
        propertyDetailState: const GetPropertyDetailState.loading(),
      ),
    );
    final result = await _getPropertyDetail(propertyId: event.propertyId);
    switch (result.failure) {
      case NoFailure():
        emit(
          state.copyWith(
            propertyDetailState: GetPropertyDetailState.done(property: result.property),
          ),
        );
      default:
        emit(
          state.copyWith(
            propertyDetailState: GetPropertyDetailState.error(
              failure: result.failure,
            ),
          ),
        );
    }
  }

  Future<void> _deleteEvent(_DeleteEvent event, Emitter<PropertyDetailState> emit) async {
    emit(state.copyWith(deletePropertyDetailState: const DeletePropertyDetailState.loading()));
    final failure = await _deleteProperty(propertyId: event.propertyId);
    switch (failure) {
      case NoFailure():
        emit(state.copyWith(deletePropertyDetailState: const DeletePropertyDetailState.done()));
      default:
        emit(
          state.copyWith(
            deletePropertyDetailState: DeletePropertyDetailState.error(failure: failure),
          ),
        );
    }
  }
}
```

---

### BlocProvider — at page level, one bloc per page

```dart
BlocProvider(
  create: (_) => getIt<PropertyDetailBloc>()
    ..add(PropertyDetailEvent.init(propertyId: propertyId)),
  child: const PropertyDetailPage(),
)
```

### NO local UI state when Bloc exists

All UI state (loading, toggle, page index, etc.) must go through Bloc events/states.
Exception: Flutter controllers (TextEditingController, PageController, ScrollController, FocusNode, AnimationController, GlobalKey<FormState>) are OK as local fields.

### ScreenUtil — MANDATORY for all sizing

```dart
Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h))
16.verticalSpace
8.horizontalSpace
Icon(Icons.home, size: 24.sp)
BorderRadius.circular(12.r)
TextStyle(fontSize: 14.sp)
```

Use `num.verticalSpace` and `num.horizontalSpace` for empty gaps. Do not
use `SizedBox(height: N.h)` or `SizedBox(width: N.w)` as spacing. See
`${UFIL_ROOT}/docs/SCREENUTIL.md` for the complete mapping and exceptions.

### Paging Pattern

Use `PagingState` in Bloc + `PagedSliverList`/`PagedSliverGrid` in UI. Never manual `isLoading`/`hasMore` flags.

### BlocListener for side effects

#### Non-Modular

```dart
BlocListener<PropertyDetailBloc, PropertyDetailState>(
  listenWhen: (prev, curr) => prev.deletePropertyDetailState != curr.deletePropertyDetailState,
  listener: (context, state) {
    switch (state.deletePropertyDetailState) {
      case DeletePropertyDetailDoneState():
        Navigator.of(context).pop();
      case DeletePropertyDetailErrorState(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.toString())));
      default:
        break;
    }
  },
)
```

#### Modular — switch on `Failure` type for granular handling

```dart
BlocListener<PropertyDetailBloc, PropertyDetailState>(
  listenWhen: (prev, curr) => prev.deletePropertyDetailState != curr.deletePropertyDetailState,
  listener: (context, state) {
    switch (state.deletePropertyDetailState) {
      case DeletePropertyDetailDoneState():
        context.router.maybePop();
      case DeletePropertyDetailErrorState(:final failure):
        switch (failure) {
          case NoConnectionFailure():
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No internet connection. Please try again.')),
            );
          case UnauthorizedFailure():
            context.router.replaceAll([const LoginRoute()]);
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.toString())),
            );
        }
      default:
        break;
    }
  },
)
```

### Key Rules

- Never use Cubit — always Bloc with events
- One Bloc per page, `@injectable` (factory)
- App-level Blocs: `@lazySingleton` (shared)
- `part`/`part of` structure — event and state files are `part of` bloc file
- `@freezed abstract class` for events, states, sub-states (not `sealed class`)
- Sub-state naming: `{Action}{BlocName}State` with `.idle()`, `.loading()`, `.done()`, `.error()`
- `.idle()` variant is private (`_` prefix), `.loading()`/`.done()`/`.error()` are public
- Default event: `.init()` → `_InitEvent` → `_initEvent` handler
- Handler naming: handler method = camelCase of the event class name (leading `_` kept, first letter lowercased, `Event` suffix kept). `_GetTransactionEvent` → `_getTransactionEvent`, `_SubmittedEvent` → `_submittedEvent`. NEVER `_onX` / `_onXEvent` / `_handleX`.
- Single-module: `switch` on `Result` in event handlers; query usecases return `Future<Result<T>>`
- Modular: query usecases return `Future<Result>` (Result carries data + `Failure`); action usecases return `Future<Failure>`. `switch` on `result.failure` / returned `Failure` (`NoFailure` = success)
- All sub-state variants (`.idle()`/`.loading()`/`.done()`/`.error()`) share the SAME named params with defaults — `@Default(Failure.noFailure()) Failure failure` + optional `@Default(...) {DataType} {field}` for queries. The state class itself is uniform; only the *call sites* in the bloc are minimal.
- **Emit sub-states with the minimum payload** — `loading` uses the `const` default constructor (`const GetState.loading()`); `done` passes ONLY the new data (`GetState.done(property: value)`); `error` passes ONLY `failure` (`GetState.error(failure: failure)`). Do NOT preserve previous data on `loading`/`error`; the field's `@Default(...)` already provides a safe fallback.
- Sub-state unions per async action — never flat bool flags
- **Pages MUST NOT call UseCases directly.** Every async action — even one-shot ops like logout/refresh/delete — goes through a Bloc. The page does `context.read<TBloc>().add(event)` and reads via `BlocBuilder`/`BlocConsumer`/`BlocSelector`/`BlocListener`. A page that imports a UseCase or calls `getIt<XUseCase>()` is ALWAYS wrong, with no exceptions.

### References

- `${UFIL_ROOT}/docs/BLOC_PATTERN.md` — Detailed Bloc patterns and conventions
- `${UFIL_ROOT}/docs/PRESENTATION_LAYER.md` — Presentation layer structure
