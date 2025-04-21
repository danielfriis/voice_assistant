class SessionsController < ApplicationController
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
    client.post("/v1/realtime/sessions") do |req|
      req.headers["Authorization"] = "Bearer #{Rails.application.credentials.dig(:openai, :api_key)}"
      req.headers["Content-Type"] = "application/json"
      req.body = {
        model: "gpt-4o-realtime-preview-2024-12-17",
        voice: "shimmer",
        instructions: "You are a helpful assistant that can answer questions and help with tasks. You talk moderately slowly, dynamically, and briefly. You talk like a human would talk, with pauses, natural intonations, etc.",
        turn_detection: {
          type: "semantic_vad"
        },
        tools: [
          {
            type: "function",
            name: "get_weather",
              description: "Get the weather for a given location",
              parameters: {
                type: "object",
                properties: {
                  location: { type: "string", description: "The location to get the weather for" }
                }
              }
          }
        ]
      }.to_json
    end
  end

  def client
    @client ||= Faraday.new(url: "https://api.openai.com") do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
