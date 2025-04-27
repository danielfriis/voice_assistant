module HasGoogleCalendar
  extend ActiveSupport::Concern
  require "google/apis/calendar_v3"

  def google_calendars
    @google_calendars ||= calendar_client.list_calendar_lists.items
  end

  def google_calendar_events(start_date, end_date, calendar_id = nil)
    return [] unless google_identity&.raw_info&.dig("token")

    calender_ids = calendar_id ? [ calendar_id ] : google_calendars.map(&:id)

    events = []
    calender_ids.each do |calendar_id|
      events += calendar_client.list_events(
        calendar_id,
        single_events: true,
        order_by: "startTime",
        time_min: start_date.iso8601,
        time_max: end_date.iso8601
      ).items
    end

    events
  rescue Google::Apis::AuthorizationError => e
    Rails.logger.error "Authorization Error: #{e.message}"
    Rails.logger.error "Current token: #{google_identity.raw_info["token"]}"
    google_identity&.refresh_token!
    retry
  rescue Google::Apis::Error => e
    Rails.logger.error "Google Calendar API error: #{e.message}"
    []
  end

  def google_identity
    @google_identity ||= identities.find_by(provider: "google_oauth2")
  end

  private

  def calendar_client
    @calendar_client ||= Google::Apis::CalendarV3::CalendarService.new
    @calendar_client.authorization = google_credentials
    @calendar_client
  end

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
end
