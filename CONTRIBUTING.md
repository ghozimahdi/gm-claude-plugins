# Contributing

Thanks for your interest in improving **GM Claude Plugins**! Contributions are welcome via **fork + pull request** workflow.

## Getting Started

1. **Fork** this repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/gm-claude-plugins.git
   cd gm-claude-plugins
   ```
3. Create a **feature branch** from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```
4. Make your changes
5. **Push** to your fork:
   ```bash
   git push origin feat/your-feature-name
   ```
6. Open a **Pull Request** against this repository's `main` branch

> **Important**: Do NOT push directly to this repository. All changes must go through fork + PR.

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
gm-claude-plugins/
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

Use descriptive branch names with a prefix:

```
feat/add-riverpod-skill
fix/generate-module-path-issue
docs/update-architecture-guide
refactor/simplify-commit-command
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

### Testing Your Changes

1. Install the plugin locally:
   ```bash
   /plugin marketplace add /path/to/your-fork
   /plugin install <plugin-name>@gm-claude-plugins
   /reload-plugins
   ```
   Example: `/plugin install ufil@gm-claude-plugins` or `/plugin install rubyku@gm-claude-plugins`.
2. Test in a real project for the target platform to verify skills, commands, and agents work correctly.
3. If you touched plugin-specific scripts (e.g. `ufil/scripts/generate-module.sh`), test every mode the script supports (e.g. `--modular` and `--single`).

## Contact

For collaboration inquiries or questions, reach out via email: **ghozi.dev@gmail.com**

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
