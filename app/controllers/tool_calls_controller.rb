class ToolCallsController < ApplicationController
  def create
    tool_call = tool_call_params
    tool_call["arguments"] = JSON.parse(tool_call["arguments"])

    case tool_call["name"]
    when "create_todo"
      create_params = tool_call["arguments"].slice("title", "description", "due_date", "due_time").compact_blank
      todo = Current.user.todos.create!(create_params)
      render json: todo
    when "update_todo"
      todo = Current.user.todos.find(tool_call.dig("arguments", "id"))
      update_params = tool_call["arguments"].slice("title", "description", "due_date", "due_time").compact_blank
      todo.update!(update_params)
      render json: todo
    when "delete_todo"
      todo = Current.user.todos.find(tool_call.dig("arguments", "id"))
      todo.destroy
      render json: { success: true }
    else
      render json: { error: "Tool not found" }, status: :not_found
    end
  end

  private

  def tool_call_params
    params.require(:tool_call).to_unsafe_h.slice(:name, :arguments)
  end
end
