module OpenaiSession::NoteTools
  def self.properties
    {
      id: { type: "string", description: "The id of the note" },
      content: { type: "string", description: "The content of the note. Markdown is supported." },
      project_id: { type: "string", description: "The id of the project the note belongs to (optional). If the project is not yet created, you should create it first to get an id." }
    }
  end

  def self.tools
    [
      {
        type: "function",
        name: "note_create",
        description: "Create a new note",
        parameters: {
          type: "object",
          properties: properties.except(:id),
          required: [ "content" ]
        }
      },
      {
        type: "function",
        name: "note_update",
        description: "Update a note",
        parameters: {
          type: "object",
          properties: properties,
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
end
