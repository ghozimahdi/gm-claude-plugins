# Architecture Guide

## Overview

This plugin assumes a Rails 8 application with:
- Multi-database setup (primary, queue, cable, cache)
- Solid Queue for background jobs
- Hotwire (Turbo + Stimulus) frontend
- AI Agent workflow automation
- Multi-tenant, multi-role user system

## Application Layers

### Controllers (Thin)
- HTTP flow only: receive request, call model/concern, render response
- No business logic
- Always use strong parameters
- Query through parent associations

```ruby
# Good
def show
  @post = @user.posts.find(params[:id])
end

# Bad — never query directly
def show
  @post = Post.where(user_id: @user.id).find(params[:id])
end
```

### Models (Fat with Concerns)
- Business logic lives here
- Organized via concerns for separation
- Model-specific concerns: `app/models/model_name/concern_name.rb`
- Shared concerns: `app/models/concerns/concern_name.rb`
- All models include `AttributeLabels` for I18n translation methods

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  include Task::StatusTransitions
  include Task::Notifications
  include AttributeLabels
end

# app/models/task/status_transitions.rb
module Task::StatusTransitions
  extend ActiveSupport::Concern
  # business logic here
end
```

### No Service Classes
Use concerns instead. Never create `app/services/`.

### Frontend (Hotwire-first)
Priority order:
1. **Turbo Frames** — partial page updates
2. **Turbo Streams** — multi-element updates or real-time
3. **Stimulus** — client-only UI behavior

Rules:
- No fetch calls for server communication
- No pushState/replaceState — Turbo handles URLs
- No jQuery or vanilla JS without team approval
- Consult team before >100 line Stimulus controllers

### Background Jobs (Solid Queue)
- Database-backed job queue (no Redis)
- Jobs stored in separate `queue` database
- Worker via `bin/jobs`
- Recurring jobs in `config/recurring.yml`
- Monitor at `/jobs` (Mission Control)

### AI Agents
Architecture: **State (DB)** → **Planner (Agent)** → **Action (Job/Logic/LLM)** → **Trace (History)**

- `app/agents/` — Agent classes with single `run` method
- `app/agents/tools/` — Reusable agent tools
- RubyLLM for intelligent reasoning when needed

## Multi-Database Setup

| Database | Purpose | Migrations |
|----------|---------|------------|
| `primary` | Main app data | `db/migrate/` |
| `queue` | Solid Queue jobs | `db/queue_migrate/` |
| `cable` | Action Cable | `db/cable_migrate/` |
| `cache` | Solid Cache (prod) | `db/cache_migrate/` |

## URL Namespace Structure

If the host app organizes screens by role, give each role its own namespace, `ApplicationController`, and route prefix. Common examples:

| Role | Prefix | Controller Base |
|------|--------|----------------|
| User-facing | `/users` | `Users::ApplicationController` |
| Admin | `/admin` | `Admin::ApplicationController` |
| API | `/api` | `Api::ApplicationController` |

Custom role prefixes (e.g. `/s`, `/c`, `/t`) are fine — just keep them consistent with the rest of `config/routes.rb`.

## Key Gems

| Gem | Purpose |
|-----|---------|
| `devise` | Authentication (4 user types) |
| `paranoia` | Soft deletes |
| `kaminari` | Pagination |
| `ransack` | Search |
| `simple_form` | Form building |
| `ruby_llm` | AI/LLM integration |
| `solid_queue` | Background jobs |
| `turbo-rails` | SPA-like navigation |
| `stimulus-rails` | JS framework |
| `tailwindcss-rails` | CSS |
| `grover` | PDF generation |
| `active_storage_validations` | File validation |

## Error Handling

- **Do NOT rescue errors** — let Sentry catch them
- Exception: rescue expected errors with clear comments
- Never broad rescue `StandardError` or `Exception`
- Use `Sentry.set_context()` for debugging context without suppressing

## File Storage

- Always use ActiveStorage
- No platform-specific logic
- Azure Blob Storage in production

## Credentials

- Never use `ENV` directly
- Always use `Rails.application.credentials.dig(:section, :key)`
