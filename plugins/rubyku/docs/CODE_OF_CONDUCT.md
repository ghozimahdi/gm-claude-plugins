# Code of Conduct

## Backend Rules

### Controllers — Thin, HTTP Only
```ruby
# Good — thin controller
def create
  @post = @user.posts.build(post_params)
  if @post.save
    redirect_to @post
  else
    render :new, status: :unprocessable_entity
  end
end

# Bad — business logic in controller
def create
  @post = Post.new(post_params)
  @post.user = current_user
  @post.status = calculate_status(@post)  # NO business logic here
  NotificationService.notify(@post)       # NO service classes
end
```

### No Service Classes
Always use concerns instead:

```ruby
# Bad
app/services/task_service.rb

# Good — model-specific concern
app/models/task/status_transitions.rb

# Good — shared concern
app/models/concerns/notifiable.rb
```

### Query Through Associations
```ruby
# Good
@post = current_user.posts.find(params[:id])
@comments = @post.comments.order(created_at: :desc)

# Bad
@post = Post.where(user_id: current_user.id).find(params[:id])
@comments = Comment.where(post_id: @post.id)
```

### Strong Parameters
Always validate incoming parameters:
```ruby
def user_params
  params.require(:user).permit(:name, :email, :phone)
end
```

### Enum Usage
```ruby
# Good — predicate methods
task.pending?
Task.status_in_progress

# Bad — string comparison
task.status == "pending"
Task.where(status: :in_progress)
```

### Class Methods
```ruby
# Good
class << self
  def active
    where(active: true)
  end
end

# Bad
def self.active
  where(active: true)
end
```

### Scopes vs Class Methods
- Scopes: chainable queries returning relations
- Class methods: single-record lookups or non-chainable operations

### Forms
- Use Rails form helpers (NOT raw HTML `<form>`, `<input>`)
- Use `form.submit` for automatic double-click prevention (NOT `<button type="submit">`)
- Use Rails URL helpers (NOT hardcoded strings)

### Layout Files
- All HTML structure in layouts, not views
- Views contain only page-specific content

## Frontend Rules

### Hotwire Priority
1. **Turbo Frames** — single container updates
2. **Turbo Streams** — multi-element updates
3. **Stimulus** — client-only UI behavior

### Prohibited
- No `fetch()` for server communication — use Turbo
- No `pushState`/`replaceState` — Turbo handles URLs
- No jQuery or vanilla JS without team approval
- No disabling Turbo (`data-turbo="false"`) without team consultation
- No complex Stimulus (>100 lines) without team review

## Code Quality

- Run `bundle exec rubocop` before every PR (zero tolerance)
- All code comments must be in English
- No magic numbers — use predicate methods or constants
- No `Rails.env` checks in application code
- No hardcoded environment-specific values
- Use credentials, not ENV

## Error Handling

- Do NOT rescue errors — let Sentry catch them
- Exception: rescue expected errors (external API 404s, missing optional files)
- Must include clear comments explaining why rescue is appropriate
- Never broad rescue `StandardError` or `Exception`

## Reference Models

- Use ActiveHash for read-only static data (countries, industries, etc.)
- `belongs_to_active_hash` for associations
- Never use for user-generated or frequently changing data
