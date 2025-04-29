class Event < ApplicationRecord
  belongs_to :calendar

  delegate :background_color, :foreground_color, to: :calendar
  delegate :user, to: :calendar

  default_scope { order(start_time: :asc) }

  after_initialize :set_dates, if: :new_record?

  after_create_commit :broadcast_event

  def broadcast_event
    broadcast_append_to "agenda", target: "calendar_events", partial: "calendar/event", locals: { event: self }
  end

  def duration
    end_time - start_time
  end

  def self.create_via_google(calendar, event_data)
    zone = ActiveSupport::TimeZone.new(event_data[:time_zone])
    raise "Invalid time zone: #{event_data[:time_zone]}" if zone.nil?

    start_time = zone.parse(event_data[:start_time]).iso8601
    end_time = zone.parse(event_data[:end_time]).iso8601

    event_record = new(
      calendar: calendar,
      title: event_data[:title],
      description: event_data[:description],
      start_date: start_time.to_date,
      start_time: start_time,
      end_date: end_time.to_date,
      end_time: end_time
    )

    # Convert times to the calendar's timezone
    calendar_time_zone = calendar.time_zone || "UTC"
    start_time_in_calendar_tz = event_record.full_start_time.in_time_zone(calendar_time_zone)
    end_time_in_calendar_tz = event_record.full_end_time.in_time_zone(calendar_time_zone)

    new_event = {
      summary: event_record.title,
      description: event_record.description,
      start: {
        date_time: start_time_in_calendar_tz.iso8601,
        time_zone: calendar_time_zone
      },
      end: {
        date_time: end_time_in_calendar_tz.iso8601,
        time_zone: calendar_time_zone
      }
    }

    puts "Creating event: #{new_event}"

    created_event = event_record.calendar_client.insert_event(calendar.provider_id, new_event)
    return unless created_event.id.present?

    puts "Created event: #{created_event}"

    event_record.provider_id = created_event.id
    event_record.save!
    event_record
  end

  def full_start_time
    return start_time if start_time.nil? || start_date.blank?

    # Create a time in the user's time zone to ensure proper formatting
    return_time = Time.use_zone(start_time.time_zone) do
      Time.zone.local(
        start_date.year,
        start_date.month,
        start_date.day,
        start_time.hour,
        start_time.min,
        start_time.sec
      )
    end

    Rails.logger.info "Full start time #{return_time}"
    return_time
  end

  def full_end_time
    return end_time if end_time.nil? || end_date.blank?

    # Create a time in the user's time zone to ensure proper formatting
    return_time = Time.use_zone(end_time.time_zone) do
      Time.zone.local(
        end_date.year,
        end_date.month,
        end_date.day,
        end_time.hour,
        end_time.min,
        end_time.sec
      )
    end

    Rails.logger.info "Full end time #{return_time}"
    return_time
  end

  def calendar_client
    @calendar_client ||= Google::Apis::CalendarV3::CalendarService.new
    @calendar_client.authorization = google_credentials
    @calendar_client
  end

  private

  def google_credentials
    # Use Google::Auth::UserRefreshCredentials instead of OAuth2::AccessToken
    Google::Auth::UserRefreshCredentials.new(
      client_id: Rails.application.credentials.dig(:google_oauth, :client_id),
      client_secret: Rails.application.credentials.dig(:google_oauth, :client_secret),
      access_token: google_identity.raw_info["token"],
      refresh_token: google_identity.raw_info["refresh_token"],
      expires_at: google_identity.raw_info["expires_at"]
    )
  end

  def google_identity
    @google_identity ||= user.identities.find_by(provider: "google_oauth2")
  end

  def set_dates
    self.start_date = start_time.to_date if start_date.blank? && start_time.present?
    self.end_date = end_time.to_date if end_date.blank? && end_time.present?
  end
end
