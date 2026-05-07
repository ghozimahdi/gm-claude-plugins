#!/bin/bash
# UFIL — Create a BLoC (3 files) following BLOC_PATTERN.md + NAMING_CONVENTIONS.md
# Inspired by https://github.com/ghozimahdi/vscode-flutter-bloc-generator
#
# Usage:
#   create-bloc.sh <bloc_name> [--path <dir>] [--actions <a1,a2,...>] [--alert] [--with-failure]
#
# Examples:
#   create-bloc.sh home
#   create-bloc.sh home --actions get_transaction,add_transaction --alert
#   create-bloc.sh property_detail \
#       --path packages/presentation/feature_property/lib/src/blocs \
#       --actions get_property_detail,delete_property --with-failure
#
# Output:
#   <path>/<bloc_name>/
#     ├── <bloc_name>_bloc.dart
#     ├── <bloc_name>_event.dart
#     └── <bloc_name>_state.dart

set -e

BLOC_NAME="${1:-}"
if [ -z "$BLOC_NAME" ] || [[ "$BLOC_NAME" == --* ]]; then
  echo "❌ Usage: create-bloc.sh <bloc_name> [--path <dir>] [--actions <a1,a2>] [--alert] [--with-failure]"
  exit 1
fi
shift

TARGET_PATH="."
ACTIONS=""
INCLUDE_ALERT=false
WITH_FAILURE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --path) TARGET_PATH="$2"; shift 2 ;;
    --actions) ACTIONS="$2"; shift 2 ;;
    --alert) INCLUDE_ALERT=true; shift ;;
    --with-failure) WITH_FAILURE=true; shift ;;
    *) echo "❌ Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate snake_case
if ! echo "$BLOC_NAME" | grep -qE '^[a-z][a-z0-9_]*$'; then
  echo "❌ bloc_name must be snake_case (e.g., 'home', 'login_form'). Got: $BLOC_NAME"
  exit 1
fi

# snake_case → PascalCase
to_pascal() {
  echo "$1" | perl -pe 's/(^|_)(\w)/\U$2/g'
}

# snake_case → camelCase
to_camel() {
  local pascal first
  pascal=$(to_pascal "$1")
  first=$(printf "%s" "${pascal:0:1}" | tr '[:upper:]' '[:lower:]')
  printf "%s%s" "$first" "${pascal:1}"
}

BLOC_PASCAL=$(to_pascal "$BLOC_NAME")
BLOC_FOLDER="${TARGET_PATH%/}/$BLOC_NAME"

if [ -d "$BLOC_FOLDER" ]; then
  echo "❌ Folder already exists: $BLOC_FOLDER"
  exit 1
fi

mkdir -p "$BLOC_FOLDER"

# Parse actions into array
ACTION_ARR=()
if [ -n "$ACTIONS" ]; then
  IFS=',' read -ra ACTION_ARR <<< "$ACTIONS"
fi

BLOC_FILE="$BLOC_FOLDER/${BLOC_NAME}_bloc.dart"
EVENT_FILE="$BLOC_FOLDER/${BLOC_NAME}_event.dart"
STATE_FILE="$BLOC_FOLDER/${BLOC_NAME}_state.dart"

# ===========================================================================
# {bloc}_bloc.dart
# ===========================================================================
{
  if [ "$WITH_FAILURE" = true ]; then
    echo "import 'package:domain_common/domain_common.dart';"
  fi
  echo "import 'package:flutter_bloc/flutter_bloc.dart';"
  echo "import 'package:freezed_annotation/freezed_annotation.dart';"
  echo "import 'package:injectable/injectable.dart';"
  echo
  echo "part '${BLOC_NAME}_bloc.freezed.dart';"
  echo "part '${BLOC_NAME}_event.dart';"
  echo "part '${BLOC_NAME}_state.dart';"
  echo
  echo "@injectable"
  echo "class ${BLOC_PASCAL}Bloc extends Bloc<${BLOC_PASCAL}Event, ${BLOC_PASCAL}State> {"
  echo "  ${BLOC_PASCAL}Bloc() : super(const ${BLOC_PASCAL}State()) {"
  echo "    on<_InitEvent>(_initEvent);"
  for action in "${ACTION_ARR[@]}"; do
    [ -z "$action" ] && continue
    AP=$(to_pascal "$action")
    AC=$(to_camel "$action")
    echo "    on<_${AP}Event>(_${AC}Event);"
  done
  echo "  }"
  echo
  echo "  Future<void> _initEvent("
  echo "    _InitEvent event,"
  echo "    Emitter<${BLOC_PASCAL}State> emit,"
  echo "  ) async {"
  echo "    emit(event.state);"
  echo "  }"
  for action in "${ACTION_ARR[@]}"; do
    [ -z "$action" ] && continue
    AP=$(to_pascal "$action")
    AC=$(to_camel "$action")
    echo
    echo "  Future<void> _${AC}Event("
    echo "    _${AP}Event event,"
    echo "    Emitter<${BLOC_PASCAL}State> emit,"
    echo "  ) async {"
    echo "    emit("
    echo "      state.copyWith("
    echo "        ${AC}State: const ${AP}State.loading(),"
    if [ "$INCLUDE_ALERT" = true ]; then
      echo "        alertState: const AlertState.idle(),"
    fi
    echo "      ),"
    echo "    );"
    echo
    echo "    // TODO: Call use case and emit done/error"
    if [ "$WITH_FAILURE" = true ]; then
      echo "    // final failure = await _${AC}UseCase();"
      echo "    // switch (failure) {"
      echo "    //   case NoFailure():"
      echo "    //     emit("
      echo "    //       state.copyWith("
      echo "    //         ${AC}State: const ${AP}State.done(),"
      if [ "$INCLUDE_ALERT" = true ]; then
        echo "    //         alertState: const AlertState.done(),"
      fi
      echo "    //       ),"
      echo "    //     );"
      echo "    //   default:"
      echo "    //     emit("
      echo "    //       state.copyWith("
      echo "    //         ${AC}State: ${AP}State.error(failure),"
      if [ "$INCLUDE_ALERT" = true ]; then
        echo "    //         alertState: const AlertState.error(),"
      fi
      echo "    //       ),"
      echo "    //     );"
      echo "    // }"
    else
      echo "    // final params = ${AP}Params();"
      echo "    // final result = await _${AC}UseCase.call(params);"
      echo "    // if (!result.isSuccess) {"
      echo "    //   emit("
      echo "    //     state.copyWith("
      echo "    //       ${AC}State: const ${AP}State.error(),"
      if [ "$INCLUDE_ALERT" = true ]; then
        echo "    //       alertState: const AlertState.error(),"
      fi
      echo "    //     ),"
      echo "    //   );"
      echo "    //   return;"
      echo "    // }"
      echo "    //"
      echo "    // emit("
      echo "    //   state.copyWith("
      echo "    //     ${AC}State: const ${AP}State.done(),"
      if [ "$INCLUDE_ALERT" = true ]; then
        echo "    //     alertState: const AlertState.done(),"
      fi
      echo "    //   ),"
      echo "    // );"
    fi
    echo "  }"
  done
  echo "}"
} > "$BLOC_FILE"

