class Identity < ApplicationRecord
  belongs_to :user
  has_many :calendars, dependent: :destroy
  has_many :events, through: :calendars

  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }
end
