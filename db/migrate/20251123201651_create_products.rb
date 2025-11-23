class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :sku
      t.string :name
      t.integer :product_category_id
      t.integer :unit_of_measure_id
      t.boolean :is_batch_tracked
      t.boolean :is_serial_tracked
      t.decimal :reorder_point
      t.boolean :is_active
      t.boolean :deleted

      t.timestamps
    end
    add_index :products, :product_category_id
    add_index :products, :unit_of_measure_id
  end
end
