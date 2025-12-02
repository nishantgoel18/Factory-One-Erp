class CreateStockTransferLines < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_transfer_lines do |t|
      t.references :stock_transfer, null: false, foreign_key: true

      t.references :product, null: false, foreign_key: true

      # UnitOfMeasure
      t.references :uom, null: false, foreign_key: { to_table: :unit_of_measures }

      t.references :from_location, null: false, foreign_key: { to_table: :locations }
      t.references :to_location,   null: false, foreign_key: { to_table: :locations }

      t.references :batch, foreign_key: { to_table: :stock_batches }

      t.decimal :qty, precision: 14, scale: 4, null: false, default: "0.0000"

      t.text :line_note

      t.boolean :deleted, null: false, default: false

      t.timestamps
    end

  end
end
