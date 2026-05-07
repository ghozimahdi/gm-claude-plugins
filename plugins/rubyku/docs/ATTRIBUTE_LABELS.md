# Attribute Labels

## Overview

The `AttributeLabels` concern provides `*_label` methods for all model attributes that return I18n translations via `human_attribute_name`. This module is automatically included in all models through `ApplicationRecord`.

## How It Works

Once included, every attribute automatically gets a `_label` method:

```ruby
user = User.new
user.email_label  # => User.human_attribute_name(:email) => "メールアドレス"
user.name_label   # => User.human_attribute_name(:name) => "名前"
```

The module uses `method_missing` to intercept calls to `*_label` methods and dynamically defines methods for future calls (performance optimization).

## Configuration

Attribute labels are configured in locale files under `activerecord.attributes`:

```yaml
# config/locales/models/user.ja.yml
ja:
  activerecord:
    attributes:
      user:
        name: 名前
        email: メールアドレス
        phone: 電話番号
```

File organization: `config/locales/models/` directory with files like `user.ja.yml`, `contract_condition.ja.yml`, etc.

## Usage in Views

```erb
<%# Display field label with value %>
<dt><%= @user.email_label %></dt>
<dd><%= @user.email %></dd>

<%# Form labels %>
<%= form.label :email, @user.email_label %>
```

## All Models Must Include

```ruby
class MyModel < ApplicationRecord
  include AttributeLabels
  # ...
end
```

## Testing with Japanese Locale

When testing validation error messages:
- "を入力してください" (can't be blank)
- "は不正な値です" (is invalid)
- "はすでに存在します" (has already been taken)

## Limitations

- Only works with database-backed attributes (`attribute_names`)
- Does not work with virtual attributes or custom accessors
- Requires I18n translations to be configured for meaningful labels

## Related Files

- `app/models/concerns/attribute_labels.rb`
- `app/models/application_record.rb`
- `config/locales/models/*.yml`
