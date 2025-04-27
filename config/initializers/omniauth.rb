redirect_uri = Rails.env.production? ? "https://jamie.nowadays.tech/auth/google_oauth2/callback" : "https://discrete-open-boa.ngrok-free.app/auth/google_oauth2/callback"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    Rails.application.credentials.dig(:google_oauth, :client_id),
    Rails.application.credentials.dig(:google_oauth, :client_secret),
    {
      scope: "email,profile,https://www.googleapis.com/auth/calendar.readonly,https://www.googleapis.com/auth/calendar.events",
      prompt: "consent select_account",
      access_type: "offline",
      redirect_uri: redirect_uri
    }
end

# Handles OmniAuth failure cases
OmniAuth.config.on_failure = Proc.new do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

# Allow POST requests for OmniAuth paths
OmniAuth.config.allowed_request_methods = [ :post ]
