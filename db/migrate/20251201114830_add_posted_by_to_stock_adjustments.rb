class AddPostedByToStockAdjustments < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_adjustments, :posted_by, :integer
    add_index :stock_adjustments, :posted_by
  end
end
