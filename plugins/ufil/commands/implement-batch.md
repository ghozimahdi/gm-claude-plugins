---
description: "Implement multiple features in parallel using multiple agents. Auto-scales based on task count."
argument-hint: "<feature1> <feature2> [feature3...]"
allowed-tools:
  ["Read", "Edit", "Write", "Bash", "Glob", "Grep", "Agent", "Skill"]
---

Implement multiple features in parallel using auto-scaled agents.

Arguments: $ARGUMENTS (space-separated feature names or ticket IDs)

## Step -1: Initialize Serena (auto-onboard if needed)

Run in order at session start, BEFORE spawning any agents:

1. Call `mcp__serena__initial_instructions`.
2. Call `mcp__serena__check_onboarding_performed`.
3. **If not onboarded:**
   - Probe for code: `find . -maxdepth 3 -type f -name '*.dart' -not -path '*/.*' | head -1`
   - If a Dart file is found → call `mcp__serena__onboarding` (one-time per project).
   - If empty → SKIP onboarding; tell the user: "Serena onboarding skipped — no Dart code detected. Will auto-run on the next /implement-batch once code exists." Sub-agents will fall back to Glob/Grep/Read.
4. **If already onboarded:** proceed.

Onboarding must happen BEFORE parallel agents spawn — each gm-implementer agent should inherit a ready symbol index, not race to onboard concurrently. To force re-onboarding, run `/serena-refresh`.

## Project Type Detection (MUST DO FIRST)

- **Modular**: `packages/` directory exists → multi-package project with melos
- **Single-module**: No `packages/` directory → single `lib/` project

## Load team config (MUST DO BEFORE PHASE 2)

Run `cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/team-config.json` to load:

- `team.maxParallelAgents` — hard cap on parallel agents (default 3)
- `team.useWorktreeIsolation` — whether to use `isolation: "worktree"` (default true)
- `team.splitStrategy` — how to split work when streams exceed the cap (default `by-layer-then-feature`)

If the file is missing or malformed, fall back to defaults: `maxParallelAgents=3`, `useWorktreeIsolation=true`, `splitStrategy=by-layer-then-feature`.

## Phase 1 — Analyze & Plan (Architect)

Use the **gm-architect** agent to:

1. Parse the list of features/tickets from the arguments
2. For each feature, define: models, DTOs, repos, usecases, blocs, pages
3. Identify **dependencies between features** (shared models, common repos, etc.)
4. Group features into **independent work streams** that can run in parallel

Output a structured plan:

```
Stream 1: [feature_a] — no dependencies
Stream 2: [feature_b] — no dependencies
Stream 3: [feature_c, feature_d] — feature_d depends on feature_c's model
```

## Phase 2 — Auto-Scale Agent Count

Based on the number of **independent work streams** from Phase 1 and `team.maxParallelAgents` (call it `N`) from the config:

| Independent Streams | Agents to Spawn | Strategy                                           |
| ------------------- | --------------- | -------------------------------------------------- |
| 1                   | 1 agent         | Sequential — single implementer                    |
| 2..N                | streams agents  | Parallel — each in worktree isolation (if enabled) |
| > N                 | N agents (max)  | Parallel — batch extra streams across the N agents |

**Rules:**

- Maximum **`team.maxParallelAgents`** parallel agents (default 3) — more causes diminishing returns and merge conflicts
- Features with **dependencies** go into the **same stream** (same agent, sequential)
- Features that are **independent** go into **separate streams** (separate agents, parallel)
- Each parallel agent uses **worktree isolation** when `team.useWorktreeIsolation = true`

## Phase 3 — Parallel Implementation

For each work stream, spawn a **gm-implementer** agent with worktree isolation.

Each agent's prompt MUST include:

1. The detected **project type** (modular or single-module)
2. The **specific features** assigned to that stream
3. The **architect's plan** for those features (file paths, class names, signatures)
4. The **implementation order**: domain → data → presentation
5. Instruction to run code generation and verification after implementation

### Agent Spawn Template

For each stream, use the Agent tool with:

