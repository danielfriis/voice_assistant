class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.datetime :archived_at

      t.timestamps
    end
  end
end
