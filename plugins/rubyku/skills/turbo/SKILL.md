---
name: turbo
description: "Turbo Frames and Turbo Streams patterns for server-driven UI updates  following Rails Way standards"
disable-model-invocation: true
---

## Turbo Patterns

### Turbo Frames

#### Basic Frame
```erb
<%= turbo_frame_tag dom_id(@task) do %>
  <h2><%= @task.title %></h2>
  <%= link_to "Edit", edit_s_task_path(@task) %>
<% end %>
```

#### Lazy Loading
```erb
<%= turbo_frame_tag "recent_activity", src: activity_path, loading: :lazy do %>
  <p class="text-gray-500">Loading activity...</p>
<% end %>
```

#### Inline Editing Pattern
```erb
<%# show.html.erb %>
<%= turbo_frame_tag dom_id(@task) do %>
  <span><%= @task.title %></span>
  <%= link_to "Edit", edit_s_task_path(@task) %>
<% end %>

<%# edit.html.erb %>
<%= turbo_frame_tag dom_id(@task) do %>
  <%= form_with model: [:s, @task] do |form| %>
    <%= form.text_field :title %>
    <%= form.submit %>
  <% end %>
<% end %>
```

#### Breaking Out
```erb
<%# Navigate full page from within a frame %>
<%= link_to "Details", s_task_path(@task), data: { turbo_frame: "_top" } %>
```

### Turbo Streams

#### Seven Actions
```erb
<%= turbo_stream.append "tasks", partial: "tasks/task", locals: { task: @task } %>
<%= turbo_stream.prepend "notifications", partial: "notification", locals: { notification: @notification } %>
<%= turbo_stream.replace dom_id(@task), partial: "tasks/task", locals: { task: @task } %>
<%= turbo_stream.update "counter", "#{@count} items" %>
<%= turbo_stream.remove dom_id(@task) %>
<%= turbo_stream.before dom_id(@task), partial: "tasks/task", locals: { task: @new_task } %>
<%= turbo_stream.after dom_id(@task), partial: "tasks/task", locals: { task: @new_task } %>
```

#### Controller with Turbo Stream
```ruby
def create
  @comment = @post.comments.build(comment_params)
  if @comment.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

```erb
<%# create.turbo_stream.erb %>
<%= turbo_stream.append "comments", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.update "comment_count", "#{@post.comments.count} comments" %>
<%= turbo_stream.replace "new_comment_form", partial: "comments/form", locals: { comment: Comment.new } %>
```

#### Real-time Broadcasting
```ruby
class ChatMessage < ApplicationRecord
  broadcasts_to :chat_channel
  # or
  after_create_commit -> { broadcast_append_to chat_channel }
end
```

### DOM ID Convention
Always use `dom_id` helper:
```erb
<%= turbo_frame_tag dom_id(@task) %>           <%# "task_42" %>
<%= turbo_frame_tag dom_id(@task, :comments) %> <%# "comments_task_42" %>
```

### Key Rules
- Use Turbo for ALL server communication (no fetch)
- Use `dom_id` for consistent frame naming
- Turbo Frames for single container updates
- Turbo Streams for multi-element or real-time updates
- Always provide HTML fallback with `respond_to`
