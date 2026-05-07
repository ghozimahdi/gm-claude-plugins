---
name: ai-agents
description: "AI Agent architecture patterns for workflow automation in this plugin using RubyLLM"
disable-model-invocation: true
---

## AI Agent Patterns

### Architecture

**State (DB)** → **Planner (Agent)** → **Action (Job/Logic/LLM)** → **Trace (History)**

### Directory Structure

```
app/agents/
├── base_agent.rb               # Base class
├── task_agent.rb               # Multi-step workflow
├── task_group_agent.rb         # Batch processing
├── document_ocr_agent.rb       # OCR processing
├── document_classifier.rb      # Document classification
├── form_fill_agent.rb          # AI form filling
└── tools/                      # Reusable tools
    └── ...
```

### Base Agent

```ruby
class BaseAgent
  def initialize(record)
    @record = record
  end

  def run
    raise NotImplementedError, "Subclasses must implement #run"
  end

  private

  def log_action(action, details = {})
    @record.ai_action_histories.create!(
      action: action,
      details: details
    )
  end
end
```

### Agent Implementation

```ruby
class TaskAgent < BaseAgent
  def run
    case @record.status
    when "pending"
      check_prerequisites_and_notify
    when "waiting_response"
      check_deadline_and_escalate
    when "documents_received"
      validate_and_advance
    end
  end

  private

  def check_prerequisites_and_notify
    if prerequisites_met?
      @record.update!(status: :in_progress)
      TaskMailer.started(@record).deliver_later
      log_action("advanced_to_in_progress")
    end
  end

  def check_deadline_and_escalate
    if @record.due_at < 3.days.from_now
      TaskMailer.deadline_approaching(@record).deliver_later
      log_action("deadline_warning_sent")
    end
  end
end
```

### AiScheduledEvent

Schedule future actions with state validation:

```ruby
# Schedule a reminder
AiScheduledEvent.create!(
  eventable: @task,
  scheduled_at: 3.days.from_now,
  workflow_status: "waiting_response",  # MUST match current status when executing
  event_type: "send_reminder",
  priority: :normal
)
```

Rules:
- Always set `workflow_status` — events check status before executing
- Mark as triggered even if skipped (stale-safe)
- Use `priority` for urgent events
- Processed every 5 minutes via `ProcessAiScheduledEventsJob`

### RubyLLM Integration

```ruby
# Use LLM for intelligent reasoning
def classify_document(document)
  chat = RubyLLM.chat(model: "gpt-4o")
  response = chat.ask(
    "Classify this document: #{document.text_content}"
  )
  parse_classification(response)
end
```

### Agent Jobs

```ruby
# app/jobs/run_task_agent_job.rb
class RunTaskAgentJob < ApplicationJob
  queue_as :default

  def perform(task)
    TaskAgent.new(task).run
  end
end
```

### Creating a New Agent

1. Create agent class in `app/agents/`
2. Extend `BaseAgent` with `run` method
3. Create job in `app/jobs/` for async execution
4. Use or create model for state storage
5. Add tools in `app/agents/tools/` if reusable
6. Write tests in `test/agents/`

### Testing Agents

```ruby
class TaskAgentTest < ActiveSupport::TestCase
  test "advances pending task when prerequisites met" do
    task = tasks(:pending_with_prerequisites)
    agent = TaskAgent.new(task)
    agent.run
    assert task.reload.in_progress?
  end

  test "sends deadline warning for approaching due date" do
    task = tasks(:waiting_due_soon)
    assert_enqueued_emails 1 do
      TaskAgent.new(task).run
    end
  end
end
```
