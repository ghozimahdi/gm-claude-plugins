# SVG Icons

## Overview

SVG icons are implemented as Rails view partials to support dynamic color inheritance via CSS `currentColor`.

## Two Types

### 1. Dynamic SVGs (View Partials)
Use for icons that need CSS color inheritance (hover states, active states, theme colors).

Location: `app/views/shared/icons/` (organized by namespace)

```erb
<%# app/views/shared/icons/t/_home.html.erb %>
<svg xmlns="http://www.w3.org/2000/svg"
     class="<%= local_assigns[:class] || 'w-6 h-6' %>"
     fill="none"
     viewBox="0 0 24 24"
     stroke="currentColor"
     stroke-width="2">
  <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
</svg>
```

Usage:
```erb
<%= render "shared/icons/t/home", class: "w-5 h-5" %>

<%# Color inherited from parent %>
<div class="text-slate-400 hover:text-emerald-500">
  <%= render "shared/icons/t/home" %>
</div>
```

### 2. Static SVGs (Asset Files)
Use for SVGs with fixed colors (logos, illustrations).

Location: `app/assets/images/`

```erb
<%= image_tag "logo.svg", class: "h-8" %>
```

## When to Use Which

| Type | When |
|------|------|
| Dynamic (partial) | Navigation icons, interactive elements, icons matching text color |
| Static (asset) | Logos, decorative illustrations, multi-color SVGs |

## Adding New Icons

1. Create partial in `app/views/shared/icons/{namespace}/`
2. Use `local_assigns[:class]` with default fallback
3. Keep `stroke="currentColor"` for CSS color inheritance
4. Use standard attributes: `fill="none"`, `viewBox="0 0 24 24"`, `stroke-width="2"`

## Icon Source

Based on **Lucide** icon set (24x24 viewBox, stroke-based designs).
