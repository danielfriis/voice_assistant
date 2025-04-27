class CreateCalendars < ActiveRecord::Migration[8.0]
  def change
    create_table :calendars do |t|
      t.references :identity, null: false, foreign_key: true
      t.string :provider_id
      t.boolean :visible, default: true
      t.string :title
      t.string :description
      t.string :background_color
      t.string :foreground_color
      t.string :time_zone

      t.timestamps
    end
  end
end
