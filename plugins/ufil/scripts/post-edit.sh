#!/bin/bash
# Post-edit hook: checks if a .dart file was edited and reports reminder
# This hook runs after every Write/Edit tool call

TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# Only act on .dart files
if echo "$TOOL_INPUT" | grep -q '\.dart'; then
  echo '{"message": "Dart file edited. Remember to run analyze before committing."}'
fi

exit 0
