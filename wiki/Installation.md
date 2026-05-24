# Installation

Serena runs as a local **MCP server**. There's no global package — `uvx` pulls it from GitHub each time Claude Code starts, then caches it via `uv`.

## 1. Prerequisites

| Component                       | Required?    | Notes                                                                                                                                                                                              |
| ------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `uv` / `uvx`                    | ✅           | Python loader from Astral. Without it Serena cannot start.                                                                                                                                         |
| `git`                           | ✅           | `uvx` clones Serena from GitHub.                                                                                                                                                                   |
| Claude Code with MCP support    | ✅           | Recent CLI/Desktop versions already support MCP.                                                                                                                                                   |
| Language server for your target | ⚠️ Sometimes | Popular languages (Ruby/Solargraph, Dart, TS, Go, Python) are bundled / auto-installed by Serena. For others — see the [upstream docs](https://oraios.github.io/serena/01-about/020_programming-languages.html). |

### Install `uv` (macOS)

```bash
brew install uv
# or via the official installer:
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Verify:

```bash
uv --version
uvx --version
```

## 2. Register Serena in your project

Add a `.mcp.json` at the **project root** (not a global config):

```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--context",
        "claude-code",
        "--project",
        "."
      ]
    }
  }
}
```

Key arguments:

- `--context claude-code` — preset prompt & tool set tuned for Claude Code.
- `--project .` — Serena uses Claude's cwd as the project root. You can pass an absolute path if the project root differs from cwd.

> 💡 Already have other MCP servers? Just add Serena alongside them — don't overwrite the whole `.mcp.json`. The UFIL plugin, for example, runs Serena **plus** the Dart MCP side by side.

## 3. Start Claude Code and onboard

Run Claude in your project directory:

```bash
claude
```

On the first interaction that needs code navigation, Claude (or the plugin) will call:

1. `mcp__serena__check_onboarding_performed` → checks whether `.serena/` already has an index.
2. If not: `mcp__serena__onboarding` → Serena reads files, scans the structure, generates `project.yml` plus seed memories.
3. The session is ready. Tools like `find_symbol`, `find_referencing_symbols`, etc. start working.

The result is a `.serena/` directory at the project root that looks roughly like:

```
.serena/
├── .gitignore
├── project.yml        # project configuration (auto-generated, editable)
└── memories/          # persistent notes across sessions
    ├── project_overview.md
    ├── architecture.md
    └── ...
```

## 4. (Optional) Commit `.serena/`?

| File                    | Commit?          | Reason                                                                                |
| ----------------------- | ---------------- | ------------------------------------------------------------------------------------- |
| `.serena/project.yml`   | ✅               | Reusable configuration; share across teammates / CI.                                  |
| `.serena/memories/*.md` | ⚖️ Team-dependent | Architecture notes are usually useful for the team. Personal trial/error notes — not. |
| LSP index cache         | ❌               | Already ignored by the default `.serena/.gitignore`.                                  |

The default `.serena/.gitignore` excludes cache files; `memories/` contents are yours to curate.

## 5. Verify

Inside Claude Code:

```
/mcp
```

This lists active MCP servers. `serena` must appear with a connected status. If it failed to start, see [Troubleshooting](Troubleshooting).
