# Helpers

## Display Logic Belongs in Helpers, NOT Models

**All display/presentation logic must be in helpers, NOT in models or concerns.**

Models and concerns handle **business logic** (validations, state transitions, calculations).
Helpers handle **display logic** (formatting, labels, badges, status text, color coding).

```ruby
# BAD — display logic in model
class Task < ApplicationRecord
  def status_badge
    case status
    when "pending" then "badge-warning"
    when "completed" then "badge-success"
    end
  end

  def formatted_due_date
    due_at&.strftime("%Y年%m月%d日")
  end

  def display_name
    "#{title} (#{status})"
  end
end

# GOOD — display logic in helper
# app/helpers/tasks_helper.rb
module TasksHelper
  def task_status_badge(task)
    css_class = case task.status
                when "pending" then "badge-warning"
                when "completed" then "badge-success"
                end
    tag.span(task.status.humanize, class: "badge #{css_class}")
  end

  def formatted_due_date(task)
    task.due_at&.strftime("%Y年%m月%d日")
  end

  def task_display_name(task)
    "#{task.title} (#{task.status})"
  end
end
```

### What Goes Where

| Logic Type | Location | Examples |
|-----------|----------|----------|
| **Business logic** | Model / Concern | Validations, state transitions, calculations, scopes |
| **Display logic** | Helper | Formatting, badges, labels, status text, CSS classes |
| **Data access** | Model / Concern | Queries, associations, callbacks |
| **View presentation** | Helper | Conditional rendering, HTML generation, date/number formatting |

## Helper Types

### 1. Common Helpers
Location: `app/helpers/` (root level)

Available everywhere in the application.

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def format_date(date)
    date&.strftime("%Y/%m/%d")
  end
end
```

### 2. Page-Specific Helpers
Location: `app/helpers/{namespace}/{controller}/`

Scoped to their specific namespace and controller.

```ruby
# app/helpers/t/tasks/intention_helper.rb
module T::Tasks::IntentionHelper
  def intention_status_badge(status)
    # ...
  end
end
```

## Namespace Isolation Rules

**Helpers must not cross namespace boundaries.**

| View Namespace | Can Use | Cannot Use |
|---------------|---------|------------|
| `/t/` views | `app/helpers/` (common) | `app/helpers/c/`, `app/helpers/s/` |
| `/c/` views | `app/helpers/` (common) | `app/helpers/t/`, `app/helpers/s/` |
| `/s/` views | `app/helpers/` (common) | `app/helpers/t/`, `app/helpers/c/` |

```ruby
# Bad — cross-namespace usage
class T::DashboardController
  helper C::OrganizationHelper  # VIOLATION
end

# Good — extract to common helper
# app/helpers/organization_helper.rb
module OrganizationHelper
  def format_org_name(org)
    # shared logic
  end
end
```

## Why This Rule Exists

- Modifying a helper in one namespace could break pages in another
- Each namespace owns its helpers and can modify freely
- Easier to understand dependencies when scoped

## Summary

- Common helpers: can be called from anywhere
- Page-specific helpers: must not be called from other pages
- Namespace isolation: `/t/` cannot use `/c/` helpers and vice versa
- Shared needs: extract to common helpers in `app/helpers/` root
