# Environment Independence

Application code must not behave differently based on the runtime environment (development, staging, production).

## Rule 1: Do Not Check Service Implementation Classes

```ruby
# Bad — inspecting storage service class
if ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService)
  # local behavior
else
  # cloud behavior
end

# Good — use ActiveStorage's unified API
blob.url
```

## Rule 2: Do Not Branch on `Rails.env`

```ruby
# Bad — environment branching in app code
if Rails.env.production?
  send_real_email(user)
else
  log_email(user)
end

# Good — configure in environment files
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp

# config/environments/development.rb
config.action_mailer.delivery_method = :smtp  # Mailcatcher
```

## Rule 3: Do Not Hardcode Environment-Specific Values

```ruby
# Bad
API_URL = Rails.env.production? ? "https://api.example.com" : "http://localhost:4000"

# Good — use credentials
API_URL = Rails.application.credentials.dig(:external_api, :url)
```

## Where Environment Differences Belong

- `config/environments/*.rb` — Rails and gem settings
- `config/credentials/*.yml.enc` — secrets and environment-specific values
- `config/storage.yml` — ActiveStorage backend configuration
- `config/database.yml` — database configuration

## Acceptable Uses of `Rails.env`

- Initializers (`config/initializers/`)
- Configuration files (`config/environments/`)
- Seeds and rake tasks
