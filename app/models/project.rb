class Project < ApplicationRecord
  belongs_to :user

  has_many :todos, dependent: :destroy
  has_many :notes, dependent: :destroy

  def archived!
    update!(completed_at: Time.current)
  end
end
