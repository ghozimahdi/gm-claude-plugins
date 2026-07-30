# Project Structure

```
gm-aiagent-plugins/
├── .claude/
│   └── commands/
│       └── release.md              # Repo-level: /release <plugin> [version]
├── .claude-plugin/
│   └── marketplace.json            # Marketplace listing (all plugins)
├── .serena/                        # Serena LSP config (root level)
│   ├── project.yml
│   └── memories/
├── plugins/
│   └── ufil/                       # UFIL — Flutter Clean Architecture plugin
│       ├── .claude-plugin/
│       │   └── plugin.json         # Plugin metadata (name, version, repo)
│       ├── .mcp.json               # MCP servers: dart-flutter + serena
│       ├── .lsp.json               # LSP config
│       ├── .claudeignore           # Template for Flutter projects
│       ├── CLAUDE.md               # Plugin entry point — instructions for Claude
│       ├── README.md
│       ├── LICENSE
│       ├── agents/                 # AI agent definitions (3 agents)
│       │   ├── architect.md        # gm-architect (Opus)
│       │   ├── implementer.md      # gm-implementer (Sonnet)
│       │   └── reviewer.md         # gm-reviewer (Sonnet)
│       ├── commands/               # Plugin-specific slash commands (15+)
│       ├── skills/                 # Knowledge skills (8 skills)
│       ├── docs/                   # Detailed conventions (15 docs)
│       ├── hooks/
│       │   └── hooks.json          # PreToolUse, PostToolUse, SessionStart, Stop
│       └── scripts/                # Bash scripts + templates
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Adding a new plugin
1. Create `plugins/<plugin-name>/` with `.claude-plugin/plugin.json`, `CLAUDE.md`, etc.
2. Register in root `.claude-plugin/marketplace.json`

## File-format conventions
- **Skill files** (`SKILL.md`): frontmatter with `name`, `description`, `disable-model-invocation`
- **Command files** (`*.md`): frontmatter with `description`, `argument-hint`, `allowed-tools`
- **Agent files** (`*.md`): frontmatter with `name`, `description`, `model`, `maxTurns`
