module DueDateGroupable
  extend ActiveSupport::Concern

  included do
    # Define class attribute for date field
    class_attribute :due_date_field, default: :due_date

    # Class methods/scopes
    scope :overdue, -> { where("#{due_date_field} < ?", Date.today).where.not(due_date_field => nil) }
    scope :due_today, -> { where(due_date_field => Date.today) }
    scope :future, -> { where("#{due_date_field} > ?", Date.today) }
    scope :no_due_date, -> { where(due_date_field => nil) }
  end

  class_methods do
    def due_date_definitions
      {
        overdue: ->(date) { date.present? && date < Date.today },
        due_today: ->(date) { date == Date.today },
        future: ->(date) { date.present? && date > Date.today },
        no_due_date: ->(date) { date.nil? }
      }.freeze
    end

    def grouped_by_due_date
      {
        overdue: overdue,
        due_today: due_today,
        future: future,
        no_due_date: no_due_date
      }
    end
  end

  # Instance methods
  def due_date_group
    self.class.due_date_definitions.each do |due_date_group, condition|
      return due_date_group if condition.call(send(due_date_field))
    end
  end

  # Dynamically define predicate methods (overdue?, due_today?, etc.)
  def self.included(base)
    base.due_date_definitions.each do |due_date_group, condition|
      define_method("#{due_date_group}?") do
        condition.call(send(due_date_field))
      end
    end
  end
end
