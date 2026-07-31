#!/usr/bin/env bash
# Cross-client PreToolUse hook: hard-block raw code reads/greps when Serena is
# active for this project, forcing symbolic tools (get_symbols_overview,
# find_symbol, find_referencing_symbols, search_for_pattern) instead.
#
# Unlike upstream serena-agent's `serena-hooks remind` (a soft nudge: denies
# only after a burst threshold, then resets and grants a grace window), this
# denies every matching call unconditionally, every time, while the project
# has been onboarded with Serena (.serena/project.yml present).
#
# Escape hatch: create a `.serena/no-enforce` file to disable this hook for a
# project without touching plugin config (e.g. if Serena's MCP server is down
# and you need raw reads to keep working).

set -u

[[ -f ".serena/project.yml" ]] || exit 0
[[ -f ".serena/no-enforce" ]] && exit 0

hook_input="$(cat)"
[[ -z "$hook_input" ]] && exit 0

# Flatten to a single line so key/value extraction works regardless of whether
# the client sends compact or pretty-printed JSON.
flat="$(printf '%s' "$hook_input" | tr '\n' ' ')"

extract_field() {
  printf '%s' "$flat" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed -E "s/\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
}

tool_name="$(extract_field "tool_name")"
[[ -z "$tool_name" ]] && tool_name="$(extract_field "toolName")"

# Same extension list serena-agent's own hooks.py treats as "code-like" for its
# read-file classification, so this hard block and the upstream soft nudge
# agree on scope.
code_ext_regex='\.(al|bash|c|clj|cljs|cpp|cs|css|dart|elm|ex|exs|fs|fsx|go|graphql|gql|groovy|h|hcl|hpp|hs|html|java|jl|js|json|jsonc|jsx|kt|kts|lean|lua|m|matlab|php|proto|ps1|py|r|rb|rs|scala|sh|sol|sql|svelte|swift|tf|tfvars|toml|ts|tsx|vue|yaml|yml|zig)$'

deny() {
  local reason="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s","additionalContext":"%s"}}' \
    "$reason" "$reason"
  exit 0
}

case "$tool_name" in
  Read)
    file_path="$(extract_field "file_path")"
    [[ -z "$file_path" ]] && file_path="$(extract_field "filePath")"
    if [[ "$file_path" =~ $code_ext_regex ]]; then
      deny "Serena is active for this project (.serena/project.yml). Use Serena's symbolic tools (get_symbols_overview, find_symbol) instead of Read for code files. Create .serena/no-enforce to disable this if Serena is unavailable."
    fi
    ;;
  Grep)
    deny "Serena is active for this project (.serena/project.yml). Use Serena's search_for_pattern / find_symbol / find_referencing_symbols instead of Grep. Create .serena/no-enforce to disable this if Serena is unavailable."
    ;;
  Bash)
    command_str="$(extract_field "command")"
    first_word="$(printf '%s' "$command_str" | awk '{print $1}')"
    case "$first_word" in
      cat | head | tail | less | more | bat)
        if [[ "$command_str" =~ $code_ext_regex ]]; then
          deny "Serena is active for this project (.serena/project.yml). Use Serena's symbolic tools instead of shell '$first_word' on code files. Create .serena/no-enforce to disable this if Serena is unavailable."
        fi
        ;;
      grep | rg | ag | ack | fgrep | egrep)
        deny "Serena is active for this project (.serena/project.yml). Use Serena's search_for_pattern / find_symbol instead of shell '$first_word'. Create .serena/no-enforce to disable this if Serena is unavailable."
        ;;
    esac
    ;;
esac

exit 0
