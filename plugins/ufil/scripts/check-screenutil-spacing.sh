#!/usr/bin/env bash
# Reject pure-spacing SizedBox usage and wrong ScreenUtil axes in Dart sources.

set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "UFIL ScreenUtil spacing check requires rg (ripgrep)." >&2
  exit 2
fi

search_roots=()
if [[ $# -eq 0 ]]; then
  set -- lib packages test
fi

for candidate in "$@"; do
  if [[ -d "$candidate" ]]; then
    search_roots+=("$candidate")
  fi
done

if [[ ${#search_roots[@]} -eq 0 ]]; then
  exit 0
fi

wrong_axis_pattern='SizedBox\(\s*width:\s*[^,\n]+\.h\b|SizedBox\(\s*height:\s*[^,\n]+\.w\b'
pure_gap_pattern='SizedBox\(\s*(?:height:\s*[^,\n]+\.h|width:\s*[^,\n]+\.w)\s*,?\s*\)'
failed=0

if matches="$(rg --pcre2 --multiline -n --glob '*.dart' "$wrong_axis_pattern" "${search_roots[@]}" 2>/dev/null)"; then
  echo "UFIL ScreenUtil wrong-axis violations:" >&2
  echo "$matches" >&2
  failed=1
fi

if matches="$(rg --pcre2 --multiline -n --glob '*.dart' "$pure_gap_pattern" "${search_roots[@]}" 2>/dev/null)"; then
  echo "UFIL ScreenUtil spacing violations:" >&2
  echo "$matches" >&2
  echo "Use N.verticalSpace or N.horizontalSpace for empty gaps." >&2
  failed=1
fi

exit "$failed"
