---
name: rails-way
description: "Rails Way patterns — thin controllers, fat models with concerns, no service classes, conventions over configuration"
disable-model-invocation: true
---

## Rails Way Patterns

### Core Principles
- **Convention over Configuration** — follow Rails conventions
- **DRY** — don't repeat yourself
- **Thin controllers, fat models** — business logic in models/concerns

### Controller Rules
- HTTP flow only: receive request, call model, render response
- No business logic, no conditionals, no calculations
- Always use strong parameters
- Query through parent associations

```ruby
# Good — thin controller
class Admin::UsersController < Admin::ApplicationController
  def create
    @user = current_admin.users.build(user_params)
    if @user.save
      redirect_to [:admin, @user], notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
```

### Model Rules
- Validations for data integrity
- Callbacks for lifecycle events
- Scopes for chainable queries
- **Business logic only** — display/presentation logic belongs in helpers
- `class << self` for class methods (NOT `def self.`)
- Enum predicate methods: `task.pending?` (NOT `task.status == "pending"`)
- Enum scopes: `Task.status_pending` (NOT `Task.where(status: :pending)`)

```ruby
class Task < ApplicationRecord
  include Task::StatusTransitions
  include AttributeLabels

  acts_as_paranoid

  belongs_to :user
  validates :title, presence: true
  enum :status, { pending: 0, in_progress: 1, completed: 2 }

  scope :due_soon, -> { where(due_at: ..3.days.from_now) }

  class << self
    def find_by_code(code)
      find_by(code: code)
    end
  end
end
```

### Display Logic → Helpers (NOT Models)
```ruby
# BAD — display logic in model
class User < ApplicationRecord
  def full_name_with_role
    "#{name} (#{role.humanize})"
  end

  def status_color
    active? ? "green" : "red"
  end
end

# GOOD — display logic in helper
module UsersHelper
  def user_full_name_with_role(user)
    "#{user.name} (#{user.role.humanize})"
  end

  def user_status_color(user)
    user.active? ? "green" : "red"
  end
end
```

### No Service Classes
```ruby
# BAD — service class
class TaskService
  def advance(task); end
end

# GOOD — model concern
module Task::StatusTransitions
  extend ActiveSupport::Concern

  def advance!
    case status
    when "pending" then update!(status: :in_progress)
    when "in_progress" then update!(status: :completed)
    end
  end
end
```

### Forms
- Use Rails form helpers (NOT raw HTML `<form>`, `<input>`)
- Use `form.submit` for double-click prevention (NOT `<button type="submit">`)
- Use URL helpers (NOT hardcoded strings)

### Error Handling
- Do NOT rescue errors — Sentry handles them
- Exception: rescue expected errors with clear comments

### Credentials
- `Rails.application.credentials.dig(:section, :key)` (NOT `ENV['KEY']`)

### Pagination
- `Model.page(params[:page]).per(25)` (Kaminari)

### Soft Deletes
- `record.destroy` = soft delete (Paranoia)
- `record.really_destroy!` = permanent delete

### Reference Models
- Use ActiveHash for read-only static data
- `belongs_to_active_hash :country`
