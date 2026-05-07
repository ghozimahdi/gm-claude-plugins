# Error Handling

## General Rule: Do NOT Rescue Errors

Let Sentry catch and report errors. Custom rescue blocks can hide bugs.

```ruby
# Bad — silently swallows error
def process
  do_something
rescue StandardError => e
  Rails.logger.error(e.message)  # Sentry never sees this
end

# Good — let error propagate to Sentry
def process
  do_something
end
```

## Exception: Expected Errors

Rescuing is acceptable when:
1. The error is a normal part of application flow
2. You have a clear recovery strategy
3. Letting it propagate would cause poor user experience

**Must include clear comments:**

```ruby
# Good — expected error with explanation
def fetch_profile
  api_client.get_profile(user_id)
rescue ApiClient::NotFoundError
  # External API may return 404 for deleted resources.
  # This is expected when the user's profile was removed from
  # the partner system. Return nil to show empty state.
  nil
end
```

## Bad Patterns

```ruby
# Bad — too broad, no explanation
rescue StandardError => e
  nil
end

# Bad — catches everything including typos
rescue Exception => e
  log(e)
end

# Bad — hides validation errors
rescue ActiveRecord::RecordInvalid
  false
end
```

## Re-raising After Logging

If you need context before Sentry captures:

```ruby
def process
  do_something
rescue => e
  Sentry.set_context("processing", { user_id: user.id, step: current_step })
  raise  # Re-raise so Sentry captures it
end
```

## Using Sentry Context Without Rescue

```ruby
def process
  Sentry.set_context("processing", { user_id: user.id })
  Sentry.set_user(id: user.id, email: user.email)
  do_something  # If this raises, Sentry captures it WITH context
end
```
