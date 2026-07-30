---
name: release
description: "Cut and publish a release for a plugin in gm-aiagent-plugins. Use only when the user explicitly asks to bump a plugin version, tag it, push it, and create a GitHub release."
---

# Release a plugin

Use this workflow only after an explicit release request.

- Claude Code invocation: `/release <plugin-name> [version|major|minor|patch]`
- Codex invocation: `$release <plugin-name> [version|major|minor|patch]`

Read the plugin name and optional version from the current request:

- First argument: plugin name, required, for example `ufil`.
- Second argument: exact `X.Y.Z`, `major`, `minor`, or `patch`.
- When the second argument is omitted, bump the patch version.
- If the plugin name is missing, stop and list available plugins from
  `.claude-plugin/marketplace.json`.

## Outcome

1. Validate the plugin and repository release state.
2. Determine the next version.
3. Keep Claude and Codex plugin manifests synchronized.
4. Commit the version bump.
5. Create and push an annotated tag.
6. Generate release notes.
7. Create the GitHub release.

## 1. Pre-flight checks

Run these independent checks in parallel when the client supports it:

```bash
git status --porcelain
git branch --show-current
git fetch --tags origin
git remote get-url origin
```

Require all of the following:

- Working tree is clean.
- Current branch is `main`.
- `plugins/<plugin>/.claude-plugin/plugin.json` exists.
- The plugin appears in `.claude-plugin/marketplace.json`.
- The remote repository is `ghozimahdi/gm-aiagent-plugins`.

If the plugin also has `plugins/<plugin>/.codex-plugin/plugin.json`, require its
base semantic version to match the Claude manifest before continuing. Ignore a
Codex build-metadata cachebuster such as `+codex.local-*` for this comparison.

Stop and report the exact mismatch when any pre-flight check fails. Do not
silently repair unrelated dirty files, branches, remotes, tags, or manifests.

## 2. Determine the next version

Read the current version from
`plugins/<plugin>/.claude-plugin/plugin.json`.

- No version argument or `patch`: increment patch.
- `minor`: increment minor and reset patch to zero.
- `major`: increment major and reset minor and patch to zero.
- An argument matching `^\d+\.\d+\.\d+$`: use it exactly.
- Anything else: stop with the invocation examples above.

The new version must be greater than the current version. Before editing, tell
the user:

```text
Bumping <plugin> <CURRENT_VERSION> -> <NEW_VERSION>
```

Abort if the tag `<plugin>-v<NEW_VERSION>` already exists locally or remotely.

## 3. Synchronize manifest versions

Update the version in:

1. `plugins/<plugin>/.claude-plugin/plugin.json`
2. The matching plugin entry in `.claude-plugin/marketplace.json`
3. `plugins/<plugin>/.codex-plugin/plugin.json`, when that file exists

Write the plain release version to all three locations. Do not retain a local
Codex cachebuster in a published release manifest.

Validate every edited JSON file. Then run:

```bash
claude plugin validate plugins/<plugin>
```

When a Codex manifest exists, also use the installed Codex/plugin validator.
If it is unavailable, validate the Codex manifest and every bundled
`SKILL.md` with the available JSON and skill validators. Do not skip validation
silently.

## 4. Commit the version bump

Stage only the manifest files changed in step 3:

```bash
git add plugins/<plugin>/.claude-plugin/plugin.json .claude-plugin/marketplace.json
```

If the Codex manifest exists, also stage:

```bash
git add plugins/<plugin>/.codex-plugin/plugin.json
```

Commit:

```bash
git commit -m "chore(<plugin>): release v<NEW_VERSION>"
```

## 5. Generate release notes

Find the latest tag for this plugin:

```bash
git tag -l "<plugin>-v*" --sort=-v:refname
```

Use the first result as `PREV_TAG`. If no previous tag exists, collect every
non-merge commit touching `plugins/<plugin>/`. Otherwise collect non-merge
commits after `PREV_TAG` that touch that directory.

Group Conventional Commit subjects into non-empty sections:

- Features: `feat`
- Bug Fixes: `fix`
- Performance: `perf`
- Refactor: `refactor`
- Documentation: `docs`
- Tests: `test`
- Build & CI: `build`, `ci`
- Chores: `chore`, `style`
- Other: unmatched subjects

Strip the `type(scope):` prefix, but retain ticket identifiers. End non-initial
release notes with:

```text
**Full Changelog**: https://github.com/ghozimahdi/gm-aiagent-plugins/compare/<PREV_TAG>...<plugin>-v<NEW_VERSION>
```

For the first release, use `**Initial release**`.

## 6. Tag and push

```bash
git tag -a <plugin>-v<NEW_VERSION> -m "Release <plugin> v<NEW_VERSION>"
git push origin main
git push origin <plugin>-v<NEW_VERSION>
```

Never force-push, overwrite a tag, delete a tag, or rewrite `main`.

## 7. Create the GitHub release

```bash
gh release create <plugin>-v<NEW_VERSION> \
  --title "<plugin> v<NEW_VERSION>" \
  --notes "<generated notes>"
```

If GitHub CLI authentication is missing, stop this step and report the exact
failure. Tell the user to run `gh auth login` or create the release manually.

## 8. Report

Return:

- Plugin name and new version.
- Commit and tag.
- Whether both pushes succeeded.
- GitHub release URL.
- Any validation warnings.
- Updated installation commands:

```text
Claude Code:
/plugin marketplace add ghozimahdi/gm-aiagent-plugins
/plugin install <plugin>@gm-aiagent-plugins

Codex:
codex plugin marketplace add ghozimahdi/gm-aiagent-plugins
codex plugin add <plugin>@gm-aiagent-plugins
```

If any operation fails, stop at that step and report it. Do not perform
destructive cleanup or claim later steps succeeded.
