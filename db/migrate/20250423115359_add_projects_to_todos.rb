class AddProjectsToTodos < ActiveRecord::Migration[8.0]
  def change
    add_reference :todos, :project, null: true, foreign_key: true
  end
end
