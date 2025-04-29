module OpenaiSession::EventTools
  def self.properties
    {
      id: { type: "string", description: "The id of the event" },
      calendar_id: { type: "string", description: "The id of the calendar the event belongs to" },
      title: { type: "string", description: "The title of the event" },
      description: { type: "string", description: "The description of the event (optional)" },
      start_time: { type: "string", description: "The start time of the event. Format: YYYY-MM-DD HH:MM." },
      end_time: { type: "string", description: "The end time of the event. Format: YYYY-MM-DD HH:MM." },
      time_zone: { type: "string", description: "The timezone of the event. Format: UTC or Europe/London etc." }
    }
  end

  def self.tools
    [
      {
        type: "function",
        name: "event_create",
        description: "Create a new event",
        parameters: {
          type: "object",
          properties: properties.except(:id),
          required: [ "title", "calendar_id", "start_time", "end_time", "time_zone" ]
        }
      }
    ]
  end
end
