class AddCancelledByIdToRfqs < ActiveRecord::Migration[8.1]
  def change
    add_column :rfqs, :cancelled_by_id, :integer
    add_index :rfqs, :cancelled_by_id
  end
end
