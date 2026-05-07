# AI Agent Architecture

## Overview

A Rails-friendly Agent-based workflow automation pattern for tasks like multi-step approvals, OCR extraction, and document classification.

## Architecture Pattern

**State (DB)** → **Planner (Agent)** → **Action (Job/Logic/LLM)** → **Trace (History)**

### Components

| Component | Role | Location |
|-----------|------|----------|
| Models | Store state and workflow data | `app/models/` |
| Agents | Decide next actions based on state | `app/agents/` |
| Jobs | Execute side effects (emails, API calls) | `app/jobs/` |
| Mailers | Send notifications | `app/mailers/` |
| Tools | Reusable agent capabilities | `app/agents/tools/` |

### Agent Classes

```ruby
# app/agents/base_agent.rb
class BaseAgent
  def run
    raise NotImplementedError
  end
end

# app/agents/task_agent.rb
class TaskAgent < BaseAgent
  def run
    # 1. Read current state from model
    # 2. Decide next action
    # 3. Execute action (call job, send email, or use LLM)
    # 4. Update state
  end
end
```

### Example Agents

| Agent | Purpose |
|-------|---------|
| `TaskAgent` | Multi-step workflow automation |
| `UserGroupAgent` | Batch operation management |
| `DocumentOcrAgent` | OCR document processing |
| `DocumentClassifier` | Document type classification |
| `FormFillAgent` | AI-powered form filling |
| `TranslateNamesAgent` | Name translation |
| `CompletenessAgent` | Form completeness validation |

## AiScheduledEvent

Enables delayed agent actions:

```ruby
# Schedule a future action
AiScheduledEvent.create!(
  scheduled_at: 3.days.from_now,
  workflow_status: "waiting_response",
  eventable: task,
  event_type: "send_reminder"
)
```

Key rules:
- Always set `workflow_status` — events validate current state before executing
- Mark as triggered even if skipped (stale-safe)
- Use `priority` for urgent events

## RubyLLM Integration

```ruby
# Conditionally use LLM for intelligent reasoning
chat = RubyLLM.chat(model: "gpt-4o")
response = chat.ask("Analyze this document...")
```

## Creating New Agents

1. Create agent class in `app/agents/`
2. Extend `BaseAgent` with `run` method
3. Create corresponding job in `app/jobs/` for async execution
4. Create model or use existing model for state storage
5. Add tools in `app/agents/tools/` if reusable

## Testing Agents

```ruby
# test/agents/task_agent_test.rb
class TaskAgentTest < ActiveSupport::TestCase
  test "advances to next step when conditions met" do
    task = tasks(:pending)
    agent = TaskAgent.new(task)
    agent.run
    assert_equal "in_progress", task.reload.status
  end
end
```
