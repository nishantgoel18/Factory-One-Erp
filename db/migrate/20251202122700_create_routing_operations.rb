class CreateRoutingOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :routing_operations do |t|
      # Parent Routing
      t.references :routing, foreign_key: true, null: false
      
      # Sequence & Identity
      t.integer :operation_sequence, null: false
      # Like 10, 20, 30... allows inserting between steps
      
      t.string :operation_name, null: false, limit: 100
      # e.g., "Cutting", "Drilling", "Welding"
      
      t.text :description
      
      # Work Center
      t.references :work_center, foreign_key: true, null: false
      
      # Time Settings (in minutes)
      t.decimal :setup_time_minutes, precision: 10, scale: 2, default: 0.0
      t.decimal :run_time_per_unit_minutes, precision: 10, scale: 2, default: 0.0
      t.decimal :wait_time_minutes, precision: 10, scale: 2, default: 0.0
      # Wait time = waiting for next operation
      
      t.decimal :move_time_minutes, precision: 10, scale: 2, default: 0.0
      # Move time = time to transport to next work center
      
      # Labor Requirements
      t.decimal :labor_hours_per_unit, precision: 8, scale: 4, default: 0.0
      # Sometimes != run_time (e.g., one operator handles multiple machines)
      
      # Quality Control
      t.boolean :is_quality_check_required, default: false
      t.text :quality_check_instructions
      
      # Cost Tracking (auto-calculated from work center)
      t.decimal :labor_cost_per_unit, precision: 12, scale: 2, default: 0.0
      t.decimal :overhead_cost_per_unit, precision: 12, scale: 2, default: 0.0
      
      # Operation Notes
      t.text :notes
      
      # Soft Delete
      t.boolean :deleted, default: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :routing_operations, [:routing_id, :operation_sequence], 
              name: 'index_routing_ops_on_routing_and_seq'
    add_index :routing_operations, [:routing_id, :deleted]
  end
end
