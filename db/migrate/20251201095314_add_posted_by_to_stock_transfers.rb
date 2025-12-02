class AddPostedByToStockTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_transfers, :posted_by, :integer
    add_index :stock_transfers, :posted_by
  end
end
