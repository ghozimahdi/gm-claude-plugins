# Credentials

## Rule 1: Do Not Use Environment Variables Directly

```ruby
# Bad
api_key = ENV['API_KEY']
bucket = ENV['S3_BUCKET']

# Good
api_key = Rails.application.credentials.dig(:api, :key)
bucket = Rails.application.credentials.dig(:aws, :s3, :bucket)
```

## Rule 2: Use Rails Credentials

All sensitive configuration must use Rails credentials. Credentials are encrypted and can be safely committed to version control.

## Rule 3: Managing Credentials

```bash
# Edit development credentials
EDITOR="code --wait" bin/rails credentials:edit --environment development

# Edit production credentials
EDITOR="code --wait" bin/rails credentials:edit --environment production

# Edit default credentials
EDITOR="code --wait" bin/rails credentials:edit
```

## Rule 4: Credentials Structure

Organize credentials hierarchically:

```yaml
basic_auth:
  username: admin
  password: secret

aws:
  access_key_id: xxx
  secret_access_key: xxx
  s3:
    bucket: my-bucket

azure:
  storage:
    account_name: xxx
    access_key: xxx

openai:
  api_key: xxx
```

## Rule 5: Accessing Credentials

Always use `dig` for safe access:

```ruby
# Good — safe access with dig
Rails.application.credentials.dig(:aws, :access_key_id)

# Bad — raises NoMethodError if key missing
Rails.application.credentials.aws.access_key_id
```
