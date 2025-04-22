class CreateTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :todos do |t|
      t.string :title
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.references :todo, null: true, foreign_key: true
      t.date :due_date
      t.time :due_time
      t.integer :priority, default: 0
      t.integer :time_estimate
      t.integer :position
      t.datetime :completed_at

      t.timestamps
    end
  end
end
