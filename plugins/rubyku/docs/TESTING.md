# Testing Guide

## Framework
- **Minitest** (Rails default) — NOT RSpec
- System tests use **Selenium WebDriver** + **Capybara**
- Fixtures for test data (in `test/fixtures/`)

## Running Tests

```bash
bin/rails test                 # All tests
bin/rails test:system          # System tests only
bin/rails test <file>          # Specific test file
bin/rails test <file>:<line>   # Specific test
```

## Directory Structure

Tests mirror `app/` structure:
```
test/
├── agents/           # Agent tests
├── channels/         # Action Cable tests
├── controllers/      # Controller tests (by namespace)
│   ├── admin/
│   ├── c/
│   ├── s/
│   └── t/
├── fixtures/         # Test data (YAML)
├── helpers/          # Helper tests
├── integration/      # Integration tests
├── jobs/             # Background job tests
├── lib/              # Library tests
├── mailers/          # Mailer tests
│   └── previews/     # Mailer previews
├── models/           # Model tests
├── support/          # Test helpers
├── system/           # Browser tests
└── test_helper.rb    # Shared config
```

## Writing Tests

### Model Tests
```ruby
class UserTest < ActiveSupport::TestCase
  test "validates presence of name" do
    user = User.new(name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "soft deletes with paranoia" do
    user = users(:active_user)
    user.destroy
    assert_not_nil user.deleted_at
    assert User.only_deleted.include?(user)
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
end
```

### System Tests
```ruby
class LoginTest < ApplicationSystemTestCase
  test "user can sign in" do
    visit new_user_session_path
    fill_in "Email", with: users(:default).email
    fill_in "Password", with: "password"
    click_on "Sign in"
    assert_text "Signed in successfully"
  end
end
```

## Fixtures

Located in `test/fixtures/` — YAML files with test data:
```yaml
# test/fixtures/users.yml
default:
  name: Test User
  email: test@example.com
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>

admin_user:
  name: Admin User
  email: admin@example.com
```

## Guidelines

- Test behavior, not implementation
- One assertion per test when possible
- Use fixtures for test data (not factories)
- Use `assert`, `assert_not`, `assert_equal`, `assert_includes`
- Test edge cases and error paths
- Test model validations and callbacks
- Run `bundle exec rubocop` on test files too
