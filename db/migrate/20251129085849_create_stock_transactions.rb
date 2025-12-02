class CreateStockTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_transactions do |t|
      t.references :product, null: false, foreign_key: true

      # UnitOfMeasure
      t.references :uom, null: false, foreign_key: { to_table: :unit_of_measures }

      t.string  :txn_type, null: false, limit: 30
      t.decimal :quantity, precision: 14, scale: 4, null: false

      t.references :from_location, foreign_key: { to_table: :locations }
      t.references :to_location,   foreign_key: { to_table: :locations }

      t.references :batch, foreign_key: { to_table: :stock_batches }

      t.string :reference_type, limit: 50
      t.string :reference_id,   limit: 50
      t.text   :note

      t.references :created_by, foreign_key: { to_table: :users }

      t.boolean :deleted, null: false, default: false

      t.timestamps
    end

    add_index :stock_transactions, [:product_id, :txn_type]
  end
end
