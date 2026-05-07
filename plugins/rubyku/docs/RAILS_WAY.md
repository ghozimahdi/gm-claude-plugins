# Rails Way

## Core Principles

### 1. DRY (Don't Repeat Yourself)
Extract common functionality into reusable components (concerns, helpers, partials).

### 2. Convention over Configuration
Follow Rails conventions instead of custom configurations.

## Controllers — Thin

Controllers handle HTTP concerns only:
- Handle request/response flow
- Use strong parameters
- Use `before_action` for common setup
- Redirect or render appropriately

```ruby
# Good
class Admin::UsersController < Admin::ApplicationController
  before_action :set_user, only: [:show, :edit, :update]

  def create
    @user = current_admin.users.build(user_params)
    if @user.save
      redirect_to [:admin, @user], notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
```

**Don't:**
- Write business logic
- Query database with complex conditions
- Send emails directly (use model callbacks or jobs)

## Validations — In Models

```ruby
class User < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0 }, allow_nil: true
end
```

## Callbacks — For Lifecycle Events

```ruby
class Task < ApplicationRecord
  before_validation :normalize_title
  after_create_commit :send_notification

  private

  def normalize_title
    self.title = title&.strip
  end

  def send_notification
    TaskMailer.created(self).deliver_later
  end
end
```

Best practice: use jobs for heavy processing in callbacks.

## Forms — Use Helpers

```erb
<%= form_with model: @user do |form| %>
  <%= form.text_field :name %>
  <%= form.email_field :email %>
  <%= form.submit %>  <%# NOT <button type="submit"> %>
<% end %>
```

Controllers should only call `save` or `update`.

## Helpers — View Logic Only

```ruby
module ApplicationHelper
  def format_currency(amount)
    number_to_currency(amount, unit: "¥", precision: 0)
  end
end
```

Don't put business logic in helpers.

## Summary

| Component | Responsibility |
|-----------|---------------|
| Controller | HTTP request/response handling only |
| Model | Business logic, validations, callbacks |
| Concern | Organized business logic modules |
| Helper | View/presentation logic |
| Job | Heavy/async processing |
