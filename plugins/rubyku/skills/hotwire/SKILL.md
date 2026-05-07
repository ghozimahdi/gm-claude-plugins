---
name: hotwire
description: "Hotwire patterns — Turbo Frames, Turbo Streams, and Stimulus priority order for this plugin frontend"
disable-model-invocation: true
---

## Hotwire Patterns

### Priority Order
1. **Turbo Frames** — partial page updates within a container
2. **Turbo Streams** — multiple DOM updates or real-time broadcasts
3. **Stimulus** — client-only UI behavior (no server calls)

### Prohibited
- No `fetch()` for server communication
- No `pushState`/`replaceState` — Turbo handles URLs
- No jQuery or vanilla JS without team approval
- No disabling Turbo without team consultation
- No complex Stimulus (>100 lines) without team review

### Turbo Frames

```erb
<%# Partial page update %>
<%= turbo_frame_tag dom_id(@task) do %>
  <div class="p-4">
    <h2><%= @task.title %></h2>
    <%= link_to "Edit", edit_s_task_path(@task) %>
  </div>
<% end %>

<%# Lazy loading %>
<%= turbo_frame_tag "weather", src: weather_path, loading: :lazy do %>
  <p>Loading...</p>
<% end %>

<%# Breaking out of frame %>
<%= link_to "Full page", post_path(@post), data: { turbo_frame: "_top" } %>
```

### Turbo Streams

Seven actions: `append`, `prepend`, `replace`, `update`, `remove`, `before`, `after`

```erb
<%# Controller response (create.turbo_stream.erb) %>
<%= turbo_stream.append "comments", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.update "comment_count", "#{@post.comments.count} comments" %>
```

```ruby
# Model broadcasting
class Comment < ApplicationRecord
  broadcasts_to :post
end
```

### Stimulus

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}
```

### Controller Placement
- Shared: `app/javascript/controllers/`
- Namespace-specific: `app/javascript/controllers/{namespace}/`
- Identifier: `data-controller="t--renewal-tasks--intention"`
- Cannot cross namespace boundaries

### Forms — ALWAYS Use Helpers
```erb
<%= form_with model: [:s, @task] do |form| %>
  <%= form.text_field :title %>
  <%= form.submit %>  <%# NOT <button type="submit"> %>
<% end %>
```
