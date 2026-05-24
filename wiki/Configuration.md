# Configuration

Per-project configuration lives in **`.serena/project.yml`**. The file is generated during onboarding and is safe to edit by hand.

## Minimum shape

```yaml
project_name: "my-app"
languages:
  - dart            # the first language is the default / fallback
encoding: "utf-8"
ignore_all_files_in_gitignore: true
```

That's enough for most single-language projects.

## Full option reference

### `project_name`
Serena's internal reference name (shown in tool output). Free-form; defaults to the folder name.

### `languages`
The list of languages whose language servers should be started. The **first one** is the default and fallback. When a file is opened, Serena picks the first LS that supports its extension.

A subset of supported languages:

```
bash  cpp  csharp  dart  elixir  go  java  kotlin
python  ruby  ruby_solargraph  rust  swift  typescript
```

The complete, up-to-date list lives in the [upstream Language enum](https://github.com/oraios/serena/blob/main/src/solidlsp/ls_config.py).

Special notes:
- For **C** → use `cpp`.
- For **JavaScript** → use `typescript`.
- For **Angular** → `angular` (subsumes TS + HTML; needs `npm install`).
- For **Svelte** → `svelte` (needs npm).

### `encoding` & `line_ending`
- `encoding`: defaults to `utf-8`.
- `line_ending`: `lf` | `crlf` | `native` | empty (use the global setting).

### `language_backend`
- `LSP` (default) — use real language servers.
- `JetBrains` — use IntelliJ / RubyMine / etc. as the backend (`languages` is ignored).

The backend is fixed at startup.

### `ignore_all_files_in_gitignore`
Defaults to `true`. Serena honors the project's `.gitignore`.

### `ignored_paths`
Gitignore-style patterns for additional paths to ignore.

```yaml
ignored_paths:
  - "vendor/**"
  - "tmp/**"
  - "**/*.generated.dart"
```

### `read_only`
`true` → all editing tools (rename, replace_symbol_body, etc.) are disabled. Useful for:
- reviewing code without any modification risk,
- exploring third-party codebases.

### `excluded_tools` / `included_optional_tools` / `fixed_tools`

Tool-set control:

- `excluded_tools` — normally-enabled tools you want disabled for this project.
- `included_optional_tools` — opt-in tools (off by default) you want enabled here.
- `fixed_tools` — **replaces** the entire default set with this list. Cannot be combined with either of the above.

Tool list: <https://oraios.github.io/serena/01-about/035_tools.html>.

### `default_modes` & `added_modes`
A mode = a preset of intent (e.g. `editing`, `query-projects`, `planning`). You can replace the default modes or add extras.

Details: <https://oraios.github.io/serena/02-usage/050_configuration.html#modes>.

### `additional_workspace_folders`
For monorepos. Each folder is registered as an LSP workspace folder so symbols resolve across packages. **Currently only supported for TypeScript.**

```yaml
additional_workspace_folders:
  - ../sibling-package
  - ../shared-lib
```

### `initial_prompt`
Text automatically injected into the LLM every time the project is activated. Good for project-specific conventions that must always be in mind:

```yaml
initial_prompt: |
  This codebase follows Clean Architecture (presentation → domain → data).
  Do not refactor across layers without explicit confirmation.
```

### `symbol_info_budget`
Seconds per tool call for fetching extra info (docstrings, parameter info). Overrides the global setting.

### Memory patterns

- `read_only_memory_patterns` — regex patterns marking memories as read-only.
- `ignored_memory_patterns` — regex patterns that hide memories entirely (won't appear in `list_memories`, can't be accessed via the memory tools). Still readable via `read_file` using the raw path.

```yaml
ignored_memory_patterns:
  - "_archive/.*"
  - "_episodes/.*"
```

## Example: UFIL config (Flutter)

```yaml
project_name: "my_flutter_app"
languages:
  - dart
encoding: "utf-8"
ignore_all_files_in_gitignore: true
ignored_paths:
  - "**/*.g.dart"
  - "**/*.freezed.dart"
  - "**/*.gr.dart"
  - "**/*.config.dart"
```

Rationale: generated files (build_runner, freezed, auto_route, injectable) don't need to be indexed — they add noise and bloat the LSP memory footprint.

## Example: Rubyku config (Rails 8)

```yaml
project_name: "my_rails_app"
languages:
  - ruby           # use the default ruby-lsp; switch to ruby_solargraph if needed
encoding: "utf-8"
ignore_all_files_in_gitignore: true
ignored_paths:
  - "tmp/**"
  - "log/**"
  - "storage/**"
  - "node_modules/**"
  - "public/assets/**"
```

## Applying config changes without a full restart

`project.yml` is read at **project activation**. After editing, call `mcp__serena__activate_project` again (or restart Claude Code) for changes to take effect.
