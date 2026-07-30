#!/usr/bin/env bash
# Cross-client PreToolUse hook. Run Flutter checks only before `git commit`.

set -u

hook_input="$(cat)"
if [[ -z "$hook_input" ]]; then
  hook_input="${CLAUDE_TOOL_INPUT:-}"
fi

case "$hook_input" in
  *'"command":"git commit'*|*'"command": "git commit'*)
    ;;
  *)
    exit 0
    ;;
esac

if ! command -v fvm >/dev/null 2>&1 || [[ ! -d lib ]]; then
  exit 0
fi

fvm dart fix --apply lib >&2 || exit 2

format_paths=(lib)
if [[ -d test ]]; then
  format_paths+=(test)
fi

fvm dart format "${format_paths[@]}" >&2 || exit 2
fvm dart analyze "${format_paths[@]}" >&2 || exit 2

exit 0
