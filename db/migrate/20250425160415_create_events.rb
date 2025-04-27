class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :calendar, null: false, foreign_key: true
      t.string :provider_id
      t.string :title
      t.text :description
      t.string :status
      t.date :start_date
      t.time :start_time
      t.date :end_date
      t.time :end_time
      t.string :html_link

      t.timestamps
    end
  end
end
