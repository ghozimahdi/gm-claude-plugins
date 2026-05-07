# Reference Models

## Overview

Reference models are read-only master data stored in code using the **ActiveHash** gem. They provide ActiveRecord-like API without database tables.

## When to Use

**Use for:**
- Countries, prefectures, regions
- Industry categories
- Status codes and types
- Organization type codes
- Any data that rarely changes and doesn't need user editing

**Don't use for:**
- Data users can create/update/delete
- Data with complex relationships
- Large datasets
- Data needing full-text search

## Directory Structure

```
app/models/reference/
├── country.rb
├── industry.rb
├── employment_type.rb
└── ...
```

## Creating a Reference Model

```ruby
# app/models/reference/country.rb
class Reference::Country < ActiveHash::Base
  self.data = [
    { id: 1, name: "Japan", code: "JP" },
    { id: 2, name: "United States", code: "US" },
    { id: 3, name: "United Kingdom", code: "GB" },
    { id: 4, name: "Indonesia", code: "ID" },
  ]
end
```

## Using Reference Models

### Queries
```ruby
Reference::Country.all
Reference::Country.find(1)
Reference::Country.find_by(name: "Japan")
```

### Association with ActiveRecord
```ruby
class User < ApplicationRecord
  belongs_to_active_hash :country, class_name: "Reference::Country"
end
```

### In Forms
```erb
<%= form.select :country_id, Reference::Country.all.map { |c| [c.name, c.id] } %>
```

### Validation
```ruby
validates :country_id, inclusion: { in: Reference::Country.all.map(&:id) }
```

## Best Practices

- Use sequential integer IDs starting from 1
- Include `name_en` for user-facing data
- Keep data sorted by ID
- Add `# frozen_string_literal: true` at top
- **Never change existing IDs**
- Don't skip IDs unnecessarily

## Example Reference Models

Country, Industry, AddressType, EmploymentType, JobCategory — anything that's a fixed enum-like list and rarely changes.
