---
name: testing
description: "Minitest testing patterns for this plugin — model, controller, job, and system tests with fixtures"
disable-model-invocation: true
---

## Testing Patterns

### Framework
- **Minitest** (NOT RSpec)
- **Capybara** + Selenium for system tests
- **Fixtures** for test data (NOT factories)

### Running Tests
```bash
bin/rails test                      # All tests
bin/rails test:system               # System tests
bin/rails test test/models/         # Directory
bin/rails test test/models/user_test.rb      # File
bin/rails test test/models/user_test.rb:15   # Line
```

### Model Tests
```ruby
class TaskTest < ActiveSupport::TestCase
  test "validates presence of title" do
    task = Task.new(title: nil)
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "soft deletes with paranoia" do
    task = tasks(:active)
    task.destroy
    assert_not_nil task.deleted_at
    assert_not Task.exists?(task.id)
    assert Task.only_deleted.exists?(task.id)
  end

  test "advances status from pending to in_progress" do
    task = tasks(:pending)
    task.advance!
    assert task.in_progress?
  end

  test "scopes due_soon returns tasks due within 3 days" do
    assert_includes Task.due_soon, tasks(:due_tomorrow)
    assert_not_includes Task.due_soon, tasks(:due_next_month)
  end
end
```

### Controller Tests
```ruby
class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:default)
    sign_in @admin
  end

  test "should get index" do
    get admin_users_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post admin_users_url, params: { user: { name: "New User", email: "new@example.com" } }
    end
    assert_redirected_to admin_user_url(User.last)
  end

  test "should not create user with invalid params" do
    assert_no_difference("User.count") do
      post admin_users_url, params: { user: { name: "", email: "" } }
    end
    assert_response :unprocessable_entity
  end
end
```

### Job Tests
```ruby
class SendWelcomeEmailJobTest < ActiveJob::TestCase
  test "sends welcome email" do
    user = users(:new_user)
    assert_enqueued_emails 1 do
      SendWelcomeEmailJob.perform_later(user)
    end
  end

  test "enqueues in default queue" do
    assert_enqueued_with(queue: "default") do
      SendWelcomeEmailJob.perform_later(users(:new_user))
    end
  end
end
```

### Mailer Tests
```ruby
class TaskMailerTest < ActionMailer::TestCase
  test "status_changed sends to correct recipient" do
    task = tasks(:active)
    email = TaskMailer.status_changed(task)
    assert_equal [task.user.email], email.to
    assert_match "Status Update", email.subject
  end
end
```

### System Tests
```ruby
class UserLoginTest < ApplicationSystemTestCase
  test "user can sign in" do
    visit new_user_session_path
    fill_in "Email", with: users(:default).email
    fill_in "Password", with: "password"
    click_on "Sign in"
    assert_text "Signed in successfully"
  end

  test "user sees error with wrong password" do
    visit new_user_session_path
    fill_in "Email", with: users(:default).email
    fill_in "Password", with: "wrong"
    click_on "Sign in"
    assert_text "Invalid Email or password"
  end
end
```

### Fixtures
```yaml
# test/fixtures/tasks.yml
active:
  title: Active Task
  status: 1
  user: default_user
  due_at: <%= 1.week.from_now %>

pending:
  title: Pending Task
  status: 0
  user: default_user
```

### Assertions
```ruby
assert value                           # truthy
assert_not value                       # falsy
assert_equal expected, actual          # equality
assert_includes collection, item       # membership
assert_difference("Model.count", 1)    # count change
assert_no_difference("Model.count")    # no count change
assert_raises(ActiveRecord::RecordNotFound) { ... }
assert_enqueued_emails 1 { ... }
assert_response :success
assert_redirected_to url
```

### Guidelines
- Test behavior, not implementation
- One assertion per test when possible
- Use fixtures for test data
- Test edge cases and error paths
- Run RuboCop on test files too
