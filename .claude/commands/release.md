---
description: "Cut a new release for a plugin: bump version, tag, push, and create GitHub release with auto-generated notes."
argument-hint: "<plugin-name> [version e.g. 1.0.1 or major|minor|patch — leave empty to auto-bump patch]"
allowed-tools: ["Bash", "Read", "Edit", "Glob"]
model: sonnet
---

Read `.agents/skills/release/SKILL.md` completely and follow it as the
authoritative release workflow.

Use these command arguments as the skill input:

```text
$ARGUMENTS
```

Do not execute a release workflow from any other copy of the instructions.
