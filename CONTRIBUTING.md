# Contributing

Thanks for your interest in improving **GM AI Agent Plugins**! Contributions are welcome via **fork + pull request** workflow.

## Getting Started

1. **Fork** this repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/gm-aiagent-plugins.git
   cd gm-aiagent-plugins
   ```
3. Create a **feature branch** from `main` using the `<type>/<plugin>/<description>` format (see [Branch Naming](#branch-naming)):
   ```bash
   git checkout -b feat/ufil/your-feature-name
   ```
4. Make your changes
5. **Push** to your fork:
   ```bash
   git push origin feat/ufil/your-feature-name
   ```
6. Open a **Pull Request** against this repository's `main` branch

> **Important**: Do NOT push directly to this repository. All changes must go through fork + PR.

## Keeping Your Fork in Sync

Because contributions go through forks, your fork will drift from this repo as new PRs are merged. Sync it before starting a new branch (and before opening a PR) so your changes apply cleanly.

1. **Add the upstream remote** (one time, right after cloning):
   ```bash
   git remote add upstream https://github.com/ghozimahdi/gm-claude-plugins.git
   git remote -v   # verify: origin = your fork, upstream = this repo
   ```

2. **Sync `main` with upstream** before creating a new feature branch:
   ```bash
   git checkout main
   git fetch upstream
   git rebase upstream/main
   git push origin main
   ```

3. **Rebase your feature branch onto the latest `main`** before opening or updating a PR:
   ```bash
   git checkout feat/ufil/your-feature-name
   git fetch upstream
   git rebase upstream/main
   git push --force-with-lease origin feat/ufil/your-feature-name
   ```

> Use `--force-with-lease` (not `--force`) when re-pushing a rebased branch — it refuses to overwrite work you haven't seen yet. Only force-push branches on your fork, never `main`.

## What You Can Contribute

- New **plugins** (`plugins/<plugin-name>/`)
- New or improved **skills** (`plugins/<plugin>/skills/`)
- New or improved **commands** (`plugins/<plugin>/commands/`)
- New or improved **agents** (`plugins/<plugin>/agents/`)
- Documentation improvements (`plugins/<plugin>/docs/`, `README.md`)
- Bug fixes in **scripts** (`plugins/<plugin>/scripts/`)
- Hook improvements (`plugins/<plugin>/hooks/`)

## Repository Structure

```
gm-aiagent-plugins/
├── .claude-plugin/
│   └── marketplace.json        # Marketplace listing (all plugins)
├── plugins/
│   ├── ufil/                   # UFIL — Flutter Clean Architecture plugin
│   ├── rubyku/                 # Rubyku — Rails 8 plugin
│   └── <your-plugin>/          # Each plugin follows the same layout:
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── CLAUDE.md
│       ├── README.md
│       ├── agents/
│       ├── commands/
│       ├── skills/
│       ├── docs/
│       ├── hooks/
│       └── scripts/
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Adding a New Plugin

1. Create a new directory under `plugins/`:
   ```
   plugins/your-plugin-name/
   ├── .claude-plugin/
   │   └── plugin.json
   ├── CLAUDE.md
   ├── README.md
   └── ...
   ```
2. Register it in `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "your-plugin-name",
     "source": "./plugins/your-plugin-name",
     "description": "Your plugin description",
     "version": "1.0.0"
   }
   ```
3. Add a row for your plugin in the **Available Plugins** table of the root [`README.md`](README.md).

## Guidelines

### Branch Naming

Use descriptive branch names with a `<type>/<plugin>/<description>` format. Include the plugin name so the scope is clear in a multi-plugin repo. For repo-wide changes (root README, CONTRIBUTING, marketplace.json), omit the plugin segment.

```
feat/ufil/add-riverpod-skill
fix/ufil/generate-module-path-issue
docs/rubyku/clarify-hotwire-guide
refactor/rubyku/simplify-commit-command
docs/update-root-readme
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/). Use the plugin name as the scope:

```
feat(ufil): add riverpod skill for non-bloc projects
fix(rubyku): correct controller path in generate-migration
docs(ufil): clarify DTO naming convention in DATA_LAYER.md
chore: update root README with new plugin
```

### Pull Request

- Keep PRs focused on a single concern
- Provide a clear description of what changed and why
- Reference any related issues
- Make sure all Markdown files are well-formatted

### Code Style for Markdown Files

- Use fenced code blocks with language identifiers (` ```dart `, ` ```bash `)
- Skill files (`SKILL.md`) must include frontmatter with `name`, `description`, and `disable-model-invocation`
- Command files must include frontmatter with `description`, `argument-hint`, and `allowed-tools`
- Agent files must include frontmatter with `name`, `description`, `model`, and `maxTurns`
- Repository workflows shared with Codex live under `.agents/skills/<name>/SKILL.md`.
  A matching `.claude/commands/<name>.md` may remain as a thin Claude wrapper.

### Testing Your Changes

1. Install the plugin locally in Claude Code:
   ```bash
   /plugin marketplace add /path/to/your-fork
   /plugin install <plugin-name>@gm-aiagent-plugins
   /reload-plugins
   ```
   Example: `/plugin install ufil@gm-aiagent-plugins` or `/plugin install rubyku@gm-aiagent-plugins`.
2. Install it locally in Codex:
   ```bash
   codex plugin marketplace add /path/to/your-fork
   codex plugin add <plugin-name>@gm-aiagent-plugins
   ```
3. Test in a real project for the target platform to verify skills, commands, hooks, and agents work correctly.
4. If you touched plugin-specific scripts (e.g. `ufil/scripts/generate-module.sh`), test every mode the script supports (e.g. `--modular` and `--single`).

### Repository release workflow

- Claude Code: `/release <plugin> [version]`
- Codex: `$release <plugin> [version]`

Both entry points use `.agents/skills/release/SKILL.md` as the authoritative
workflow.

## Contact

For collaboration inquiries or questions, reach out via email: **ghozi.dev@gmail.com**

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
