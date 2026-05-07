---
description: "Generate a Rails migration following project naming conventions."
argument-hint: "<migration_name> [columns...]"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
model: haiku
---

Generate a Rails migration following project naming conventions.

Arguments: $ARGUMENTS (migration name and optional columns)

## Naming Rules

- Present tense verb + target: `add_published_at_to_posts`, `create_users`
- Booleans: NO `is_`/`has_` prefix → `active`, `email_verified`
- Timestamps: `*_at` for datetime, `*_on` for date
- Foreign keys: singular `_id` → `user_id`, `post_id`

## Steps

1. Parse `$ARGUMENTS` for migration name and columns
2. Validate naming conventions:
   - Boolean columns don't have `is_`/`has_` prefix
   - Datetime columns end in `_at`
   - Date columns end in `_on`
3. Generate: `bin/rails generate migration $ARGUMENTS`
4. Show the generated migration file
5. Run `bin/rails db:migrate`
6. Run `bundle exec annotate` to update model annotations

## Examples

```bash
/generate-migration add_email_verified_to_users email_verified:boolean
/generate-migration create_tasks title:string status:integer due_at:datetime
/generate-migration add_user_id_to_posts user_id:references
```

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/NAMING_CONVENTIONS.md`
