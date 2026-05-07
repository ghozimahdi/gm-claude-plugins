# Code Comments

## Rule

**All comments in the code must be written in English.**

This applies to:
- Inline comments
- Block comments
- Method/class documentation
- TODO/FIXME notes

## Examples

```ruby
# Bad — Japanese
# 税込み価格を計算する
def calculate_total
  price * 1.1
end

# Good — English
# Calculate the total price including tax
def calculate_total
  price * 1.1
end
```

```javascript
// Bad
// サイドバーの表示を切り替える

// Good
// Toggle the sidebar visibility
```

## Rationale

- Ensures codebase accessibility for all team members
- Facilitates collaboration with international developers
- Maintains consistency across the codebase
- Makes code review easier for everyone

## Scope

This rule applies only to **code comments**. User-facing content (UI text, error messages, etc.) should be in the appropriate language for the target audience.
