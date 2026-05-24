# Usage in Plugins

The plugins in this repo (`ufil` and `rubyku`) make Serena the **default navigation layer** for any non-trivial task. This page explains how each plugin activates, steers, and fences Serena so the user experience stays smooth.

## Shared principles

1. **Serena first, Grep second.** Every agent (architect / implementer / reviewer) is instructed to prefer `find_symbol`, `find_referencing_symbols`, `get_symbols_overview` before falling back to `Grep` / `Read`. The reason: lower token cost and LSP-grade accuracy.
2. **Lazy onboarding.** The plugins do not ship a pre-built `.serena/`. Serena's index is project-specific — a generic seed would actively mislead.
3. **Auto-approve for Serena tools.** A plugin hook ensures `mcp__serena__*` calls don't trigger a user confirmation each time — Serena is considered safe because it's read-mostly and operates within the project root.
4. **Manual refresh after large changes.** A `/serena-refresh` command (UFIL) is provided to force re-onboarding after a big refactor or branch switch.

## UFIL (Flutter/Dart)

UFIL's `.mcp.json` runs **two** servers side by side:

```json
{
  "mcpServers": {
    "dart-flutter": { "command": "dart", "args": ["mcp-server"] },
    "serena":       { "command": "uvx",  "args": ["--from", "git+https://github.com/oraios/serena", "serena", "start-mcp-server", "--context", "claude-code", "--project", "."] }
  }
}
```

- **dart-flutter MCP** → Dart-specific analysis (pub, build_runner, melos).
- **Serena** → cross-package symbol navigation (Clean Architecture: presentation/domain/data).

### UFIL onboarding behavior

Driven by command:

| Command | Checks `check_onboarding_performed`? | Triggers `onboarding`? |
|---|---|---|
| `/init-project` | ❌ — fresh scaffold, the index would immediately go stale | ❌ |
| `/plan`, `/implement`, `/implement-batch` | ✅ every invocation | ✅ if not onboarded **and** Dart files are detected |
| `/serena-refresh` | — | ✅ forced, even if already onboarded |

If there are no Dart files at all (e.g. opening a brand-new project for scaffolding), the plugin **skips** onboarding and falls back to `Glob` / `Grep` / `Read` — then retries on the next invocation.

### UFIL hooks related to Serena

From `plugins/ufil/hooks/hooks.json`:

```jsonc
"PreToolUse": [
  { "matcher": "", "hooks": [{ "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/serena-hook.sh remind --client=claude-code"
  }]},
  { "matcher": "mcp__serena__.*", "hooks": [{ "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/serena-hook.sh auto-approve --client=claude-code"
  }]}
],
"SessionStart": [{ "matcher": "", "hooks": [{ "type": "command",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/install-serena.sh && ${CLAUDE_PLUGIN_ROOT}/scripts/serena-hook.sh activate --client=claude-code"
}]}],
"Stop": [{ "matcher": "", "hooks": [{ "type": "command",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/serena-hook.sh cleanup --client=claude-code"
}]}]
```

- `SessionStart` → ensure Serena is installed (`install-serena.sh`) and the project is activated.
- `PreToolUse` (empty matcher) → reminds the agent to prefer Serena.
- `PreToolUse` (matcher `mcp__serena__.*`) → auto-approve Serena tools.
- `Stop` → per-session cleanup.

### Serena-related paths in UFIL

```
plugins/ufil/
├── .mcp.json                 # MCP server list (includes serena)
├── scripts/
│   ├── install-serena.sh     # ensures uv + serena are available
│   └── serena-hook.sh        # remind / auto-approve / activate / cleanup
└── commands/
    └── serena-refresh.md     # /serena-refresh
```

## Rubyku (Rails 8)

Rubyku's `.mcp.json` is simpler — Serena only:

```json
{
  "mcpServers": {
    "serena": { "command": "uvx", "args": [/* same as UFIL */] }
  }
}
```

Target language in `.serena/project.yml`:

```yaml
languages:
  - ruby           # or ruby_solargraph for the alternate LSP
```

### Rubyku navigation convention

From Rubyku's `CLAUDE.md`:

> **Before coding anything**, call `mcp__serena__initial_instructions` then `mcp__serena__activate_project`. **Always** prefer Serena tools over `Grep` / `Glob` / `Read` for navigation.

The mapping:

| Day-to-day Rails task | Use Serena | Not |
|---|---|---|
| Find a model / controller | `find_symbol` | `Grep "class User"` |
| Jump to a method's definition | `find_declaration` | `Read` + scroll |
| Check callers of `before_action :authorize` | `find_referencing_symbols` | `Grep "authorize"` |
| Outline `app/models/order.rb` | `get_symbols_overview` | full-file `Read` |
| Safely rename `OrderConcern` | `rename_symbol` | sed / manual `Edit` |
| Edit the body of `def process` | `replace_symbol_body` | manual edit |

### Rubyku hooks related to Serena

`plugins/rubyku/hooks/hooks.json` likewise wires auto-approve for `mcp__serena__.*`, alongside the pre-commit RuboCop and guideline-reviewer hooks. Same pattern as UFIL — inspect the file for details.

## Adopting Serena in a new plugin

If you're writing a new plugin in this repo:

1. Copy the `serena` block from `.mcp.json` into your plugin. Tune `languages` in `.serena/project.yml`.
2. Add an auto-approve hook for `mcp__serena__.*` in `hooks.json` so the UX isn't interrupted by repeated confirmations.
3. In the agent prompts, **explicitly** state the Serena-vs-Grep preference — the model doesn't always guess right without instruction.
4. Provide a `/serena-refresh`-equivalent command if your plugin will be used on repos that see frequent large refactors.
