module OpenaiSession::ProjectTools
  def self.properties
    {
      id: { type: "string", description: "The id of the project" },
      title: { type: "string", description: "The title of the project" },
      description: { type: "string", description: "The description of the project (optional)" }
    }
  end

  def self.tools
    [
      {
        type: "function",
        name: "project_create",
        description: "Create a new project",
        parameters: {
          type: "object",
          properties: properties.except(:id),
          required: [ "title" ]
        }
      },
      {
        type: "function",
        name: "project_update",
        description: "Update a project",
        parameters: {
          type: "object",
          properties: properties,
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
end
