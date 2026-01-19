class CreateSalesOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_orders do |t|
      t.integer :organization_id

      t.timestamps
    end
    add_index :sales_orders, :organization_id
  end
end
