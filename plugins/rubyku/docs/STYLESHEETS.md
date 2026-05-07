# Stylesheets

## Asset Manager: Propshaft (NOT Sprockets) + Tailwind CSS

## Directory Structure

```
app/assets/stylesheets/
├── application.css              # Shared/fallback
├── auth/
│   └── application.css          # Auth pages
├── admin/
│   └── application.css          # Admin namespace
└── users/
    ├── application.css          # User-facing namespace
    ├── sidebar.css              # Sidebar-specific
    └── tasks/
        └── profile_photos.css   # Page-specific
```

## Rules

### 1. Group by Namespace
Match URL namespace structure.

### 2. `application.css` as Entry Points
Each namespace has an `application.css` as entry point. Don't put actual styles here.

### 3. Separate Files for Styles
- Component styles: `{namespace}/{component}.css`
- Page-specific: `{namespace}/{controller}/{page}.css`

### 4. Load via `stylesheet_link_tag` in Layouts

```erb
<%# app/views/layouts/t/application.html.erb %>
<%= stylesheet_link_tag "application", "users/application", "users/sidebar" %>
```

### 5. Do NOT Use CSS `@import` for Local Files

**Propshaft adds digest hashes to filenames. CSS `@import` cannot resolve these, causing 404 errors.**

```css
/* Bad — will 404 */
@import "./sidebar.css";

/* Good — use stylesheet_link_tag instead */
```

### 6. Prefer Tailwind CSS Utility Classes

Use Tailwind directly in HTML/ERB. Only create custom CSS when:
- Styles require complex selectors or pseudo-elements
- Third-party library integration needs custom CSS
- Animations or keyframes are needed

```erb
<%# Good — Tailwind utilities %>
<div class="flex items-center gap-4 p-4 bg-white rounded-lg shadow">
  <h2 class="text-lg font-semibold text-gray-900"><%= @task.title %></h2>
</div>
```
