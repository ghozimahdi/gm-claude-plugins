# Turbo Guide

## Turbo Frames vs Turbo Streams

| | Turbo Frames | Turbo Streams |
|---|-------------|---------------|
| Updates | Single container | Multiple DOM elements |
| Trigger | Link clicks, form submissions | Form submissions, WebSocket, SSE |
| Response | HTML matching frame | `<turbo-stream>` elements |

**Decision:** Use Frames for single area updates. Use Streams for multiple areas or broadcasting.

## Turbo Frames

### Core Principles

1. **Smaller DOM Replacement** — smaller frames = minimal DOM updates
2. **Single Purpose** — one frame = one responsibility (form, list, detail panel)
3. **Avoid Unintended Re-renders** — large frames cause scroll reset, focus loss, JS state re-init
4. **Composition & Reuse** — smaller frames are easier to extract and reuse

### Frame Naming
Always use `dom_id` helper:
```erb
<%= turbo_frame_tag dom_id(@task) %>              <%# "task_42" %>
<%= turbo_frame_tag dom_id(@task, :comments) %>   <%# "comments_task_42" %>
```

### Inline Editing Pattern
```erb
<%# show view %>
<%= turbo_frame_tag dom_id(@task) do %>
  <span><%= @task.title %></span>
  <%= link_to "Edit", edit_s_task_path(@task) %>
<% end %>

<%# edit view (same frame ID) %>
<%= turbo_frame_tag dom_id(@task) do %>
  <%= form_with model: [:s, @task] do |form| %>
    <%= form.text_field :title %>
    <%= form.submit %>
  <% end %>
<% end %>
```

### Anti-patterns
- Wrapping entire pages in one frame
- Deeply nested frames
- Mixing unrelated concerns in one frame

## Turbo Streams

### Seven Actions
```erb
<%= turbo_stream.append "tasks", partial: "tasks/task", locals: { task: @task } %>
<%= turbo_stream.prepend "notifications", partial: "notification" %>
<%= turbo_stream.replace dom_id(@task), partial: "tasks/task" %>
<%= turbo_stream.update "counter", "#{@count} items" %>
<%= turbo_stream.remove dom_id(@task) %>
<%= turbo_stream.before dom_id(@task), partial: "tasks/task" %>
<%= turbo_stream.after dom_id(@task), partial: "tasks/task" %>
```

### Controller Response
```ruby
def create
  @comment = @post.comments.build(comment_params)
  if @comment.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end
end
```

### Broadcasting (Real-time)
```ruby
class ChatMessage < ApplicationRecord
  broadcasts_to :chat_channel
  # or
  after_create_commit -> { broadcast_append_to chat_channel }
end
```

```erb
<%# Subscribe in view %>
<%= turbo_stream_from @chat_channel %>
```

### Stream Anti-patterns
- Too many granular stream actions
- Missing target elements in DOM
- Mixing streams with full page navigation

## Combining Frames and Streams

Frames contain forms. Stream responses update frames AND other elements:

```erb
<%# create.turbo_stream.erb %>
<%= turbo_stream.append "comments", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.update "comment_count", "#{@post.comments.count}" %>
<%= turbo_stream.replace "new_comment_form", partial: "comments/form", locals: { comment: Comment.new } %>
```
