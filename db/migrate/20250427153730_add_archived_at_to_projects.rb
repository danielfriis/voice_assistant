class AddArchivedAtToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :archived_at, :datetime
  end
end
