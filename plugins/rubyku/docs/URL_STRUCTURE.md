# URL Structure

If your Rails app organizes screens by role, give each role its own URL namespace and `ApplicationController`. The exact prefixes are up to the host app — these are common examples:

| Role / Screen | Prefix | Example URLs |
|---------------|--------|--------------|
| Authentication (Devise) | `/users` | `/users/sign_in` |
| User-facing | `/` or `/app` | `/dashboard`, `/posts` |
| Admin | `/admin` | `/admin/users`, `/admin/posts` |
| API | `/api` | `/api/v1/posts/:id` |

## Notes

- Each namespace has its own `ApplicationController` that handles authentication, layout, and cross-action concerns. For example:
  - `Admin::ApplicationController`
  - `Api::ApplicationController`
- All controllers follow `app/controllers/<namespace>/` structure
- Custom role prefixes (e.g. `/s`, `/c`, `/t`) are fine — match whatever the host app's `config/routes.rb` already uses

## Controller Directory Mapping

| URL Prefix | Controller Directory |
|-----------|---------------------|
| `/admin/` | `app/controllers/admin/` (module: `Admin`) |
| `/api/` | `app/controllers/api/` (module: `Api`) |
