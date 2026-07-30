#!/usr/bin/env bash
# Cross-client post-edit hook: report a reminder after editing a Dart file.

set -u

hook_input="$(cat)"
if [[ -z "$hook_input" ]]; then
  hook_input="${CLAUDE_TOOL_INPUT:-}"
fi

if [[ "$hook_input" == *".dart"* ]]; then
  echo '{"message": "Dart file edited. Remember to run analyze before committing."}'
fi

exit 0
