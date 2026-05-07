---
name: stimulus
description: "Stimulus controller patterns for client-only UI behavior  following Rails Way standards"
disable-model-invocation: true
---

## Stimulus Patterns

### When to Use
- Toggle visibility (show/hide elements)
- Form validation (client-side only)
- UI interactions (dropdowns, modals, tabs, tooltips)
- Copy to clipboard
- Animations and transitions

### When NOT to Use
- Server communication → use Turbo Frames/Streams
- URL manipulation → Turbo handles it
- Complex state management → consider Turbo Streams
- Anything >100 lines → consult team first

### Basic Controller
```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { open: { type: Boolean, default: false } }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.contentTarget.classList.toggle("hidden", !this.openValue)
  }
}
```

```erb
<div data-controller="toggle">
  <button data-action="toggle#toggle">Toggle</button>
  <div data-toggle-target="content" class="hidden">
    Content here
  </div>
</div>
```

### File Placement

| Location | Purpose |
|----------|---------|
| `app/javascript/controllers/` | Shared across all namespaces |
| `app/javascript/controllers/t/` | Talent (`/t`) specific |
| `app/javascript/controllers/c/` | Client org (`/c`) specific |
| `app/javascript/controllers/s/` | Support org (`/s`) specific |
| `app/javascript/controllers/admin/` | Admin specific |

### Naming Convention

Controllers follow kebab-case with double-dashes for namespaces:

```erb
<%# Shared controller %>
data-controller="toggle"

<%# Namespace-specific %>
data-controller="t--renewal-tasks--intention"
```

Maps to: `app/javascript/controllers/t/tasks/intention_controller.js`

### Namespace Isolation
- `/t/` controllers CANNOT be used in `/c/` views
- `/c/` controllers CANNOT be used in `/s/` views
- Extract to shared if needed across namespaces

### Common Patterns

#### Dropdown
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
```

#### Form Validation
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error"]

  validate() {
    const value = this.inputTarget.value
    if (value.length < 3) {
      this.errorTarget.textContent = "Must be at least 3 characters"
      this.errorTarget.classList.remove("hidden")
    } else {
      this.errorTarget.classList.add("hidden")
    }
  }
}
```

### Key Rules
- Frontend behavior ONLY — no fetch calls
- No pushState/replaceState
- Keep controllers focused and small (<100 lines)
- Use targets and values, not querySelector
- Respect namespace boundaries
