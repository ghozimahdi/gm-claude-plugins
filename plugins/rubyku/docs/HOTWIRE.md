# Hotwire Guide

## Priority Order

1. **Turbo Frames** — partial page updates within a container
2. **Turbo Streams** — multiple DOM updates or real-time broadcasts
3. **Stimulus** — client-only UI behavior (no server calls)

## Turbo Frames

### When to Use
- Loading a section of a page independently
- Inline editing
- Lazy loading content
- Navigation within a container

### Rules
- Keep frames small and focused
- Use `dom_id` helper for consistent frame naming
- Set `loading: :lazy` for below-the-fold content

```erb
<%# Wrapping a section in a frame %>
<%= turbo_frame_tag dom_id(@post, :comments) do %>
  <%= render @post.comments %>
<% end %>

<%# Lazy loading %>
<%= turbo_frame_tag "weather", src: weather_path, loading: :lazy do %>
  <p>Loading...</p>
<% end %>
```

### Breaking Out of Frames
Use `data-turbo-frame="_top"` to navigate outside:
```erb
<%= link_to "Full page", post_path(@post), data: { turbo_frame: "_top" } %>
```

## Turbo Streams

### When to Use
- Updating multiple elements on the page
- Real-time broadcasting (Action Cable)
- After form submissions that affect multiple areas

### Seven Actions
- `append`, `prepend`, `replace`, `update`, `remove`, `before`, `after`

```erb
<%# Controller response %>
<%= turbo_stream.append "comments", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.update "comment_count", "#{@post.comments.count} comments" %>

<%# Model broadcasting %>
class Comment < ApplicationRecord
  broadcasts_to :post
end
```

## Stimulus

### When to Use
- Toggle visibility
- Form validation (client-side)
- UI interactions (dropdowns, modals, tabs)
- Copy to clipboard

### When NOT to Use
- Server communication (use Turbo instead)
- URL manipulation (Turbo handles it)
- Complex state management

### Controller Placement
- Shared: `app/javascript/controllers/`
- Namespace-specific: `app/javascript/controllers/{namespace}/`
- Cannot cross namespace boundaries

### Identifier Convention
```
data-controller="namespace--feature--action"
data-controller="t--renewal-tasks--intention"
```

## Common Patterns

### Inline Editing
```erb
<%= turbo_frame_tag dom_id(@post) do %>
  <div>
    <h2><%= @post.title %></h2>
    <%= link_to "Edit", edit_post_path(@post) %>
  </div>
<% end %>
```

### Flash Messages via Streams
```ruby
# Controller
def create
  @post = Post.new(post_params)
  if @post.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end
end
```

### Form Submission
```erb
<%= form_with model: @post do |form| %>
  <%= form.text_field :title %>
  <%= form.submit %>  <%# Always use form.submit, NOT <button> %>
<% end %>
```
