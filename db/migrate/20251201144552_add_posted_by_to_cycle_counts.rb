class AddPostedByToCycleCounts < ActiveRecord::Migration[8.1]
  def change
    add_column :cycle_counts, :posted_by, :integer
    add_index :cycle_counts, :posted_by
  end
end
