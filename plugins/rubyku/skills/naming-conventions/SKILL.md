---
name: naming-conventions
description: "Naming rules for models, controllers, database columns, branches, commits, and file organization  following Rails Way standards"
disable-model-invocation: true
---

## Naming Conventions

### Database Columns

| Type | Convention | Good | Bad |
|------|-----------|------|-----|
| Boolean | positive, no `is_`/`has_` | `active`, `email_verified` | `is_active`, `has_email` |
| Datetime | `*_at` | `published_at`, `expired_at` | `publish_date`, `expiry` |
| Date | `*_on` | `birthday_on`, `hired_on` | `birthday`, `hire_date` |
| Foreign key | singular `_id` | `user_id` | `users_id` |
| Enum | singular | `status`, `role` | `statuses` |

### Models & Tables

| Entity | Convention | Example |
|--------|-----------|---------|
| Model | singular CamelCase | `Post` |
| Table | plural snake_case | `posts` |
| File | snake_case | `post.rb` |
| Concern (model-specific) | `ModelName::ConcernName` | `Task::StatusTransitions` |
| Concern (shared) | `ConcernName` | `Notifiable` |

### Controllers

| Entity | Convention | Example |
|--------|-----------|---------|
| Class | plural CamelCase + Controller | `Admin::UsersController` |
| File | snake_case | `app/controllers/admin/users_controller.rb` |
| Actions | REST only | `index`, `show`, `new`, `create`, `edit`, `update`, `destroy` |

### Jobs & Mailers

| Entity | Convention | Example |
|--------|-----------|---------|
| Job | + `Job` | `SendWelcomeEmailJob` |
| Mailer | + `Mailer` | `UserMailer` |

### Migrations

Present tense verb + target:
- `add_published_at_to_posts`
- `create_tasks`
- `remove_legacy_column_from_accounts`

### Git

| Entity | Format | Example |
|--------|--------|---------|
| Branch | `issues/<id>` | `issues/42` |
| Commit | `[#id] Message` | `[#42] Fix login timeout` |
| No issue | `[fix] Message` | `[fix] Fix typo` |
| PR title | `[#id] Description` | `[#42] Add renewal notifications` |

### Class Methods
```ruby
# Good — class << self
class << self
  def find_active
    where(active: true)
  end
end

# Bad — def self.method
def self.find_active
  where(active: true)
end
```

### Enum Usage
```ruby
# Good — predicate
task.pending?
task.in_progress?

# Good — scope
Task.status_pending
Task.status_in_progress

# Bad
task.status == "pending"
Task.where(status: :pending)
```

