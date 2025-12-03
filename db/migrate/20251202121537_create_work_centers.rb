class CreateWorkCenters < ActiveRecord::Migration[8.1]
  def change
    create_table :work_centers do |t|
      # Basic Info
      t.string :code, null: false, limit: 20
      t.string :name, null: false, limit: 100
      t.text :description
      
      # Work Center Type
      t.string :work_center_type, null: false, limit: 30
      # Types: MACHINE, ASSEMBLY, QUALITY_CHECK, PACKING, FINISHING, PAINTING, WELDING, etc.
      
      # Location & Warehouse
      t.references :location, foreign_key: true, null: true
      t.references :warehouse, foreign_key: true, null: true
      
      # Capacity & Performance
      t.decimal :capacity_per_hour, precision: 10, scale: 2, default: 0.0
      # Kitni units per hour process kar sakta hai
      
      t.integer :efficiency_percent, default: 100
      # Machine ki actual efficiency (100% = perfect, 85% = some downtime)
      
      # Cost Information
      t.decimal :labor_cost_per_hour, precision: 10, scale: 2, default: 0.0
      t.decimal :overhead_cost_per_hour, precision: 10, scale: 2, default: 0.0
      # Overhead includes: electricity, maintenance, depreciation
      
      # Scheduling Info
      t.integer :setup_time_minutes, default: 0
      # Default setup time for this work center
      
      t.integer :queue_time_minutes, default: 0
      # Average waiting time before work starts
      
      # Status & Tracking
      t.boolean :is_active, default: true
      t.boolean :deleted, default: false
      
      # Notes
      t.text :notes
      
      # Audit fields
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      
      t.timestamps
    end
    
    # Indexes for performance
    add_index :work_centers, :code, unique: true
    add_index :work_centers, :work_center_type
    add_index :work_centers, :is_active
    add_index :work_centers, [:warehouse_id, :is_active]
  end
end
