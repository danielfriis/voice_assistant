class OpenaiSessionsController < ApplicationController
  def create
    response = OpenaiSession.new(Current.user).build

    if response.success?
      render json: response.body
    else
      render json: { error: "Failed to create OpenAI session" }, status: :service_unavailable
    end
  end
end
