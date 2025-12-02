class CreateCycleCounts < ActiveRecord::Migration[8.1]
  def change
    # ===================================
    # CYCLE COUNT HEADER
    # ===================================
    create_table :cycle_counts do |t|
      # Reference & Status
      t.string :reference_no, null: false, limit: 50
      t.string :status, default: 'SCHEDULED', null: false, limit: 20
      
      # Warehouse reference
      t.references :warehouse, null: false, foreign_key: true
      
      # Scheduling & Counting
      t.datetime :scheduled_at, null: false
      t.datetime :count_started_at
      t.datetime :count_completed_at
      t.datetime :posted_at
      
      # User tracking
      t.references :scheduled_by, foreign_key: { to_table: :users }, null: true
      t.references :counted_by, foreign_key: { to_table: :users }, null: true
      t.references :posted_by, foreign_key: { to_table: :users }, null: true
      
      # Count type (optional categorization)
      t.string :count_type, limit: 30  # e.g., "FULL", "PARTIAL", "ABC_A", "SPOT_CHECK"
      
      # Notes
      t.text :notes
      
      # Summary stats (can be computed, but storing for quick access)
      t.integer :total_lines_count, default: 0
      t.integer :lines_with_variance_count, default: 0
      
      # Soft delete
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :cycle_counts, :reference_no, unique: true
    add_index :cycle_counts, :status
    add_index :cycle_counts, [:warehouse_id, :status]
    add_index :cycle_counts, :scheduled_at
  end
end
