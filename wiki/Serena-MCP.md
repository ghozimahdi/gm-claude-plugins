# Serena MCP

[Serena](https://github.com/oraios/serena) is a [Model Context Protocol](https://modelcontextprotocol.io) server that brings LSP-grade code navigation (find symbol, references, rename, etc.) into Claude Code. It's one of the foundations of the **UFIL** and **Rubyku** plugins in this repository.

> Serena = "Symbolic Editor & Retrieval Engine for Navigating Anything". Open-source, released by [oraios/serena](https://github.com/oraios/serena).

## Why Serena?

Out of the box, Claude Code relies on `Grep`, `Glob`, and `Read` to understand a codebase. That works for small files, but it burns tokens and breaks down quickly on larger, layered projects. Serena plugs in a real **language server** (Solargraph for Ruby, dart-analysis-server for Dart, tsserver for TypeScript, etc.) so Claude can:

- jump to a symbol's definition in a single call instead of multiple greps,
- find **every** caller of a method with LSP accuracy (not regex),
- rename a symbol semantically — safe, and won't touch unrelated strings that happen to match,
- read a file **outline** instead of the entire file body,
- carry project context across sessions via the **memories** system at `.serena/memories/`.

The result: more accurate answers, smaller edits, far fewer tokens.

## Quick start

```bash
# Prerequisite: uv installed
brew install uv          # macOS
# or: curl -LsSf https://astral.sh/uv/install.sh | sh

# Drop .mcp.json at the project root
cat > .mcp.json <<'EOF'
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": [
        "--from", "git+https://github.com/oraios/serena",
        "serena", "start-mcp-server",
        "--context", "claude-code",
        "--project", "."
      ]
    }
  }
}
EOF

# Run Claude Code in that project
claude
```

On the first run Serena will **onboard** — index the project and generate files under `.serena/` (project.yml + memories). After that, all LSP-backed tools are ready to be called by Claude.

## Read next

- [Installation](Installation) — install uv, register `.mcp.json`, verify the MCP connection.
- [Configuration](Configuration) — anatomy of `.serena/project.yml`, options like `read_only`, `excluded_tools`, modes.
- [Tools Reference](Tools-Reference) — the MCP tools Serena exposes to Claude.
- [Usage in Plugins](Usage-in-Plugins) — how UFIL and Rubyku consume Serena (lazy onboarding, auto-approve hook).
- [Troubleshooting](Troubleshooting) — `uvx` missing, onboarding fails, stale index, language server problems.
