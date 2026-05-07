---
description: "Cut a new release for a plugin: bump version, tag, push, and create GitHub release with auto-generated notes."
argument-hint: "<plugin-name> [version e.g. 1.0.1 or major|minor|patch — leave empty to auto-bump patch]"
allowed-tools: ["Bash", "Read", "Edit", "Glob"]
model: sonnet
---

Cut a new release for a plugin in the **gm-claude-plugins** marketplace.

Arguments: $ARGUMENTS

Parse arguments:
- First argument = plugin name (required, e.g. `ufil`)
- Second argument (optional) = explicit version like `1.2.0`, or bump keyword `major`/`minor`/`patch`, or empty for auto-patch bump

If no plugin name is provided, **abort** and list available plugins from `.claude-plugin/marketplace.json`.

## What this command does

1. Validates the plugin exists and working tree is clean on `main`
2. Determines next version (from argument or auto-bump patch)
3. Updates `version` field in `plugins/<plugin>/.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` (matching entry)
4. Commits the version bump
5. Creates an annotated git tag `<plugin>-vX.Y.Z`
6. Pushes commit + tag to `origin`
7. Generates release notes from commits since previous tag (grouped by Conventional Commits type)
8. Creates a GitHub release via `gh release create`

## Steps

### 1. Pre-flight checks

Run in parallel:
- `git status --porcelain` — must be empty (no uncommitted changes)
- `git branch --show-current` — must be `main`
- `git fetch --tags origin` — sync remote tags
- `git remote get-url origin` — verify remote exists

Validate the plugin exists:
- Check `plugins/<plugin>/.claude-plugin/plugin.json` exists
- Check the plugin is listed in `.claude-plugin/marketplace.json`

If working tree is dirty, branch is not `main`, or plugin doesn't exist, **abort** and tell the user.

### 2. Determine next version

Read current version from `plugins/<plugin>/.claude-plugin/plugin.json` (the `version` field).

- If version argument is empty -> bump patch (e.g., `1.0.0` -> `1.0.1`)
- If version argument is `major` -> bump major (e.g., `1.0.0` -> `2.0.0`)
- If version argument is `minor` -> bump minor (e.g., `1.0.0` -> `1.1.0`)
- If version argument is `patch` -> bump patch
- If version argument matches `^\d+\.\d+\.\d+$` -> use that exact version
- Otherwise -> abort with usage hint

Show the user: "Bumping `<plugin>` `1.0.0` -> `1.0.1`" before continuing.

### 3. Update manifest files

Use the **Edit** tool (not sed) to update the `"version"` field in:
- `plugins/<plugin>/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json` (find the matching plugin entry by name)

### 4. Commit the version bump

```bash
git add plugins/<plugin>/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore(<plugin>): release v<NEW_VERSION>"
```

### 5. Generate release notes

Get the previous tag for this plugin:

```bash
PREV_TAG=$(git tag -l "<plugin>-v*" --sort=-v:refname | head -1)
```

If `PREV_TAG` is empty (first release), use all commits that touch `plugins/<plugin>/`. Otherwise use commits since `PREV_TAG` that touch `plugins/<plugin>/`.

```bash
# Get commits as <type>|<subject>
git log ${PREV_TAG:+$PREV_TAG..}HEAD --pretty=format:"%s" --no-merges -- "plugins/<plugin>/"
```

Group commits by Conventional Commits type into these sections (skip empty sections):

- **Features** -> `feat`
- **Bug Fixes** -> `fix`
- **Performance** -> `perf`
- **Refactor** -> `refactor`
- **Documentation** -> `docs`
- **Tests** -> `test`
- **Build & CI** -> `build`, `ci`
- **Chores** -> `chore`, `style`
- **Other** -> anything that doesn't match

Format:

```markdown
## What's Changed

### Features
- add tenant list page with pagination (PROP-123)
- add payment checkout flow (PROP-145)

### Bug Fixes
- handle null amount in checkout DTO (PROP-456)

**Full Changelog**: https://github.com/<owner>/<repo>/compare/<PREV_TAG>...<plugin>-v<NEW_VERSION>
```

If first release, replace the changelog line with: `**Initial release**`.

Strip the `<type>(<scope>):` prefix from subject lines but **keep** the ticket ID in parentheses at the end if present.

Example:
- Input: `feat(ufil): add tenant list page`
- Output: `- add tenant list page`

### 6. Tag and push

```bash
git tag -a <plugin>-v<NEW_VERSION> -m "Release <plugin> v<NEW_VERSION>"
git push origin main
git push origin <plugin>-v<NEW_VERSION>
```

### 7. Create GitHub release

```bash
gh release create <plugin>-v<NEW_VERSION> \
  --title "<plugin> v<NEW_VERSION>" \
  --notes "<generated notes from step 5>"
```

If `gh` is not authenticated or no GitHub remote, abort step 7 and tell the user to:
1. Run `gh auth login`
2. Or push the tag manually and create release on github.com

### 8. Final summary

Print to user:
- Plugin: `<plugin>`
- New version: `v<NEW_VERSION>`
- Git tag pushed: `<plugin>-v<NEW_VERSION>`
- GitHub release URL (from `gh release view <plugin>-v<NEW_VERSION> --json url -q .url`)
- Install command for users:
  ```
  /plugin marketplace add ghozimahdi/gm-claude-plugins
  /plugin install <plugin>@gm-claude-plugins
  ```

## Safety rules

- **Never** force-push
- **Never** delete tags
- **Never** rewrite history on `main`
- If any step fails, stop and report the failure — do not try to "clean up" with destructive commands
- If a tag with the target version already exists, abort and ask the user (do not overwrite)
