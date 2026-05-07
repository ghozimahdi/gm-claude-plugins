#!/bin/bash
# Post-edit reminder: analyze Ruby files after editing
FILE_PATH="${1:-}"

if [[ "$FILE_PATH" == *.rb ]]; then
  echo "Reminder: Run 'bundle exec rubocop $FILE_PATH' to check style compliance."
fi
