---
name: create-bloc
description: "Create a BLoC (3 files: bloc/event/state) following GM BLoC pattern with sub-state unions, optional AlertState, and optional Failure params."
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:create-bloc`; in Codex invoke it as `$ufil:create-bloc`. Resolve
`UFIL_ROOT` to the plugin root containing this skill; Claude Code may provide
`CLAUDE_PLUGIN_ROOT`, while Codex can resolve it from the installed skill path.

Create a BLoC (3 files) following GM `docs/BLOC_PATTERN.md` and `docs/NAMING_CONVENTIONS.md`.

Inspired by [vscode-flutter-bloc-generator](https://github.com/ghozimahdi/vscode-flutter-bloc-generator) — same `{name}_bloc.dart` / `{name}_event.dart` / `{name}_state.dart` layout, but tuned for GM BLoC conventions: freezed events/states, sub-state unions per async action, AlertState, and optional `Failure` params for modular projects.

**Script:** `${UFIL_ROOT}/scripts/create-bloc.sh`

```
create-bloc.sh <bloc_name> [--path <dir>] [--actions <a1,a2,...>] [--alert] [--with-failure]
```

Arguments: <requested arguments>

## Steps

### 1. Parse arguments

- `<bloc_name>` — snake_case (e.g., `home`, `login`, `property_detail`).
- `--path <dir>` — target directory (default: `.`). The folder `<bloc_name>/` is created inside.
- `--actions <a1,a2>` — comma-separated action names. Each one generates:
  - a sub-state class `{Action}State` with `idle` / `loading` / `done` / `error` variants
  - an event factory on the bloc event union
  - a handler stub in the bloc
- `--alert` — include `AlertState` (`idle` / `error` / `done`) on the main state. Reset to `idle` on loading; switched to `done` / `error` on result.
- `--with-failure` — error sub-states carry a positional `Failure failure` parameter and the bloc imports `package:domain_common/domain_common.dart`. Use this for modular projects.

### 2. Run the script

```bash
bash ${UFIL_ROOT}/scripts/create-bloc.sh <requested arguments>
```

### 3. Output structure

```
<path>/<bloc_name>/
├── <bloc_name>_bloc.dart       # @injectable, init handler + action handler stubs
├── <bloc_name>_event.dart      # part of bloc — freezed events with init({state})
└── <bloc_name>_state.dart      # part of bloc — main state + sub-state unions
```

### 4. Post-create

1. Inject use cases via constructor in the generated bloc class.
2. Replace the `// TODO: Call use case` comments with the real use case calls.
3. Run code generation:
   ```bash
   fvm dart run build_runner build --delete-conflicting-outputs
   ```

## Examples

```text
# Minimal bloc — only the init event
/ufil:create-bloc home            # Claude Code
$ufil:create-bloc home            # Codex

# Home bloc with two actions + AlertState (matches docs/BLOC_PATTERN.md exactly)
/ufil:create-bloc home --actions get_transaction,add_transaction --alert

# Modular property bloc — Failure-typed errors, custom path
/ufil:create-bloc property_detail \
  --path packages/presentation/feature_property/lib/src/blocs \
  --actions get_property_detail,delete_property \
  --with-failure
```

## Conventions Applied

- **File layout**: folder `{name}/` containing `{name}_bloc.dart` / `{name}_event.dart` / `{name}_state.dart`
- **`part` / `part of`** — event and state files are `part of` the bloc file
- **`@injectable`** annotation on the bloc
- **`@freezed abstract class`** for events and states
- **Init event** is mandatory with a `state` parameter (default = `BlocState()`); handler emits `event.state`
- **Sub-state unions** per async action with `.idle()` / `.loading()` / `.done()` / `.error()` variants
- **State field name** = `{action}State` (camelCase), e.g., `getTransactionState`
- **Sub-state class** = `{Action}State`; concrete classes `{Action}IdleState` / `{Action}LoadingState` / `{Action}DoneState` / `{Action}ErrorState`
- **AlertState** (optional) — `idle` / `error` / `done`, reset on loading
- **Error param** (optional, `--with-failure`) — `Failure failure` positional parameter

## When to use vs `generate-module`

- **`create-bloc`** — adds a single bloc to an existing feature. No domain/data scaffolding, no DI wiring beyond `@injectable`. Quick local generation, like the VSCode extension.
- **`generate-module`** — full feature scaffold across `domain_*` / `data_*` / `feature_*` packages (modular) or `lib/features/<name>/` (single-module). Use for new features.

## References

Plugin docs live under the resolved `UFIL_ROOT`.

- `${UFIL_ROOT}/docs/BLOC_PATTERN.md` — Full BLoC pattern guidelines (source of truth)
- `${UFIL_ROOT}/docs/NAMING_CONVENTIONS.md` — Naming standards for bloc/event/state files and sub-state classes
- `${UFIL_ROOT}/skills/bloc-pattern/SKILL.md` — Bloc patterns reference (modular vs single-module)
