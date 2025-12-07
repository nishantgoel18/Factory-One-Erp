# db/migrate/20251203XXXXXX_create_work_order_operations.rb

class CreateWorkOrderOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :work_order_operations do |t|
      # Parent Reference
      t.references :work_order, null: false, foreign_key: true
      
      # Routing Reference (which operation from routing this is)
      t.references :routing_operation, null: false, foreign_key: true
      
      # Work Center (where this operation happens)
      t.references :work_center, null: false, foreign_key: true
      
      # Operation Details
      t.integer    :sequence_no, null: false  # 10, 20, 30... for ordering
      t.string     :operation_name, limit: 100, null: false
      t.text       :operation_description
      
      # Status
      t.string     :status, limit: 20, default: 'PENDING', null: false
      # PENDING → IN_PROGRESS → COMPLETED (or SKIPPED)
      
      # Quantities
      t.decimal    :quantity_to_process, precision: 14, scale: 4, null: false
      t.decimal    :quantity_completed, precision: 14, scale: 4, default: 0.0
      t.decimal    :quantity_scrapped, precision: 14, scale: 4, default: 0.0
      
      # Planned Time (copied from routing_operation)
      t.integer    :planned_setup_minutes, default: 0
      t.decimal    :planned_run_minutes_per_unit, precision: 10, scale: 2, default: 0.0
      t.integer    :planned_total_minutes, default: 0  # setup + (run_per_unit × qty)
      
      # Actual Time (recorded during execution)
      t.integer    :actual_setup_minutes, default: 0
      t.integer    :actual_run_minutes, default: 0
      t.integer    :actual_total_minutes, default: 0
      
      # Costs
      t.decimal    :planned_cost, precision: 12, scale: 2, default: 0.0
      t.decimal    :actual_cost, precision: 12, scale: 2, default: 0.0
      
      # Execution Tracking
      t.datetime   :started_at
      t.datetime   :completed_at
      t.references :operator, foreign_key: { to_table: :users } # Who performed this
      
      # Notes
      t.text       :notes
      
      # Soft Delete
      t.boolean    :deleted, default: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :work_order_operations, [:work_order_id, :sequence_no]
    add_index :work_order_operations, :status
    add_index :work_order_operations, [:work_center_id, :status]
    add_index :work_order_operations, :deleted
  end
end
