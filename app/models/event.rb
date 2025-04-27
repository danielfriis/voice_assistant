class Event < ApplicationRecord
  belongs_to :calendar

  delegate :background_color, :foreground_color, to: :calendar
  delegate :user, to: :calendar

  default_scope { order(start_time: :asc) }

  def duration
    end_time - start_time
  end

  def start_time
    return nil if super.nil?

    # Create a time in the user's time zone to ensure proper formatting
    Time.use_zone(calendar.time_zone || user.time_zone) do
      Time.zone.local(
        start_date.year,
        start_date.month,
        start_date.day,
        super.hour,
        super.min,
        super.sec
      )
    end
  end

  def end_time
    return nil if super.nil?

    # Create a time in the user's time zone to ensure proper formatting
    Time.use_zone(calendar.time_zone || user.time_zone) do
      Time.zone.local(
        end_date.year,
        end_date.month,
        end_date.day,
        super.hour,
        super.min,
        super.sec
      )
    end
  end
end
