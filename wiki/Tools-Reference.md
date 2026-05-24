# Tools Reference

Serena exposes its MCP tools to Claude with the `mcp__serena__` prefix. This page summarizes the tools you'll use most often. The complete, authoritative list lives at <https://oraios.github.io/serena/01-about/035_tools.html>.

> Which tools are available depends on the active **mode** and the project's `excluded_tools` / `fixed_tools` settings. If a tool is missing, check [Configuration](Configuration).

## Project lifecycle

| Tool | Purpose |
|---|---|
| `mcp__serena__initial_instructions` | Loads the Serena manual into Claude's context (call once at session start). |
| `mcp__serena__activate_project` | Activates the project at a given path — loads `project.yml`, starts the LSP. |
| `mcp__serena__check_onboarding_performed` | Checks whether `.serena/` has been onboarded. Plugins typically call this before `/plan` / `/implement`. |
| `mcp__serena__onboarding` | Runs onboarding (scans project structure, generates `project.yml` + seed memories). |
| `mcp__serena__list_dir`, `mcp__serena__read_file` | Read the filesystem through Serena's path-aware view (respects `ignored_paths`). |

## Symbol navigation (LSP)

The main reason to use Serena. **Always prefer these tools over `Grep`/`Glob`** when investigating code.

| Tool | Replaces | When to use |
|---|---|---|
| `find_symbol` | `Grep` for class/method names | Find a class or method by name (exact / fuzzy). |
| `find_declaration` | `Read` + scroll | Jump to a symbol's declaration / definition. |
| `find_referencing_symbols` | `Grep` for call sites | List every place a symbol is called or read. |
| `get_symbols_overview` | `Read` of the full file | Outline of classes / methods in a single file (without reading the bodies). |
| `get_diagnostics_for_file` | running a linter | LSP diagnostics (errors / warnings) per file. |
| `find_implementations` | grep for `implements`/`extends` | Find concrete classes implementing an interface or abstract type. |

## Symbolic editing

Structure-aware edits — not string-based find-and-replace.

| Tool | Purpose |
|---|---|
| `rename_symbol` | Rename a symbol across the whole project (safe: won't touch unrelated identical strings). |
| `replace_symbol_body` | Replace the entire body of a method/class without touching the signature or surrounding comments. |
| `insert_before_symbol` / `insert_after_symbol` | Insert code right above or below a target symbol. |

Editing tools are automatically disabled when `read_only: true`.

## Memories

Per-project memories live at `.serena/memories/*.md` and are loaded **on demand** (not auto-injected into context).

| Tool | Purpose |
|---|---|
| `list_memories` | List all active memory files. |
| `read_memory` | Read a specific memory. |
| `write_memory` | Write / overwrite a memory. |
| `delete_memory` | Delete a memory. |

Usage pattern: store architectural decisions, naming conventions, package layouts, onboarding summaries here so they don't need to be re-discovered every session. Use `read_only_memory_patterns` / `ignored_memory_patterns` in `project.yml` to lock or hide entries.

## Richer search

| Tool | Purpose |
|---|---|
| `search_for_pattern` | Search for a text pattern with scope filters (file / folder, globs). |
| `find_file` | Locate files by name using glob filters. |

These complement the LSP — use them when the target isn't a symbol (e.g. YAML config, string literals, HTML fragments).

## Shell (optional)

| Tool | Notes |
|---|---|
| `execute_shell_command` | Run a shell command at the project root. **Off by default** in some contexts. Enable via `included_optional_tools` if you want Serena to be allowed to run `rake`, `flutter pub get`, etc. |

## Recommended usage pattern

A typical workflow when asked to "add a new field to model X":

1. `find_symbol "X"` → locate the declaration.
2. `get_symbols_overview <file>` → see the methods in that file.
3. `find_referencing_symbols "X"` → list callers to anticipate the blast radius.
4. `replace_symbol_body` or `insert_after_symbol` → apply the edit.
5. `get_diagnostics_for_file` → confirm there are no errors.

Compare with the no-Serena workflow (3× `Grep`, 5× full-file `Read`, then manual edits) — Serena removes most of the token churn and the risk of mis-edits.
