# Project Purpose

**gm-claude-plugins** is a multi-plugin marketplace repository for Claude Code plugins by Ghozi Mahdi.

It is NOT a Flutter app — it is a collection of Claude Code plugin definitions (Markdown, Bash scripts, JSON configs) distributed via Claude Code's plugin marketplace system.

## Current Plugins

| Plugin | Platform | Description |
|--------|----------|-------------|
| **ufil** | Flutter/Dart | UFIL (Ultimate Flutter Intelligent Layer) — Clean Architecture + Modularization with Dart MCP & LSP integration |

## Planned Plugins (coming soon)
- React Native
- Kotlin
- Express
- Ruby

## Structure
- Root marketplace: `.claude-plugin/marketplace.json` — lists all available plugins
- Each plugin lives in `plugins/<name>/` with its own `.claude-plugin/plugin.json`, `CLAUDE.md`, agents, commands, skills, docs, hooks, scripts
- Root `.claude/commands/` — repo-level commands (e.g. `/release <plugin> [version]`)
- Root `.serena/` — Serena LSP config for the repo

## Repository
- URL: https://github.com/ghozimahdi/gm-claude-plugins
- License: MIT
- Author: Ghozi Mahdi (ghozi.dev@gmail.com)
