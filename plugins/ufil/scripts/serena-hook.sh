#!/usr/bin/env bash
# Wrapper that locates `serena-hooks` even when ~/.local/bin is not on PATH,
# then forwards all args to it. Silent no-op if not installed.

set -u

find_serena_hooks() {
  if command -v serena-hooks >/dev/null 2>&1; then
    command -v serena-hooks
    return 0
  fi
  for candidate in \
    "$HOME/.local/bin/serena-hooks" \
    "$HOME/.local/share/uv/tools/serena-agent/bin/serena-hooks"; do
    if [ -x "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

bin="$(find_serena_hooks)" || exit 0
exec "$bin" "$@"
