class Todo < ApplicationRecord
  include DueDateGroupable

  attr_accessor :toggle_completed

  belongs_to :user
  belongs_to :todo, optional: true
  belongs_to :project, optional: true

  after_create_commit :broadcast_todo
  after_update_commit :broadcast_update_todo
  after_destroy_commit :broadcast_remove_todo

  validates :title, presence: true

  def complete!
    update(completed_at: Time.current)
  end

  def uncomplete!
    update(completed_at: nil)
  end

  private

  def broadcast_todo
    if self.no_due_date?
      target = "no-due-date"
    elsif self.overdue?
      target = "overdue"
    elsif self.due_today?
      target = "today"
    else
      target = "future"
    end

    broadcast_append_to "agenda", target: target, partial: "todos/todo", locals: { todo: self }
  end

  def broadcast_remove_todo
    broadcast_remove_to "agenda", target: "todo_#{self.id}"
  end

  def broadcast_update_todo
    Rails.logger.debug "broadcast_update_todo called"
    if self.saved_change_to_due_date?
      Rails.logger.debug "due_date changed from #{due_date_was} to #{due_date}"
      broadcast_remove_todo
      broadcast_todo
    else
      broadcast_replace_to "agenda", target: "todo_#{self.id}", partial: "todos/todo", locals: { todo: self }
    end
  end
end
