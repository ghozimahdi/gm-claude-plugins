---
description: "Resolve git merge conflicts intelligently using project guidelines."
argument-hint: "[file path]"
allowed-tools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep"]
---

Resolve git merge conflicts by understanding both sides and making intelligent decisions.

Arguments: $ARGUMENTS (optional specific file path)

## Steps

### 1. Identify conflicting files

- If `$ARGUMENTS` provided, resolve that specific file
- Otherwise: `git diff --name-only --diff-filter=U`

### 2. For each conflicting file

- Read the file to see conflict markers
- Understand the purpose of each side's changes
- Check git log for both branches to understand intent
- Consider project guidelines from `docs/guidelines/`

### 3. Resolve

- Choose appropriate resolution (keep HEAD, keep incoming, merge both)
- Remove all conflict markers
- Ensure resulting code follows project guidelines

### 4. Verify

- `bundle exec rubocop <file>` for Ruby files
- Run relevant tests
- Ensure no conflict markers remain

### 5. Stage

- `git add <resolved_file>` for each resolved file

## Special Cases

- **db/schema.rb**: take the later version, re-run `bin/rails db:migrate`
- **Gemfile.lock**: delete and run `bundle install`
- **Routes files**: ensure no duplicate routes

## Report

- Number of files resolved
- Summary of resolution decisions
- Reminder to run tests before committing
