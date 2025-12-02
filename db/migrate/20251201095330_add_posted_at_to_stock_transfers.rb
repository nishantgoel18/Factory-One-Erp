class AddPostedAtToStockTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_transfers, :posted_at, :datetime
  end
end
