---
description: "Run tests and report results. Use after implementing features."
argument-hint: "[test file, directory, or leave empty for all]"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
model: haiku
---

Run tests and report results.

Arguments: $ARGUMENTS (test file, directory, or empty for all tests)

## Steps

1. If `$ARGUMENTS` is provided:
   - If it's a test file: `bin/rails test $ARGUMENTS`
   - If it's a directory: `bin/rails test $ARGUMENTS`
   - If it's "system": `bin/rails test:system`
2. Otherwise: `bin/rails test`
3. If tests fail, show:
   - Failing test names
   - Error messages
   - Relevant file paths
4. Suggest fixes for each failing test

## Examples

```bash
/test                              # All tests
/test test/models/user_test.rb     # Specific file
/test test/controllers/admin/      # Directory
/test system                       # System tests
/test test/models/user_test.rb:15  # Specific line
```
