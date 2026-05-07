# PR Target Rules

## Basic Rule

Create issue branches from `main`. Open pull requests to `main`.

```
issues/42 → PR → main
```

## When There Is a Parent Issue with Sub-Issues

### Parent Issue
Create branch from `main`:
```
main → issues/14 (parent)
```

### Sub-Issues
Create sub-issue branches from the parent branch:
```
issues/14 → issues/15 (sub-issue)
```

PR flow for sub-issue:
```
issues/15 → PR → issues/14
```

### Completing the Parent Issue
Once all sub-issues are completed, open PR for the parent:
```
issues/14 → PR → main
```

## Summary

| Scenario | Branch From | PR Target |
|----------|-------------|-----------|
| Regular issue | `main` | `main` |
| Parent issue | `main` | `main` |
| Sub-issue | parent branch | parent branch |
