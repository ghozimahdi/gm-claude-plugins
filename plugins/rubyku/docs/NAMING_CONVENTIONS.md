# Naming Conventions

## General Rules

| Entity | Convention | Example |
|--------|-----------|---------|
| Classes/Modules | CamelCase | `Post` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Files/Folders | snake_case | `post.rb` |
| Tables | plural snake_case | `posts` |
| Models | singular CamelCase | `Post` |
| Foreign keys | singular `_id` | `user_id` |
| Controllers | plural + `Controller` | `UsersController` |
| Jobs | + `Job` | `SendWelcomeEmailJob` |
| Mailers | + `Mailer` | `UserMailer` |
| Concerns | descriptive module name | `StatusTransitions` |

## Database Columns

- **Booleans**: positive words, NO `is_`/`has_` prefix
  - Good: `active`, `email_verified`, `published`
  - Bad: `is_active`, `has_email`, `is_published`
- **Timestamps**: `*_at` for datetime, `*_on` for date
  - Good: `published_at`, `birthday_on`, `expired_at`
  - Bad: `publish_date`, `birthday`, `expiry`
- **Enums**: singular snake_case
  - Good: `status`, `role`, `category`

## Migrations

- Present tense verb + target
  - Good: `add_published_at_to_posts`, `create_users`, `remove_legacy_column_from_accounts`
  - Bad: `added_field`, `new_migration`

## Routes

- Resources: plural (`resources :users`)
- Namespaces: match URL prefix (`namespace :admin`)
- State pages: nested namespace with resource

```ruby
# Good
namespace :intention do
  resource :complete, only: [:show, :create]
end

# Bad — custom action
resources :tasks do
  member do
    post :complete  # Avoid this
  end
end
```

## Concerns

- Model-specific: `app/models/model_name/concern_name.rb`
  - Module: `ModelName::ConcernName`
- Shared: `app/models/concerns/concern_name.rb`
  - Module: `ConcernName`
- Controller: `app/controllers/concerns/concern_name.rb`

## Helpers

- Common: `app/helpers/` (root)
- Namespace-specific: `app/helpers/{namespace}/{controller}/`
- Namespace isolation: `/t/` helpers cannot use `/c/` helpers

## Stimulus Controllers

- Shared: `app/javascript/controllers/`
- Namespace-specific: `app/javascript/controllers/{namespace}/`
- Identifier: kebab-case with double-dashes: `data-controller="t--renewal-tasks--intention"`

## Stylesheets

- Organized by namespace: `app/assets/stylesheets/{namespace}/application.css`
- Use `stylesheet_link_tag` with multiple args (NOT CSS `@import`)

## Git

- **Branch**: `issues/<issue_id>` (e.g., `issues/42`)
- **Commit**: `[#issue_id] Imperative message` (e.g., `[#100] Fix login timeout`)
- **No issue**: `[fix] Message`

