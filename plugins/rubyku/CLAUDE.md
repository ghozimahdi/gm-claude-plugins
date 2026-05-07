# Rubyku Plugin

A Rails 8 development plugin for Claude Code that enforces the Rails Way: thin controllers, fat models with concerns, Hotwire-first frontend, and Serena LSP for Ruby code intelligence.

## What's Included

- **3 Agents**: Architect, Implementer, Reviewer
- **8 Skills**: rails-way, hotwire, turbo, stimulus, testing, naming-conventions, concerns-pattern, ai-agents
- **13 Commands**: plan, implement, implement-batch, commit, create-pr, check, test, fix-tests, review, ship, generate-migration, github-issue, resolve-conflicts
- **Hooks**: Auto rubocop + guideline validation before git commit
- **MCP Servers**: Serena LSP for Ruby code intelligence
- **.claudeignore**: Template for Rails projects

## Architecture

| Layer | Pattern |
|-------|---------|
| **Controllers** | Thin — HTTP flow only, no business logic |
| **Models** | Fat models with concerns for organization (business logic only) |
| **Helpers** | Display/presentation logic (formatting, badges, labels) |
| **Business Logic** | Concerns (NOT service classes) |
| **Frontend** | Hotwire-first: Turbo Frames → Turbo Streams → Stimulus |
| **Background Jobs** | Solid Queue (database-backed) |
| **AI Agents** | State (DB) → Planner (Agent) → Action (Job/LLM) → Trace (History) |
| **Auth** | Devise |
| **Soft Deletes** | Paranoia gem |
| **Pagination** | Kaminari |
| **Search** | Ransack |

## URL Namespaces

This plugin assumes your Rails app organizes role-based screens under per-role URL namespaces, each backed by its own `ApplicationController`. Example:

| Role | Prefix | Controller Base |
|------|--------|----------------|
| User-facing auth | `/users` | `Users::ApplicationController` |
| Admin | `/admin` | `Admin::ApplicationController` |
| API | `/api` | `Api::ApplicationController` |

Customize namespaces to match your app — the plugin's rules ("new screen = new controller", "RESTful resources only") are namespace-agnostic.

## Serena LSP — ALWAYS USE

**Before starting any coding task**, initialize Serena:
1. Call `mcp__serena__initial_instructions` to load Serena manual
2. Call `mcp__serena__activate_project` to activate the project

**ALWAYS prefer Serena tools over Grep/Glob/Read for code navigation:**

| Task | Use Serena | NOT |
|------|-----------|-----|
| Find class/method | `find_symbol` | Grep |
| Go to definition | `find_declaration` | Read + search |
| Find callers | `find_referencing_symbols` | Grep |
| File structure | `get_symbols_overview` | Read entire file |
| Check errors | `get_diagnostics_for_file` | rubocop |
| Safe rename | `rename_symbol` | Find & replace |
| Edit method | `replace_symbol_body` | Manual edit |

## Standards

- **Rails Way** — Convention over Configuration, DRY, thin controllers
- **No service classes** — use concerns instead (`app/models/model_name/concern.rb`)
- **Display logic in helpers** — NOT in models/concerns (e.g., formatting, badges, status labels → helper)
- **Hotwire-first** — no jQuery, no vanilla JS, no fetch for server communication
- **Turbo Frames → Turbo Streams → Stimulus** priority order
- **Query through parent associations** — `@user.posts.find(id)` not `Post.where(user_id: @user.id).find(id)`
- **Rails credentials** — never use `ENV` directly
- **Sentry for errors** — do NOT rescue errors with custom handling
- **RuboCop compliance** — zero tolerance before PR
- **All code comments in English**
- **ActiveStorage** for all file uploads
- **Paranoia** for soft deletes
- **Kaminari** for pagination
- **Minitest** for testing (not RSpec)

## Naming Conventions

- **Booleans**: positive words, no `is_`/`has_` prefix (e.g., `active`, not `is_active`)
- **Timestamps**: `*_at` for datetime, `*_on` for date
- **Models**: singular CamelCase, tables plural snake_case
- **Controllers**: plural, end with `Controller`
- **Jobs**: end with `Job`
- **Mailers**: end with `Mailer`
- **Branches**: `issues/<issue_id>`
- **Commits**: `[#issue_id] Message`

## Git Workflow

- **Branch**: `issues/<issue_id>` (e.g., `issues/42`)
- **Commit**: `[#issue_id] Commit message` (e.g., `[#100] Fix bugs`)
- **No issue**: Use `[fix]` tag
- **PR target**: `main` (sub-issues PR to parent branch)

## Usage

```bash
# Plan first, then implement
/plan 123
/implement 123

# Or implement directly (auto-plans if no plan exists)
/implement 123

# Run checks before committing
/check

# Run tests
/test
/test test/models/user_test.rb

# Fix failing tests automatically
/fix-tests test/models/user_test.rb

# Commit with proper format
/commit

# Ship: test → review → commit → PR
/ship

# Create PR
/create-pr

# Review code for guideline violations
/review app/controllers/admin/

# Generate migration
/generate-migration add_email_verified_to_users

# Create GitHub issue
/github-issue "Fix login timeout"

# Resolve merge conflicts
/resolve-conflicts
```
