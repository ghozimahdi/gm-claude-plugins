---
description: "Implement multiple features in parallel using multiple agents. Auto-scales based on task count."
argument-hint: "<issue1> <issue2> [issue3...]"
allowed-tools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep", "Agent", "Skill"]
---

Implement multiple features in parallel using auto-scaled agents.

Arguments: $ARGUMENTS (space-separated issue IDs or feature names)

## Phase 1 — Analyze & Plan (Architect)

Use the **rubyku-architect** agent to:
1. Parse the list of features/issues from the arguments
2. For each feature, define: models, concerns, controllers, routes, views, jobs
3. Identify **dependencies between features** (shared models, routes, etc.)
4. Group features into **independent work streams** that can run in parallel

Output a structured plan:
```
Stream 1: [feature_a] — no dependencies
Stream 2: [feature_b] — no dependencies
Stream 3: [feature_c, feature_d] — feature_d depends on feature_c's model
```

## Phase 2 — Auto-Scale Agent Count

| Independent Streams | Agents | Strategy |
|---------------------|--------|----------|
| 1 | 1 agent | Sequential |
| 2 | 2 agents | Parallel with worktree isolation |
| 3+ | 3 agents (max) | Parallel, batched across 3 agents |

Rules:
- Maximum **3 parallel agents**
- Features with dependencies → same stream (sequential)
- Independent features → separate streams (parallel)
- Each parallel agent MUST use **worktree isolation**

## Phase 3 — Parallel Implementation

For each work stream, spawn a **rubyku-implementer** agent with worktree isolation.

Each agent's prompt MUST include:
1. The **features assigned** to that stream
2. The **architect's plan** (models, routes, controllers, views)
3. The **implementation order**: migration → model → routes → controller → views → tests
4. Instruction to follow all Rails Way standards

Launch all parallel agents in a **single message** with multiple Agent tool calls.

## Phase 4 — Merge & Review

After all agents complete:
1. Review each agent's worktree changes
2. Merge changes back to the working branch
3. Resolve conflicts (shared files like routes, migrations)
4. Run `bin/rails db:migrate`
5. Use the **rubyku-reviewer** agent to audit all modified files:
   - Architecture violations (thin controllers, no service classes, no display logic in models)
   - Naming conventions, frontend compliance, code quality
   - **Fix ALL critical and warning issues found**
6. Run `bundle exec rubocop` — fix all offenses
7. Run `bin/rails test` — all tests pass

## Phase 5 — Summary

Report:
- Number of agents used
- Features implemented per agent
- Conflicts resolved
- Test status

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/ARCHITECTURE.md`
- `${CLAUDE_PLUGIN_ROOT}/docs/NAMING_CONVENTIONS.md`
- `${CLAUDE_PLUGIN_ROOT}/docs/CODE_OF_CONDUCT.md`
