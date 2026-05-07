# Style & Conventions

## Repository conventions
- Use fenced code blocks with language identifiers in all Markdown
- Each plugin is self-contained under `plugins/<name>/`
- Repo-level commands go in `.claude/commands/`, NOT inside any plugin

## Branch & commit conventions
- Branches: `feat/...`, `fix/...`, `docs/...`, `refactor/...`
- Commits: [Conventional Commits](https://www.conventionalcommits.org/) with plugin scope: `feat(ufil): ...`, `fix(ufil): ...`
- For repo-level changes: `chore: ...`, `docs: ...` without scope
- PRs: focused on a single concern, clear description, reference related issues
- **NEVER** push directly to `main`. Use **fork + PR**.

## Release convention
- Tags are namespaced per plugin: `ufil-v1.0.1`, `<plugin>-v<version>`
- Use `/release <plugin> [version]` command

## Plugin file conventions
- **Skill files** (`skills/<name>/SKILL.md`): frontmatter with `name`, `description`, `disable-model-invocation`
- **Command files** (`commands/<name>.md`): frontmatter with `description`, `argument-hint`, `allowed-tools`
- **Agent files** (`agents/<name>.md`): frontmatter with `name`, `description`, `model`, `maxTurns`
