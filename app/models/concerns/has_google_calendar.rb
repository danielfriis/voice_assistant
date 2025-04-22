module HasGoogleCalendar
  extend ActiveSupport::Concern
  require "google/apis/calendar_v3"

  def google_calendar_events(start_date, end_date)
    return [] unless google_identity&.raw_info&.dig("token")

    calendar_client = Google::Apis::CalendarV3::CalendarService.new
    calendar_client.authorization = google_credentials

    # Add debug logging
    Rails.logger.debug "Using token: #{google_identity.raw_info["token"]}"

    calenders = calendar_client.list_calendar_lists

    events = []
    calenders.items.each do |calendar|
      events += calendar_client.list_events(
        calendar.id,
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

  private

  def google_identity
    identities.find_by(provider: "google_oauth2")
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
