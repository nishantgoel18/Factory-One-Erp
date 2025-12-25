class AddDeletedToSupplierContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :supplier_contacts, :deleted, :boolean, default: false
  end
end
