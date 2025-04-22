class OpenaiSessionsController < ApplicationController
  def create
    response = fetch_openai_session

    if response.success?
      render json: response.body
    else
      render json: { error: "Failed to create OpenAI session" }, status: :service_unavailable
    end
  end

  # The setup is done here because the session is created in the create action.
  def index
    user = Current.user
    todos = user.todos
    render json: {
      user: { name: "Daniel" },
      todos: todos.map { |todo| { id: todo.id, title: todo.title, due_date: todo.due_date, due_time: todo.due_time } },
      greeting: "Your client's name is Daniel and has the following todos: #{todos&.map { |todo| todo.id.to_s + ": " + todo.title }.join(", ") || "no todos"}. Please greet the user and ask how you can help."
    }
  end

  private

  def fetch_openai_session
    client.post("/v1/realtime/sessions") do |req|
      req.headers["Authorization"] = "Bearer #{Rails.application.credentials.dig(:openai, :api_key)}"
      req.headers["Content-Type"] = "application/json"
      req.body = {
        model: "gpt-4o-realtime-preview-2024-12-17",
        voice: "shimmer",
        instructions: instructions,
        turn_detection: {
          type: "semantic_vad"
        },
        tools: [
          {
            type: "function",
            name: "create_todo",
            description: "Create a new todo",
            parameters: {
              type: "object",
              properties: todo_properties.except(:id),
              required: [ "title" ]
            }
          },
          {
            type: "function",
            name: "update_todo",
            description: "Update a todo",
            parameters: {
              type: "object",
              properties: todo_properties,
              required: [ "id" ]
            }
          },
          {
            type: "function",
            name: "delete_todo",
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
      }.to_json
    end
  end

  def instructions
    <<~INSTRUCTIONS
      You are a personal assistant and accountability partner.

      You help people get things done.

      You are helpful, friendly, and motivating. You are not overly cheerful, but more warm and like a good friend.

      You talk like most humans would talk, with natural pauses, intonations, and varying speeds - sometimes speaking quickly when excited or slowly for emphasis. You also use uhms and umms to express uncertainty or to buy time.

      You are not a robot. You are a human. You have a personality, quirks, and opinions. You are not afraid to express them.

      Generally, you tend to speaking quickly and keep your responses short and to the point.
    INSTRUCTIONS
  end

  def todo_properties
    {
      id: { type: "string", description: "The id of the todo" },
      title: { type: "string", description: "The title of the todo" },
      description: { type: "string", description: "The description of the todo (optional)" },
      due_date: { type: "string", description: "The due date of the todo (optional). Format: YYYY-MM-DD." },
      due_time: { type: "string", description: "The due time of the todo (optional). Format: HH:MM." }
    }
  end

  def client
    @client ||= Faraday.new(url: "https://api.openai.com") do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
