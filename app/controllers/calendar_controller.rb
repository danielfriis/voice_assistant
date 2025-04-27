class CalendarController < ApplicationController
  def show
    @date = Date.parse(params[:date])
    @events = Current.user.events.where(start_date: @date)

    respond_to do |format|
      format.html { render :show }
      format.turbo_stream
    end
  end
end
