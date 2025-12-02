class AddSupplierLotNumberToStockBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_batches, :supplier_lot_number, :string
  end
end
