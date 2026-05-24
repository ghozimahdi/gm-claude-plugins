# Troubleshooting

## `uvx: command not found`

Serena is bootstrapped through `uvx`. Without `uv` installed, the MCP server can't start.

```bash
brew install uv                                     # macOS
curl -LsSf https://astral.sh/uv/install.sh | sh     # cross-platform
```

Make sure the `uv` / `uvx` binaries are on the `PATH` of the same shell Claude Code is launched from. After installing, restart Claude Code (the MCP process is re-spawned).

## MCP server `serena` shows "disconnected" / "failed"

Check the logs:

```bash
# Claude Code (CLI) stores per-server MCP logs
ls ~/.cache/claude-code/mcp-logs/ 2>/dev/null
```

Most common causes:

1. **`uvx` clone failed** — GitHub down / firewall. Try manually:
   ```bash
   uvx --from git+https://github.com/oraios/serena serena --help
   ```
2. **`uv` Python version conflict** — clear the cache:
   ```bash
   uv cache clean
   ```
3. **Malformed `.mcp.json`** — the JSON must be valid. Check with `jq . .mcp.json`.

## Onboarding never runs

Symptom: tools like `find_symbol` always reply "project not onboarded".

Usually because: the `.serena/` directory doesn't exist **or** there are no source files matching the languages in `languages` to justify onboarding.

Fix:

```bash
# Remove .serena/ so it's truly fresh
rm -rf .serena/

# Restart Claude in the project, then ask it to:
#   "call mcp__serena__onboarding"
# (or, for the UFIL plugin: run /serena-refresh)
```

If your target language is missing from `languages`, add it to `.serena/project.yml` first.

## Language server crashes / is very slow

Some LSes (especially Solargraph on big Ruby codebases, or angular-language-server) are genuinely heavy. Mitigations:

- Expand `ignored_paths` so generated files aren't indexed (`*.g.dart`, `node_modules/**`, `public/assets/**`, etc.).
- For Ruby: compare the default `ruby` vs. `ruby_solargraph` — pick the one that's more stable for your codebase.
- For TS monorepos: make sure `additional_workspace_folders` is correct; if wrong, the LSP keeps re-resolving dependencies.

## "Stale" index after a big refactor / branch switch

Serena's index isn't automatically invalidated when the folder structure changes drastically. Symptom: `find_symbol` returns files that no longer exist or classes that have been renamed.

Fix:
- UFIL plugin: `/serena-refresh`.
- Manually: `rm -rf .serena/` and re-onboard.
- For memories: edit / delete `.serena/memories/*.md` directly.

## Serena tools ask for confirmation every time

By default Claude Code prompts for approval on every MCP tool call. The plugins in this repo already wire an auto-approve hook for `mcp__serena__.*`.

If you're **not** using the plugins, add this to `~/.claude/settings.json` or the project's `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["mcp__serena__*"]
  }
}
```

> ⚠️ Weigh the risk. Tools like `execute_shell_command` (when enabled) should **not** receive a blanket auto-approve.

## Memory grows out of control

`.serena/memories/` keeps growing if Claude writes freely. Mitigations:

- Set `read_only_memory_patterns` in `project.yml` to lock memories that have stabilized.
- Set `ignored_memory_patterns` to hide a category (e.g. `_archive/.*`).
- Audit `memories/` periodically — those files are Markdown, safe to edit / delete by hand.

## Serena can't find a symbol that obviously exists

Check the chain:

1. Is the file caught by `ignored_paths` or `.gitignore`? Set `ignore_all_files_in_gitignore: false` if that's not what you want.
2. Does the file's language match an LS? Check `languages` — Serena uses the first LS that supports the extension.
3. Has the LSP finished indexing? Fresh files sometimes take a few seconds.
4. Have you re-onboarded after a significant change? Try `/serena-refresh` or `rm -rf .serena/`.

## Reporting Serena bugs

Bugs in Serena itself (not the plugin) → [oraios/serena issues](https://github.com/oraios/serena/issues). Include:
- versions: `uv --version`, `uvx --version`,
- the `languages` block from `project.yml`,
- the relevant MCP log (path listed above),
- a minimal reproduction.
