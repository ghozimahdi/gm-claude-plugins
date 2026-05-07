---
description: "Force Serena to re-run project onboarding. Use after major refactors, package moves, or when symbol search returns stale results."
allowed-tools: ["Bash"]
---

Force Serena to re-onboard the current project.

`/plan`, `/implement`, and `/implement-batch` auto-trigger onboarding once per project. This command is the escape hatch when that one-time index has gone stale — for example after:

- a large refactor that renames/moves many symbols
- restructuring packages (modular: adding/removing `packages/*` entries)
- switching project type (single-module ↔ modular)
- pulling a branch with substantial structural changes
- Serena symbol lookups returning outdated or missing results

## Steps

1. Verify the project has Dart code to analyze:

   ```bash
   find . -maxdepth 3 -type f -name '*.dart' -not -path '*/.*' | head -1
   ```

   If empty, abort and tell the user: "No Dart code detected. Scaffold the project first with `/init-project`, then re-run `/serena-refresh`."

2. Call `mcp__serena__initial_instructions` to ensure the instruction manual is loaded for this session.

3. Call `mcp__serena__onboarding` to rebuild the symbol index and project memories.

4. Report to the user:
   - Confirmation that onboarding completed
   - Any notable memories Serena recorded (project type, key entry points, etc.)

## Notes

- Onboarding rebuilds Serena's internal index. It does NOT touch project source files.
- A typical Flutter project re-onboards in well under a minute; large modular projects with many packages may take longer.
- Subsequent `/plan` and `/implement` runs will reuse this refreshed index — no need to re-run unless the codebase shifts again.
