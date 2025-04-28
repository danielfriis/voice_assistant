class AgendaController < ApplicationController
  def index
    @todos = Current.user.todos
    @date = Date.today

    Current.user.sync_calendars
    @events = Current.user.events.where(start_date: @date)
  end
end
