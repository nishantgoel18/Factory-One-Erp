class AddCertificateNumberToStockBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_batches, :certificate_number, :string
  end
end
