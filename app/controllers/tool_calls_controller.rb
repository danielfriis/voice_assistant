class ToolCallsController < ApplicationController
  def create
    tool_call = tool_call_params

    case tool_call["name"]
    when "get_weather"
      location = tool_call["arguments"]["location"]
      # TODO: Implement weather API call
      response = {
        "location" => location,
        "weather" => "72 degrees and sunny"
      }
      render json: response
    else
      render json: { error: "Tool not found" }, status: :not_found
    end
  end

  private

  def tool_call_params
    params.require(:tool_call).permit(:name, :arguments)
  end
end
