class CreateStockAdjustmentLines < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_adjustment_lines do |t|
      # Parent adjustment
      t.references :stock_adjustment, null: false, foreign_key: true
      
      # Product being adjusted
      t.references :product, null: false, foreign_key: true
      
      # Batch (nullable - only if product is batch tracked)
      t.references :batch, foreign_key: { to_table: :stock_batches }, null: true
      
      # Location where adjustment happens
      t.references :location, null: false, foreign_key: true
      
      # Unit of Measure
      t.references :uom, null: false, foreign_key: { to_table: :unit_of_measures }
      
      # Quantity delta (positive = increase, negative = decrease)
      # This is the KEY field - can be + or -
      t.decimal :qty_delta, precision: 14, scale: 4, null: false, default: 0.0
      
      # Optional: Current system qty for reference
      t.decimal :system_qty_at_adjustment, precision: 14, scale: 4
      
      # Optional: Reason for this specific line
      t.text :line_reason
      
      # Line-level notes
      t.text :line_note
      
      # Soft delete
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :stock_adjustment_lines, [:stock_adjustment_id, :product_id]
  end
end
