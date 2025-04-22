class AgendaController < ApplicationController
  def index
    @todos = Current.user.todos
    @date = Date.today
    fetch_calendar_events
    render action: "show"
  end

  def show
    @todos = Current.user.todos
    @date = Date.parse(params[:date])
    fetch_calendar_events
  end

  private

  def fetch_calendar_events
    @events = Current.user.google_calendar_events(
      @date.beginning_of_day,
      @date.end_of_day
    )
  end
end
