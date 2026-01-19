class CreateMrpRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :mrp_runs do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :run_by, null: false, foreign_key: { to_table: :users }
      
      # ========================================
      # RUN IDENTIFICATION
      # ========================================
      t.string :run_number, limit: 50, null: false
      t.string :run_name, limit: 200
      
      # ========================================
      # RUN TYPE
      # ========================================
      t.string :run_type, limit: 30, default: 'REGENERATIVE', null: false
      # Options:
      # - 'REGENERATIVE': Full recalculation (delete all planned orders and recalculate)
      # - 'NET_CHANGE': Only recalculate changed items
      # - 'SIMULATION': Test run, don't save results
      
      # ========================================
      # RUN PARAMETERS
      # ========================================
      t.date :planning_horizon_start, null: false
      t.date :planning_horizon_end, null: false
      t.integer :planning_horizon_days, null: false
      
      t.boolean :include_forecasts, default: true
      t.boolean :include_safety_stock, default: true
      t.boolean :include_reorder_points, default: true
      t.boolean :consider_on_hand_inventory, default: true
      t.boolean :consider_existing_pos, default: true
      t.boolean :consider_existing_wos, default: true
      t.boolean :consider_in_transit, default: true
      
      # Item Filters
      t.text :item_filter_criteria  # JSON string of filters applied
      t.string :abc_classes, array: true, default: []  # ['A', 'B', 'C']
      t.boolean :critical_items_only, default: false
      
      # ========================================
      # RUN STATUS
      # ========================================
      t.string :status, limit: 30, default: 'PENDING', null: false
      # Options: 'PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED', 'PARTIALLY_COMPLETED'
      
      # ========================================
      # EXECUTION TIMELINE
      # ========================================
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :duration_seconds  # Total run time
      
      # ========================================
      # PROCESSING STATISTICS
      # ========================================
      t.integer :items_to_process, default: 0
      t.integer :items_processed, default: 0
      t.integer :items_with_requirements, default: 0
      t.integer :items_skipped, default: 0
      t.integer :items_failed, default: 0
      
      # ========================================
      # OUTPUT STATISTICS
      # ========================================
      t.integer :planned_pos_generated, default: 0
      t.integer :planned_wos_generated, default: 0
      t.integer :exceptions_generated, default: 0
      t.integer :action_messages_generated, default: 0
      
      # Total planned value
      t.decimal :total_planned_po_value, precision: 15, scale: 2, default: 0.0
      t.decimal :total_planned_wo_value, precision: 15, scale: 2, default: 0.0
      
      # ========================================
      # DEMAND SUMMARY
      # ========================================
      t.integer :total_sales_orders_considered, default: 0
      t.integer :total_forecasts_considered, default: 0
      t.decimal :total_demand_quantity, precision: 14, scale: 4, default: 0.0
      
      # ========================================
      # SUPPLY SUMMARY
      # ========================================
      t.decimal :total_on_hand_inventory, precision: 14, scale: 4, default: 0.0
      t.decimal :total_on_order_qty, precision: 14, scale: 4, default: 0.0
      t.decimal :total_in_production_qty, precision: 14, scale: 4, default: 0.0
      
      # ========================================
      # BOM EXPLOSION STATS
      # ========================================
      t.integer :boms_exploded, default: 0
      t.integer :bom_levels_processed, default: 0  # How many levels deep
      t.integer :component_requirements_created, default: 0
      
      # ========================================
      # ERROR HANDLING
      # ========================================
      t.text :error_message
      t.text :error_details  # Stack trace or detailed error info
      t.jsonb :processing_errors, default: []  # Array of item-level errors
      
      # ========================================
      # EXECUTION LOG
      # ========================================
      t.jsonb :execution_log, default: []
      # Store key events during processing:
      # [
      #   { timestamp: '...', event: 'Started processing', details: '...' },
      #   { timestamp: '...', event: 'Item XYZ processed', details: '...' }
      # ]
      
      # ========================================
      # COMPARISON WITH PREVIOUS RUN
      # ========================================
      t.references :previous_run, foreign_key: { to_table: :mrp_runs }
      t.integer :new_planned_orders_vs_previous
      t.integer :cancelled_planned_orders_vs_previous
      t.integer :modified_planned_orders_vs_previous
      
      # ========================================
      # APPROVAL WORKFLOW (Optional)
      # ========================================
      t.boolean :requires_approval, default: false
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.text :approval_notes
      
      # ========================================
      # SETTINGS SNAPSHOT
      # ========================================
      t.jsonb :configuration_snapshot, default: {}
      # Store MRP settings at time of run for audit trail
      
      # ========================================
      # ADDITIONAL INFO
      # ========================================
      t.text :notes
      t.text :run_description
      t.string :tags, array: true, default: []
      
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # ========================================
    # INDEXES
    # ========================================
    add_index :mrp_runs, :run_number, unique: true
    add_index :mrp_runs, :status
    add_index :mrp_runs, :run_type
    add_index :mrp_runs, [:organization_id, :created_at], order: { created_at: :desc }
    add_index :mrp_runs, [:started_at, :completed_at]
    add_index :mrp_runs, :deleted
  end
end
