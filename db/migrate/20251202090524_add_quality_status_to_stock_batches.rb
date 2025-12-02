class AddQualityStatusToStockBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_batches, :quality_status, :string
  end
end
