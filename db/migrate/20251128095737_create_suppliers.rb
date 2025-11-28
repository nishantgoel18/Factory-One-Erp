class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :code
      t.string :name
      t.string :email
      t.string :phone
      t.text :billing_address
      t.text :shipping_address
      t.integer :lead_time_days
      t.decimal :on_time_delivery_rate, precision: 5, scale: 2, default: 100.00
      t.boolean :is_active
      t.boolean :deleted
      t.integer :created_by

      t.timestamps
    end
  end
end
