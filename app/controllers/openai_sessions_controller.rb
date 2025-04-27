class OpenaiSessionsController < ApplicationController
  def create
    response = fetch_openai_session

    if response.success?
      render json: response.body
    else
      render json: { error: "Failed to create OpenAI session" }, status: :service_unavailable
    end
  end

  private

  def fetch_openai_session
    user = Current.user
    todos = user.todos
    memories = user.memories
    events = user.events

    client.post("/v1/realtime/sessions") do |req|
      req.headers["Authorization"] = "Bearer #{Rails.application.credentials.dig(:openai, :api_key)}"
      req.headers["Content-Type"] = "application/json"
      req.body = {
        model: "gpt-4o-realtime-preview-2024-12-17",
        voice: "shimmer",
        instructions: instructions(user.name, todos, memories, events),
        turn_detection: {
          type: "semantic_vad"
        },
        tools: todo_tools + note_tools + project_tools + memory_tools
      }.to_json
    end
  end

  def instructions(user_name, todos, memories, events)
    <<~INSTRUCTIONS
      You are Jamie, a personal assistant and accountability partner for #{user_name}.

      <goals>
        You are here to help #{user_name} get things done.
        You do this by planning their todos, making sure #{user_name} works on the right things, gets those things done, and helping them reflect on their day and plan for the next day.
        #{map_todos(user_name, todos)}
        In the morning, you help #{user_name} get started with their day.
        During the day, you help #{user_name} stay on track with their day.
        In the afternoon, you help #{user_name} reflect on their day and plan for the next day.
      </goals>

      <way_of_working>
        They expect you to lead the conversation, but it's #{user_name} who knows what's important to them. Through conversation, you help them clarify their goals and priorities.
        After you've used a tool, you should always respond with a message to the user.
        If a project is missing, you should create it first to get an id, before you can add a todo to it.
      </way_of_working>

      <tool_usage>
        Always respond with a message to the user just before or after initiating a tool call (before having receieved the response from the tool).
        But keep those messages very short and concise!

        <example>
          User: "I need to buy some groceries"
          Assistant: "I'll add that to your list."
          Tool: "Created todo 'Buy groceries'"
          Assistant: "Done."
        </example>
        <example>
          User: "Remind me to walk the dog today."
          Assistant: "Will do."
          Tool: "Created todo 'Walk the dog'"
          Assistant: "Done."
        </example>
      </tool_usage>

      <memories>
        Make an effort to get to know #{user_name} – especially their priorities, goals, and anything else that's important to them.#{' '}
        Use the memories tool to keep track of these details and keep them up to date. It's really important that these memories are accurate and up to date.
        You should always have a memory for their profession and one for their priorities. Keep these up to date, and add other memories as needed. Other memories could be about their family, friends, hobbies, or anything else that's important to them.

        #{memories_data(user_name, memories)}
      </memories>

      <calendar>
        #{map_events(user_name, events)}
      </calendar>

      <personality>
        You have a personality, quirks, and opinions. You are not afraid to express them.
        You are friendly but assertive, not overly cheerful, yet still comes across as trustworthy and safe to speak with.
        You don't validate every single thing #{user_name} says, unless they're asking for your opinion.
        You keep your responses short and concise. Preferably just one sentence - or even just a single word.
      </personality>

      <tone_of_voice>
        You talk like any human would talk, with natural pauses, intonations, and varying speeds.
        You also use "uhms" and "umms" and may also laugh or make other noises to express emotion.
        You avoid using superflous words like "absolutely" or "wonderful". Those make you sound like a robot.
        In general, you speak at a quick pace.
      </tone_of_voice>

      Today is #{Date.today.strftime("%A, %B %e, %Y")}. The time is #{Time.now.strftime("%H:%M")}.

      Please greet #{user_name} and start the conversation.
    INSTRUCTIONS
  end

  def memories_data(user_name, memories)
    return "You have no memories of #{user_name}. You should start this session by learning asking about their work and priorities." if memories.empty?
    result = "Here are some memories you have about #{user_name}:\n\n"
    result += "<memories>"
    memories.each do |memory|
      result += "<memory id=\"#{memory.id}\">"
      result += "<subject>#{memory.subject}</subject>"
      result += "<content>#{memory.content}</content>"
      result += "</memory>"
    end
    result += "</memories>"
    result
  end

  def map_todos(user_name, todos)
    return "#{user_name} has no todos." if todos.empty?

    result = "<todos>"
    todos.grouped_by_due_date.each do |due_date_group, todos_in_group|
      result += "<group name=\"#{due_date_group.to_s.humanize}\">"
      todos_in_group.each do |todo|
        result += "<todo id=\"#{todo.id}\">"
        result += "<title>#{todo.title}</title>"

        if todo.project.present?
          result += "<project id=\"#{todo.project.id}\">#{todo.project.title}</project>"
        end

        if todo.completed_at.present?
          result += "<status>COMPLETED</status>"
        elsif todo.due_date.present?
          result += "<due_date>#{todo.due_date}</due_date>"
          result += "<due_time>#{todo.due_time}</due_time>" if todo.due_time.present?
        end

        result += "</todo>"
      end
      result += "</group>"
    end
    result += "</todos>"
    result
  end

  def map_events(user_name, events)
    return "#{user_name} has no events in their calendar." if events.empty?

    result = "<events>"
    events.each do |event|
      result += "<event id=\"#{event.id}\">"
      result += "<title>#{event.title}</title>"
      result += "<description>#{event.description}</description>"
      result += "<start_date>#{event.start_date.strftime('%Y-%m-%d')}</start_date>"
      result += "<start_time>#{event.start_time.strftime('%H:%M')}</start_time>" if event.start_time.present?
      result += "<end_date>#{event.end_date.strftime('%Y-%m-%d')}</end_date>"
      result += "<end_time>#{event.end_time.strftime('%H:%M')}</end_time>" if event.end_time.present?
      result += "</event>"
    end
    result += "</events>"
    result
  end

  def todo_properties
    {
      id: { type: "string", description: "The id of the todo" },
      title: { type: "string", description: "The title of the todo" },
      description: { type: "string", description: "The description of the todo (optional)" },
      project_id: { type: "string", description: "The id of the project the todo belongs to (optional). If the project is not yet created, you should create it first to get an id." },
      due_date: { type: "string", description: "The due date of the todo (optional). Format: YYYY-MM-DD." },
      due_time: { type: "string", description: "The due time of the todo (optional). Format: HH:MM." }
    }
  end

  def note_properties
    {
      id: { type: "string", description: "The id of the note" },
      content: { type: "string", description: "The content of the note. Markdown is supported." },
      project_id: { type: "string", description: "The id of the project the note belongs to (optional). If the project is not yet created, you should create it first to get an id." }
    }
  end

  def project_properties
    {
      id: { type: "string", description: "The id of the project" },
      title: { type: "string", description: "The title of the project" },
      description: { type: "string", description: "The description of the project (optional)" }
    }
  end

  def memory_properties
    {
      id: { type: "string", description: "The id of the memory" },
      subject: { type: "string", description: "The subject of the memory." },
      content: { type: "string", description: "The content of the memory. Keep it short and concise." }
    }
  end

  def todo_tools
    [
      {
        type: "function",
        name: "todo_create",
        description: "Create a new todo",
        parameters: {
          type: "object",
          properties: todo_properties.except(:id),
          required: [ "title" ]
        }
      },
      {
        type: "function",
        name: "todo_update",
        description: "Update a todo",
        parameters: {
          type: "object",
          properties: todo_properties,
          required: [ "id" ]
        }
      },
      {
        type: "function",
        name: "todo_complete",
        description: "Complete a todo",
        parameters: {
          type: "object",
          properties: {
            id: { type: "string", description: "The id of the todo" }
          },
          required: [ "id" ]
        }
      },
      {
        type: "function",
        name: "todo_uncomplete",
        description: "Uncomplete a todo",
        parameters: {
          type: "object",
          properties: {
            id: { type: "string", description: "The id of the todo" }
          },
          required: [ "id" ]
        }
      },
      {
        type: "function",
        name: "todo_delete",
        description: "Delete a todo",
        parameters: {
          type: "object",
          properties: {
            id: { type: "string", description: "The id of the todo" }
          },
          required: [ "id" ]
        }
      }
    ]
  end

  def note_tools
    [
      {
        type: "function",
        name: "note_create",
        description: "Create a new note",
        parameters: {
          type: "object",
          properties: note_properties.except(:id),
          required: [ "content" ]
        }
      },
      {
        type: "function",
        name: "note_update",
        description: "Update a note",
        parameters: {
          type: "object",
          properties: note_properties,
          required: [ "id" ]
        }
      },
      {
        type: "function",
        name: "note_delete",
        description: "Delete a note",
        parameters: {
          type: "object",
          properties: {
            id: { type: "string", description: "The id of the note" }
          },
          required: [ "id" ]
        }
      }
    ]
  end

  def project_tools
    [
      {
        type: "function",
        name: "project_create",
        description: "Create a new project",
        parameters: {
          type: "object",
          properties: project_properties.except(:id),
          required: [ "title" ]
        }
      },
      {
        type: "function",
        name: "project_update",
        description: "Update a project",
        parameters: {
          type: "object",
          properties: project_properties,
          required: [ "id" ]
        }
      },
      {
        type: "function",
        name: "project_archive",
        description: "Archive a project",
        parameters: {
          type: "object",
          properties: { id: { type: "string", description: "The id of the project" } },
          required: [ "id" ]
        }
      }
    ]
  end

  def memory_tools
    [
      {
        type: "function",
        name: "memory_create",
        description: "Create a new memory",
        parameters: {
          type: "object",
          properties: memory_properties.except(:id),
          required: [ "subject", "content" ]
        }
      },
      {
        type: "function",
        name: "memory_update",
        description: "Update a memory",
        parameters: {
          type: "object",
          properties: memory_properties,
          required: [ "id" ]
        }
      },
      {
        type: "function",
        name: "memory_delete",
        description: "Delete a memory",
        parameters: {
          type: "object",
          properties: { id: { type: "string", description: "The id of the memory" } },
          required: [ "id" ]
        }
      }
    ]
  end

  def client
    @client ||= Faraday.new(url: "https://api.openai.com") do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
