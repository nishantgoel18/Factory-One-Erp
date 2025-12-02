class CreateGoodReceiptLines < ActiveRecord::Migration[8.1]
  def change
    create_table :goods_receipt_lines do |t|
      # Parent GRN
      t.references :goods_receipt, null: false, foreign_key: true
      
      # Product being received
      t.references :product, null: false, foreign_key: true
      
      # Batch (nullable - only if product is batch tracked)
      t.references :batch, foreign_key: { to_table: :stock_batches }, null: true
      
      # Receiving Location (must be receivable)
      t.references :location, null: false, foreign_key: true
      
      # Unit of Measure
      t.references :uom, null: false, foreign_key: { to_table: :unit_of_measures }
      
      # Quantity received
      t.decimal :qty, precision: 14, scale: 4, null: false, default: 0.0
      
      # Optional: Unit cost (for costing purposes)
      t.decimal :unit_cost, precision: 15, scale: 4, null: true
      
      # Line-level notes
      t.text :line_note
      
      # Soft delete
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes for performance
    add_index :goods_receipt_lines, [:goods_receipt_id, :product_id]
    add_index :goods_receipt_lines, :batch_id
  end
end