```
Agent({
  description: "Implement <feature_names>",
  subagent_type: "general-purpose",
  isolation: "worktree",
  prompt: "You are implementing Flutter features using Clean Architecture.

Project type: <modular|single-module>

## Features to implement:
<architect's plan for this stream>

## Implementation order:
1. Domain models (@freezed, @Default, no nullable)
2. Repository contracts (abstract class)
3. UseCases (@lazySingleton, plain call())
4. DTOs (@freezed, nullable, @JsonKey on EVERY field, .toModel())
5. Datasources (@lazySingleton, Dio only, NO try/catch)
6. Repository impls (@LazySingleton(as:), with error handler mixin)
7. Bloc events + states (@freezed abstract class, sub-state unions)
8. Bloc (@injectable, part/part of structure)
9. Pages + Widgets (@RoutePage, BlocProvider, ScreenUtil)

## After writing code:
1. Run code generation
2. Run dart fix --apply lib/
3. Run dart format lib/
4. Run dart analyze — fix ALL errors

## Mandatory rules:
- Always Bloc, never Cubit
- @injectable for DI
- No try/catch in datasources
- Freezed everywhere
- @JsonKey on every DTO field
- No arrow (=>) for method bodies
- Sub-state freezed unions, never flat bool flags
- Modular: FailureHandlerMixin, query → Future<Result> (Failure + data), action → Future<Failure>, separate mapper classes
- Single-module: ErrorMapper + Result<T>
"
})
```

**IMPORTANT**: Launch all parallel agents in a **single message** with multiple Agent tool calls so they run concurrently.

## Phase 4 — Merge & Verify

After all agents complete:

1. Review each agent's worktree changes
2. If using worktrees, merge changes back to the working branch
3. Resolve any conflicts (shared files like router, injector)
4. Run full verification:
   - Modular: `melos run build`
   - Single: `fvm dart run build_runner build --delete-conflicting-outputs`
5. Run `fvm dart fix --apply lib/`
6. Run `fvm dart format lib/`
7. Run `fvm dart analyze` — fix ALL errors

## Phase 4.5 — Auto Review (MANDATORY)

After merge & verify pass, invoke the **gm-reviewer** agent (single instance — reviewer audits the merged result, never run in parallel) to audit ALL files created/modified across every stream:

- Architecture violations: page calls UseCase directly (no Bloc), Cubit instead of Bloc, `.toModel()` on DTO, missing separate mapper class, manual `getIt.register*`, `try/catch` in datasource, missing `@JsonKey` on DTO field
- Naming conventions: `{Action}UseCase`, `{Name}DataSource`, `{Name}ModelMapper`, event suffix `Event`, handler camelCase
- Bloc compliance: init event present, sub-state unions with 4 variants, error variant carries `Failure`
- Quality: no `=>` for method bodies, ScreenUtil for sizing, no business logic in pages

**Fix ALL critical and warning issues found.** If an issue is large, re-spawn a gm-implementer agent for that stream's worktree; if small, fix inline.

## Phase 4.6 — Final Verify (MANDATORY after review fixes)

After review fixes, re-run the full verification pass:

1. Modular: `melos run build` — Single: `fvm dart run build_runner build --delete-conflicting-outputs`
2. `fvm dart fix --apply lib/`
3. `fvm dart format lib/`
4. `fvm dart analyze` — fix ALL errors and warnings

Never skip this — review-driven edits frequently re-introduce lint/analyzer issues.

## Phase 5 — Summary

Report to user:

- Number of agents used
- Features implemented per agent
- Any conflicts resolved
- Verification status (analyzer clean or issues remaining)
- Review status (issues found / fixed / remaining)

## Examples

```bash
# 2 independent features → 2 parallel agents
/implement-batch tenant payment

# 3 features → 3 parallel agents
/implement-batch auth tenant notification

# 4 features → 3 agents (batched)
/implement-batch auth tenant payment notification

# Features with dependency → grouped in same agent
/implement-batch order order-history
# → 1 agent (order-history depends on order models)
```

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/ARCHITECTURE.md` — Clean Architecture overview
- `${CLAUDE_PLUGIN_ROOT}/docs/DOMAIN_LAYER.md` — Domain layer patterns
- `${CLAUDE_PLUGIN_ROOT}/docs/DATA_LAYER.md` — Data layer patterns
- `${CLAUDE_PLUGIN_ROOT}/docs/PRESENTATION_LAYER.md` — Presentation layer
- `${CLAUDE_PLUGIN_ROOT}/docs/BLOC_PATTERN.md` — Bloc patterns
