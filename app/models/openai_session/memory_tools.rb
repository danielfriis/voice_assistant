module OpenaiSession::MemoryTools
  def self.properties
    {
      id: { type: "string", description: "The id of the memory" },
      subject: { type: "string", description: "The subject of the memory." },
      content: { type: "string", description: "The content of the memory. Keep it short and concise." }
    }
  end

  def self.tools
    [
      {
        type: "function",
        name: "memory_create",
        description: "Create a new memory",
        parameters: {
          type: "object",
          properties: properties.except(:id),
          required: [ "subject", "content" ]
        }
      },
      {
        type: "function",
        name: "memory_update",
        description: "Update a memory",
        parameters: {
          type: "object",
          properties: properties,
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
end
