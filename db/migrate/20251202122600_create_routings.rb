class CreateRoutings < ActiveRecord::Migration[8.1]
  def change
    create_table :routings do |t|
      # Basic Info
      t.string :code, null: false, limit: 20
      t.string :name, null: false, limit: 100
      t.text :description
      
      # Product Association
      t.references :product, foreign_key: true, null: false
      
      # Version Control
      t.string :revision, limit: 16, default: "1"
      
      # Status Management
      t.string :status, null: false, limit: 20, default: "DRAFT"
      # Status: DRAFT, ACTIVE, INACTIVE, ARCHIVED
      
      # Default Routing Flag
      t.boolean :is_default, default: false
      
      # Effective Date Range
      t.date :effective_from, null: false
      t.date :effective_to
      
      # Auto-calculated totals (from operations)
      t.decimal :total_setup_time_minutes, precision: 10, scale: 2, default: 0.0
      t.decimal :total_run_time_per_unit_minutes, precision: 10, scale: 2, default: 0.0
      t.decimal :total_labor_cost_per_unit, precision: 12, scale: 2, default: 0.0
      t.decimal :total_overhead_cost_per_unit, precision: 12, scale: 2, default: 0.0
      
      # Notes
      t.text :notes
      
      # Soft Delete
      t.boolean :deleted, default: false
      
      # Audit fields
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      
      t.timestamps
    end
    
    # Indexes
    add_index :routings, :code, unique: true
    add_index :routings, :status
    add_index :routings, [:product_id, :is_default]
    add_index :routings, [:product_id, :status]
    add_index :routings, [:effective_from, :effective_to]
  end
end
