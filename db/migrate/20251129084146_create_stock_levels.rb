class CreateStockLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_levels do |t|
      t.references :product, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true

      # batch belongs to StockBatch model
      t.references :batch, foreign_key: { to_table: :stock_batches }

      # quantities as decimals, with defaults
      t.decimal :on_hand_qty, precision: 20, scale: 6, default: "0.0", null: false
      t.decimal :reserved_qty, precision: 20, scale: 6, default: "0.0", null: false

      t.boolean :deleted, default: false, null: false

      t.timestamps
    end

    # Optional but VERY useful based on your find_or_create_by(product, location, batch)
    add_index :stock_levels,
              [:product_id, :location_id, :batch_id],
              unique: true,
              name: "index_stock_levels_on_product_location_batch"
  end
end
