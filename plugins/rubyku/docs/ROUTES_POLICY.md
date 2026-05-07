# Routes Policy

## Default: RESTful Resources

Use standard REST actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`

```ruby
# Good
resources :users, only: [:index, :show, :edit, :update]

# Bad — custom actions
resources :users do
  member do
    post :activate    # Avoid
    post :deactivate  # Avoid
  end
end
```

## State Pages

Use nested namespace with resource for state-specific pages:

```ruby
# Good — separate controller
namespace :intention do
  resource :complete, only: [:show, :create]
  resource :decline, only: [:show, :create]
end

# Bad — custom member actions
resources :tasks do
  member do
    post :complete
    post :decline
  end
end
```

## New Screen = New Controller

When a new page or behavior is needed, create a new controller with a noun-based name:

```ruby
# Good — separate controller
resources :task_exports, only: [:new, :create]

# Bad — adding to existing controller
resources :tasks do
  collection do
    get :export_form
    post :export
  end
end
```

## Route File Organization

For larger apps, split routes into separate files under `config/routes/`:
- `config/routes/admin.rb`
- `config/routes/api.rb`
- etc.

Main `config/routes.rb` uses `draw` to include them.

## Namespace Structure

```ruby
# Admin
namespace :admin do
  resources :users
  resources :posts
end

# API
namespace :api do
  namespace :v1 do
    resources :posts, only: [:index, :show]
  end
end

# Custom role prefix (example only — match whatever your app uses)
namespace :s, module: :support do
  resources :dashboard, only: [:index]
end
```
