class AddDeletedToSupplierAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :supplier_addresses, :deleted, :boolean, default: false
  end
end
