class CreateStockTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_transfers do |t|
      t.string :transfer_number, null: false

      t.references :from_warehouse, null: false, foreign_key: { to_table: :warehouses }
      t.references :to_warehouse, null: false, foreign_key: { to_table: :warehouses }

      t.string :status, limit: 20, null: false, default: "DRAFT"

      t.references :requested_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.references :created_by,  foreign_key: { to_table: :users }

      t.text :note
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end

    add_index :stock_transfers, :transfer_number, unique: true
  end
end
