class AddSupplierBatchRefToStockBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_batches, :supplier_batch_ref, :string
  end
end
