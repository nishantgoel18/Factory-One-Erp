class CreateCycleCountLines < ActiveRecord::Migration[8.1]
  def change
    # ===================================
    # CYCLE COUNT LINE
    # ===================================
    create_table :cycle_count_lines do |t|
      # Parent cycle count
      t.references :cycle_count, null: false, foreign_key: true
      
      # Product being counted
      t.references :product, null: false, foreign_key: true
      
      # Batch (nullable - only if product is batch tracked)
      t.references :batch, foreign_key: { to_table: :stock_batches }, null: true
      
      # Location being counted
      t.references :location, null: false, foreign_key: true
      
      # Unit of Measure
      t.references :uom, null: false, foreign_key: { to_table: :unit_of_measures }
      
      # System quantity (expected quantity from system at count time)
      t.decimal :system_qty, precision: 14, scale: 4, default: 0.0
      
      # Counted quantity (actual physical count)
      t.decimal :counted_qty, precision: 14, scale: 4
      
      # Variance (counted - system) - computed but stored
      t.decimal :variance, precision: 14, scale: 4
      
      # Status for this line
      t.string :line_status, default: 'PENDING', limit: 20  # PENDING, COUNTED, ADJUSTED
      
      # Line-level notes (for explaining variances)
      t.text :line_note
      
      # Soft delete
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :cycle_count_lines, [:cycle_count_id, :product_id]
    add_index :cycle_count_lines, :line_status
  end
end
