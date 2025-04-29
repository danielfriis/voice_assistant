module OpenaiSession::TodoTools
  def self.properties
    {
      id: { type: "string", description: "The id of the todo" },
      title: { type: "string", description: "The title of the todo" },
      time_estimate: { type: "string", description: "The time estimate of the todo in minutes (optional)." },
      description: { type: "string", description: "The description of the todo (optional)" },
      project_id: { type: "string", description: "The id of the project the todo belongs to (optional). If the project is not yet created, you should create it first to get an id." },
      due_date: { type: "string", description: "The due date of the todo (optional). Format: YYYY-MM-DD." },
      due_time: { type: "string", description: "The due time of the todo (optional). Format: HH:MM." }
    }
  end

  def self.tools
    [
      {
        type: "function",
        name: "todo_create",
        description: "Create a new todo",
        parameters: {
          type: "object",
          properties: properties.except(:id),
          required: [ "title" ]
        }
      },
      {
        type: "function",
        name: "todo_update",
        description: "Update a todo",
        parameters: {
          type: "object",
          properties: properties,
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
end
