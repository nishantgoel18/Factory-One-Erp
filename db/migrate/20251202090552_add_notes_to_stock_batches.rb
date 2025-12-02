class AddNotesToStockBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_batches, :notes, :text
  end
end
