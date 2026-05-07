# File Storage

## Rule 1: Use ActiveStorage

All file uploads and attachments must use Rails ActiveStorage.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :documents
end
```

## Rule 2: Do Not Write Platform-Specific Logic

```ruby
# Bad — platform-specific
if Rails.env.production?
  upload_to_s3(file)
else
  save_to_disk(file)
end

# Good — ActiveStorage abstracts the backend
user.avatar.attach(file)
```

## Rule 3: Configuration

Storage backends configured in `config/storage.yml`:

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

azure:
  service: AzureStorage
  storage_account_name: <%= Rails.application.credentials.dig(:azure, :storage, :account_name) %>
  storage_access_key: <%= Rails.application.credentials.dig(:azure, :storage, :access_key) %>
  container: uploads
```

Environment-specific settings in `config/environments/`:

```ruby
# config/environments/development.rb
config.active_storage.service = :local

# config/environments/production.rb
config.active_storage.service = :azure
```
