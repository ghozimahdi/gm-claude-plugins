---
description: "Run tests and automatically fix any errors or failures."
argument-hint: "[test file or pattern]"
allowed-tools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep"]
---

Run tests and automatically fix any errors or failures.

Arguments: $ARGUMENTS (test file or pattern, empty for all tests)

## Steps

### 1. Run tests

- If `$ARGUMENTS` provided: `bin/rails test $ARGUMENTS`
- Otherwise: `bin/rails test`

### 2. Analyze failures

For each error/failure:
- Read the test file and source code
- Identify root cause
- Determine if the test or source code should be fixed

### 3. Fix issues

Common fixes:
- Removing non-existent fields from permitted params
- Updating test data to use valid attributes
- Fixing method signatures or return values
- Correcting assertions
- Updating fixtures

### 4. Re-run and verify

- Re-run tests to confirm fix
- Run `bundle exec rubocop <modified_files>` for style compliance

### 5. Report

Summary of fixes made and test status.

## Guidelines

- Prefer fixing source code when the test is correct
- Prefer fixing tests when the source code behavior is intentional
- Check model schema annotations for correct field names
- Keep changes minimal and focused
