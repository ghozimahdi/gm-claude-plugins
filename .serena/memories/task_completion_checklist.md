# Task Completion Checklist

This repo is a Claude Code plugin marketplace (Markdown + Bash). There is **no compile/test step**. The checks below are what to verify before opening a PR.

## When editing a plugin (e.g. ufil)

1. **Frontmatter is valid** — the file type's required fields are present:
   - Skills (`skills/<n>/SKILL.md`): `name`, `description`, `disable-model-invocation`
   - Commands (`commands/<n>.md`): `description`, `argument-hint`, `allowed-tools`
   - Agents (`agents/<n>.md`): `name`, `description`, `model`, `maxTurns`
2. **Markdown is well-formatted** — fenced code blocks have language identifiers
3. **Cross-references are accurate** — plugin README.md command/skill/agent counts match actual file counts; CLAUDE.md table aligns with README
4. **No hardcoded versions** in scaffold templates
5. **If you modified scripts** — test them against a scratch project
6. **If you modified `hooks/hooks.json`** — verify valid JSON and `${CLAUDE_PLUGIN_ROOT}` references resolve
7. **If you modified MCP config** (`.mcp.json`) — verify server starts cleanly
8. **Reload locally** — `/reload-plugins` after edits

## When editing repo-level files

1. **Root README.md** — plugin table is up to date
2. **CONTRIBUTING.md** — structure diagram matches reality
3. **`.claude-plugin/marketplace.json`** — all plugins listed with correct source paths
4. **`.claude/commands/`** — commands work for any plugin, not hardcoded to one

## Git workflow

- Branch from `main`, use Conventional Commits with plugin scope
- Push to fork, open PR against `main`
- Keep PRs focused on a single concern
