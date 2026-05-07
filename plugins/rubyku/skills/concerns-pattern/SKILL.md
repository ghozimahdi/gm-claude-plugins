---
name: concerns-pattern
description: "Concerns pattern for organizing business logic in models — the alternative to service classes  following Rails Way standards"
disable-model-invocation: true
---

## Concerns Pattern

### Why Concerns (Not Service Classes)

This plugin enforces **concerns** to organize business logic, NEVER service classes.

### Organization

| Type | Location | Module Name |
|------|----------|-------------|
| Model-specific | `app/models/model_name/concern.rb` | `ModelName::ConcernName` |
| Shared across models | `app/models/concerns/concern.rb` | `ConcernName` |
| Controller | `app/controllers/concerns/concern.rb` | `ConcernName` |

### Model-Specific Concern

```ruby
# app/models/task/status_transitions.rb
module Task::StatusTransitions
  extend ActiveSupport::Concern

  included do
    after_commit :notify_status_change, if: :saved_change_to_status?

    scope :actionable, -> { where(status: [:pending, :in_progress]) }
  end

  def advance!
    case status
    when "pending" then update!(status: :in_progress)
    when "in_progress" then update!(status: :completed)
    end
  end

  def revert!
    update!(status: :pending)
  end

  private

  def notify_status_change
    TaskMailer.status_changed(self).deliver_later
  end
end
```

### Including in Model

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  include Task::StatusTransitions
  include Task::Notifications
  include Task::Validations
  include AttributeLabels

  acts_as_paranoid

  belongs_to :user
  has_many :ai_scheduled_events, as: :eventable
end
```

### Shared Concern

```ruby
# app/models/concerns/attribute_labels.rb
module AttributeLabels
  extend ActiveSupport::Concern

  class_methods do
    def define_label_methods
      column_names.each do |column|
        define_method("#{column}_label") do
          self.class.human_attribute_name(column)
        end
      end
    end
  end

  included do
    define_label_methods
  end
end
```

### Controller Concern

```ruby
# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def current_organization
    current_user.organizations.first
  end
end
```

### When to Create a Concern

- Model has multiple responsibilities → split into focused concerns
- Same behavior needed across multiple models → shared concern
- Controller logic is reused across namespaces → controller concern
- **NOT for display logic** — formatting, badges, labels → use helpers instead

### Concern Checklist

1. Single responsibility — one concern = one cohesive behavior
2. Proper namespace — model-specific vs shared
3. `extend ActiveSupport::Concern`
4. Use `included` block for callbacks, scopes, associations
5. Use `class_methods` block for class-level methods
6. Keep it focused — if it's growing large, split further

### Anti-Patterns

```ruby
# BAD — display logic in concern (belongs in helper)
module Task::Display
  extend ActiveSupport::Concern

  def status_badge
    case status
    when "pending" then "badge-warning"
    when "completed" then "badge-success"
    end
  end

  def formatted_due_date
    due_at&.strftime("%Y年%m月%d日")
  end
end
# GOOD — move to app/helpers/tasks_helper.rb

# BAD — service class
class TaskService
  def initialize(task)
    @task = task
  end

  def process
    @task.update!(status: :in_progress)
    send_notification(@task)
  end
end

# BAD — god concern (too many responsibilities)
module Task::Everything
  # validations, notifications, transitions, exports, imports...
end

# GOOD — focused concerns
module Task::StatusTransitions  # just status logic
module Task::Notifications      # just notification logic
module Task::Exports            # just export logic
```
