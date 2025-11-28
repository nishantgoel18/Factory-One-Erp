class CreateStockBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_batches do |t|
      t.references :product, null: false, foreign_key: true
      t.string :batch_number
      t.date :manufacture_date
      t.date :expiry_date
      t.text :note
      t.boolean :is_active, default: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.boolean :deleted, default: false

      t.timestamps
    end
  end
end
