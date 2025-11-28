class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :code
      t.string :full_name
      t.string :email
      t.string :phone_number
      t.text :billing_address
      t.text :shipping_address
      t.boolean :is_active, default: false
      t.integer :created_by_id
      t.boolean :deleted, default: false

      t.timestamps
    end
    add_index :customers, :created_by_id
  end
end
