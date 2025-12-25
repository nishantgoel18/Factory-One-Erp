class AddDeletedToProductSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :product_suppliers, :deleted, :boolean, default: false
  end
end