# ===========================================================================
# {bloc}_event.dart
# ===========================================================================
{
  echo "part of '${BLOC_NAME}_bloc.dart';"
  echo
  echo "@freezed"
  echo "abstract class ${BLOC_PASCAL}Event with _\$${BLOC_PASCAL}Event {"
  echo "  const factory ${BLOC_PASCAL}Event.init({"
  echo "    @Default(${BLOC_PASCAL}State()) ${BLOC_PASCAL}State state,"
  echo "  }) = _InitEvent;"
  for action in "${ACTION_ARR[@]}"; do
    [ -z "$action" ] && continue
    AP=$(to_pascal "$action")
    AC=$(to_camel "$action")
    echo
    echo "  const factory ${BLOC_PASCAL}Event.${AC}() = _${AP}Event;"
  done
  echo "}"
} > "$EVENT_FILE"

# ===========================================================================
# {bloc}_state.dart
# ===========================================================================
{
  echo "part of '${BLOC_NAME}_bloc.dart';"
  echo
  echo "@freezed"
  echo "abstract class ${BLOC_PASCAL}State with _\$${BLOC_PASCAL}State {"
  echo "  const factory ${BLOC_PASCAL}State({"
  for action in "${ACTION_ARR[@]}"; do
    [ -z "$action" ] && continue
    AP=$(to_pascal "$action")
    AC=$(to_camel "$action")
    echo "    @Default(${AP}State.idle()) ${AP}State ${AC}State,"
  done
  if [ "$INCLUDE_ALERT" = true ]; then
    echo "    @Default(AlertState.idle()) AlertState alertState,"
  fi
  echo "  }) = _${BLOC_PASCAL}State;"
  echo "}"
  for action in "${ACTION_ARR[@]}"; do
    [ -z "$action" ] && continue
    AP=$(to_pascal "$action")
    echo
    echo "@freezed"
    echo "abstract class ${AP}State with _\$${AP}State {"
    echo "  const factory ${AP}State.idle() = ${AP}IdleState;"
    echo "  const factory ${AP}State.loading() = ${AP}LoadingState;"
    echo "  const factory ${AP}State.done() = ${AP}DoneState;"
    if [ "$WITH_FAILURE" = true ]; then
      echo "  const factory ${AP}State.error(Failure failure) = ${AP}ErrorState;"
    else
      echo "  const factory ${AP}State.error() = ${AP}ErrorState;"
    fi
    echo "}"
  done
  if [ "$INCLUDE_ALERT" = true ]; then
    echo
    echo "@freezed"
    echo "abstract class AlertState with _\$AlertState {"
    echo "  const factory AlertState.idle() = AlertIdleState;"
    echo "  const factory AlertState.error() = AlertErrorState;"
    echo "  const factory AlertState.done() = AlertDoneState;"
    echo "}"
  fi
} > "$STATE_FILE"

echo "✅ Created BLoC at: $BLOC_FOLDER"
echo "   - ${BLOC_NAME}_bloc.dart"
echo "   - ${BLOC_NAME}_event.dart"
echo "   - ${BLOC_NAME}_state.dart"
echo
echo "Next steps:"
echo "  1. Inject use cases via constructor in ${BLOC_PASCAL}Bloc"
echo "  2. Run code generation:"
echo "       fvm dart run build_runner build --delete-conflicting-outputs"
