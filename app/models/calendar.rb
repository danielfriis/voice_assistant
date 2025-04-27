class Calendar < ApplicationRecord
  belongs_to :identity
  has_many :events, dependent: :destroy

  delegate :user, to: :identity
end
