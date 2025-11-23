class CreateWarehouses < ActiveRecord::Migration[8.1]
  def change
    create_table :warehouses do |t|
      t.string :name
      t.string :code
      t.text :address
      t.boolean :is_active
      t.boolean :deleted

      t.timestamps
    end
  end
end
