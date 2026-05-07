# Tech Stack

This is a **Claude Code plugin marketplace repository**, not a runtime application. It contains Markdown definitions and shell scripts.

## Repo-level tech
- **Plugin format**: Claude Code plugin marketplace (`.claude-plugin/marketplace.json` at root, `.claude-plugin/plugin.json` per plugin)
- **Repo commands**: `.claude/commands/` — repo-level slash commands (e.g. `/release`)
- **Serena**: `.serena/` at root for LSP intelligence
- **VCS**: Git + GitHub

## Per-plugin tech (example: ufil)
- **Definitions**: Markdown files with YAML frontmatter (agents, skills, commands)
- **Scripts**: Bash (`scripts/*.sh`)
- **Hooks config**: `hooks/hooks.json` (PreToolUse, PostToolUse, SessionStart, Stop)
- **MCP**: `.mcp.json` — plugin-specific MCP servers
- **LSP**: `.lsp.json` — plugin-specific LSP config

## Developer tools
- **Git** — version control
- **gh** — GitHub CLI for releases
- **Serena** — `pip install serena` or `uvx serena` (LSP intelligence)
- **FVM** — only needed when testing Flutter plugins in target projects
- **RTK** — auto-installed by ufil plugin on SessionStart
