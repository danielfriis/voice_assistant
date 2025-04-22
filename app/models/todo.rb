class Todo < ApplicationRecord
  belongs_to :user
  belongs_to :todo, optional: true

  after_create_commit :broadcast_todo
  after_update_commit :broadcast_update_todo
  after_destroy_commit :broadcast_remove_todo

  private

  def broadcast_todo
    if self.due_date.nil?
      target = "no-due-date"
    elsif self.due_date < Date.today
      target = "overdue"
    elsif self.due_date == Date.today
      target = "today"
    else
      target = "future"
    end

    broadcast_append_to "todos", target: target, partial: "todos/todo", locals: { todo: self }
  end

  def broadcast_remove_todo
    broadcast_remove_to "todos", target: "todo_#{self.id}"
  end

  def broadcast_update_todo
    broadcast_remove_todo
    broadcast_todo
  end
end
