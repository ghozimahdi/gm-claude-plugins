# Stimulus Controllers

## Directory Structure

```
app/javascript/controllers/
├── application.js                      # Stimulus application setup
├── index.js                            # Controller registration
├── hello_controller.js                 # Shared controller
├── modal_controller.js                 # Shared controller
├── t/
│   └── tasks/
│       └── intention_controller.js     # Screen-specific
├── c/
│   └── dashboard/
│       └── chart_controller.js         # Screen-specific
└── admin/
    └── ...
```

## Rules

### 1. Shared Controllers → Root Directory
Controllers used across multiple screens:
```
app/javascript/controllers/modal_controller.js
app/javascript/controllers/toggle_controller.js
```

### 2. Screen-Specific → Namespace Directory
Controllers for a specific screen mirror the URL namespace:
```
/t/tasks/intention → app/javascript/controllers/t/tasks/intention_controller.js
/c/dashboard              → app/javascript/controllers/c/dashboard/chart_controller.js
```

### 3. Naming Convention
- File names: `snake_case` (`intention_controller.js`)
- HTML identifiers: `kebab-case` with double-dashes for paths

```erb
data-controller="t--renewal-tasks--intention"
```

### 4. Namespace Boundary Enforcement

Namespace-specific controllers must only be referenced in views of that namespace:

| Controller | Can Be Used In | Cannot Be Used In |
|-----------|---------------|-------------------|
| `t--*` | `/t/` views | `/c/`, `/s/`, `/admin/` views |
| `c--*` | `/c/` views | `/t/`, `/s/`, `/admin/` views |
| `admin--*` | `/admin/` views | `/t/`, `/c/`, `/s/` views |

They may also appear in `app/views/shared/` and `app/views/layouts/`.

**Enforced in CI by `bin/lint_stimulus_namespaces`.**

If a controller needs to be used across namespaces, move it to `app/javascript/controllers/shared/`.

## When to Create

- **Shared controller**: functionality is generic and reusable (modals, dropdowns, copy-to-clipboard)
- **Screen-specific controller**: functionality is tightly coupled to a specific page's behavior or DOM structure
