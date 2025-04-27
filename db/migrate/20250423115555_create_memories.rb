class CreateMemories < ActiveRecord::Migration[8.0]
  def change
    create_table :memories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subject
      t.text :content

      t.timestamps
    end
  end
end
