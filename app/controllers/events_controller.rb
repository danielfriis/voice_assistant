class EventsController < ApplicationController
  def create
    if @event = Current.user.calendars.find(event_params[:calendar_id]).events.create_via_google(event_params)
      render json: @event, status: :created
    else
      render json: { error: "Failed to create event" }, status: :unprocessable_entity
    end
  end

  private

  def event_params
    params.require(:event).permit(:title, :description, :start_time, :end_time, :time_zone, :calendar_id)
  end
end
