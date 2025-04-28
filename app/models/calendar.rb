class Calendar < ApplicationRecord
  belongs_to :identity
  has_many :events, dependent: :destroy do
    def create_via_google(event_data)
      Event.create_via_google(proxy_association.owner, event_data)
    end
  end

  delegate :user, to: :identity
end
