class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :extract_time_zone_from_request

  private

  def extract_time_zone_from_request
    time_zone = request.headers["Time-Zone"] || cookies[:timezone]

    if time_zone.present? && Current.user && Current.user.time_zone.blank?
      Current.user.update!(time_zone: time_zone)
    end

    time_zone
  end
end
