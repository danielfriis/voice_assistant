class User < ApplicationRecord
  has_secure_password
  has_many :identities, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :todos, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :memories, dependent: :destroy
  has_many :calendars, through: :identities
  has_many :events, through: :calendars

  validates :name, presence: true

  include HasGoogleCalendar

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def time_zone
    nil
  end

  def sync_calendars
    # Get all Google calendars
    google_calendar_ids = google_calendars.map(&:id)

    # Delete calendars that no longer exist in Google
    google_identity.calendars.where.not(provider_id: google_calendar_ids).destroy_all
    google_calendars.each do |calendar|
      calendar_record = google_identity.calendars.find_or_create_by(provider_id: calendar.id) do |c|
        c.title = calendar.summary
        c.description = calendar.description
        c.background_color = calendar.background_color
        c.foreground_color = calendar.foreground_color
        c.time_zone = calendar.time_zone
      end

      # Get current events from Google Calendar
      google_events = google_calendar_events(1.week.ago.beginning_of_day, 4.weeks.from_now.end_of_day, calendar.id)
      google_event_ids = google_events.map(&:id)

      # Delete events that no longer exist in Google Calendar
      calendar_record.events.where.not(provider_id: google_event_ids).destroy_all

      # Create or update events
      google_events.each do |event|
        calendar_record.events.find_or_create_by(provider_id: event.id) do |e|
          e.title = event.summary
          e.description = event.description
          e.start_date = event.start.date || event.start.date_time.to_date
          e.start_time = event.start.date_time&.to_time
          e.end_date = event.end.date || event.end.date_time.to_date
          e.end_time = event.end.date_time&.to_time
          e.html_link = event.html_link
        end
      end
    end
  end

  def self.from_omniauth(auth)
    transaction do
      identity = Identity.find_or_initialize_by(provider: auth.provider, uid: auth.uid)

      if identity.new_record?
        # Try to find existing user by email or create new one
        user = User.find_or_initialize_by(email_address: auth.info.email) do |u|
          u.name = auth.info.name
          u.password = SecureRandom.hex(32)
        end

        identity.user = user
        identity.email = auth.info.email
        identity.name = auth.info.name
        identity.raw_info = auth.extra.raw_info.to_h

        identity.save!
      end

      identity.update!(raw_info: {
        "token" => auth.credentials.token,
        "refresh_token" => auth.credentials.refresh_token,
        "expires_at" => auth.credentials.expires_at
      }) if auth.credentials.token

      identity.user
    end
  end
end
