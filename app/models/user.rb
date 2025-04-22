class User < ApplicationRecord
  has_secure_password
  has_many :identities, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :todos, dependent: :destroy

  include HasGoogleCalendar

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.from_omniauth(auth)
    transaction do
      identity = Identity.find_or_initialize_by(provider: auth.provider, uid: auth.uid)

      if identity.new_record?
        # Try to find existing user by email or create new one
        user = User.find_or_initialize_by(email_address: auth.info.email) do |u|
          u.password = SecureRandom.hex(32) if u.new_record?
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
