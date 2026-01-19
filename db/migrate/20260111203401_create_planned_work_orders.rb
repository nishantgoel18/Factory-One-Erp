class CreatePlannedWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :planned_work_orders do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :mrp_run, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.references :bom, foreign_key: { to_table: :bill_of_materials }
      t.references :routing, foreign_key: true
      t.references :uom, foreign_key: { to_table: :unit_of_measures }
      
      # Workflow references
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.references :production_planner, foreign_key: { to_table: :users }
      
      # Conversion tracking
      t.references :work_order, foreign_key: true
      
      # ========================================
      # PLANNED ORDER IDENTIFICATION
      # ========================================
      t.string :planned_wo_number, limit: 50, null: false
      t.string :reference_number, limit: 100
      
      # ========================================
      # QUANTITIES
      # ========================================
      t.decimal :required_quantity, precision: 14, scale: 4, null: false
      t.decimal :suggested_production_quantity, precision: 14, scale: 4, null: false
      # (May be different due to lot sizing, scrap allowance, etc.)
      
      t.decimal :minimum_production_quantity, precision: 14, scale: 4
      t.decimal :scrap_allowance_percent, precision: 5, scale: 2, default: 0.0
      t.decimal :quantity_with_scrap, precision: 14, scale: 4
      
      # ========================================
      # DATES & SCHEDULING
      # ========================================
      t.date :required_completion_date, null: false  # When we need finished goods
      t.date :suggested_start_date, null: false  # When to start production
      t.date :suggested_release_date  # When to release to shop floor
      
      t.integer :lead_time_days  # Manufacturing lead time used
      t.integer :routing_lead_time_days  # From routing calculation
      
      # ========================================
      # WORK CENTER ASSIGNMENT
      # ========================================
      t.references :primary_work_center, foreign_key: { to_table: :work_centers }
      t.boolean :work_center_pre_assigned, default: false
      
      # ========================================
      # COST ESTIMATION
      # ========================================
      t.decimal :estimated_material_cost, precision: 15, scale: 2
      t.decimal :estimated_labor_cost, precision: 15, scale: 2
      t.decimal :estimated_overhead_cost, precision: 15, scale: 2
      t.decimal :estimated_total_cost, precision: 15, scale: 2
      
      t.string :currency, limit: 3, default: 'USD'
      
      # ========================================
      # DURATION ESTIMATES
      # ========================================
      t.integer :estimated_duration_minutes  # Total production time
      t.integer :estimated_setup_minutes
      t.integer :estimated_run_minutes
      
      # ========================================
      # SOURCE OF DEMAND (Pegging)
      # ========================================
      t.string :demand_source_type, limit: 50
      # Options: 'SALES_ORDER', 'FORECAST', 'SAFETY_STOCK', 'REORDER_POINT', 'PARENT_WORK_ORDER'
      
      t.bigint :demand_source_id
      t.string :demand_source_reference
      
      # For traceability
      t.references :sales_order, foreign_key: { to_table: :sales_orders }
      t.references :sales_forecast, foreign_key: true
      t.references :parent_work_order, foreign_key: { to_table: :work_orders }
      t.references :parent_planned_wo, foreign_key: { to_table: :planned_work_orders }
      
      # ========================================
      # BOM & ROUTING INFO
      # ========================================
      t.string :bom_code, limit: 50
      t.string :bom_revision, limit: 20
      t.string :routing_code, limit: 50
      t.string :routing_revision, limit: 20
      
      t.integer :bom_level, default: 0  # 0 = top level, 1 = component, etc.
      t.integer :low_level_code, default: 0
      
      # ========================================
      # STATUS & WORKFLOW
      # ========================================
      t.string :status, limit: 30, default: 'SUGGESTED', null: false
      # Workflow: SUGGESTED → UNDER_REVIEW → APPROVED → CONVERTED_TO_WO → CANCELLED → EXPIRED
      
      t.string :substatus, limit: 50
      
      # ========================================
      # PRIORITY
      # ========================================
      t.string :priority, limit: 20, default: 'NORMAL'
      # Options: 'CRITICAL', 'HIGH', 'NORMAL', 'LOW'
      
      t.integer :priority_score  # Numeric score (1-100)
      
      # ========================================
      # DATES FOR WORKFLOW
      # ========================================
      t.datetime :reviewed_at
      t.datetime :approved_at
      t.datetime :converted_at
      t.datetime :cancelled_at
      t.datetime :expired_at
      
      # ========================================
      # CONVERSION TRACKING
      # ========================================
      t.string :conversion_status, limit: 30
      # 'NOT_CONVERTED', 'WO_CREATED', 'PARTIAL_CONVERSION'
      
      t.decimal :converted_quantity, precision: 14, scale: 4, default: 0.0
      t.decimal :remaining_quantity, precision: 14, scale: 4
      
      # ========================================
      # EXCEPTION HANDLING
      # ========================================
      t.boolean :has_exceptions, default: false
      t.string :exception_type, limit: 50
      # 'NO_BOM', 'NO_ROUTING', 'CAPACITY_OVERLOAD', 'MATERIAL_SHORTAGE', 'LEAD_TIME_ISSUE'
      
      t.text :exception_message
      
      # ========================================
      # ACTION MESSAGES
      # ========================================
      t.boolean :has_action_message, default: false
      t.string :action_type, limit: 30
      # 'EXPEDITE', 'DELAY', 'INCREASE_QTY', 'DECREASE_QTY', 'CANCEL', 'SPLIT'
      
      t.date :action_new_start_date
      t.date :action_new_completion_date
      t.decimal :action_new_quantity, precision: 14, scale: 4
      
      # ========================================
      # PLANNING DATA
      # ========================================
      t.string :lot_sizing_rule_applied, limit: 30
      t.decimal :gross_requirement, precision: 14, scale: 4
      t.decimal :net_requirement, precision: 14, scale: 4
      
      # ========================================
      # CAPACITY PLANNING
      # ========================================
      t.decimal :total_capacity_hours_required, precision: 10, scale: 2
      t.boolean :capacity_available, default: true
      t.text :capacity_constraints
      
      # ========================================
      # MATERIAL AVAILABILITY
      # ========================================
      t.boolean :materials_available, default: true
      t.integer :missing_materials_count, default: 0
      t.text :material_shortages  # JSON or text list
      
      # ========================================
      # COMPONENT REQUIREMENTS
      # ========================================
      t.integer :components_count, default: 0
      t.decimal :total_component_cost, precision: 15, scale: 2
      
      # ========================================
      # MAKE OR BUY DECISION
      # ========================================
      t.string :make_or_buy_decision, limit: 20, default: 'MAKE'
      # Could be 'MAKE', 'BUY', 'OUTSOURCE'
      
      # ========================================
      # CUSTOMER INFO (if direct customer order)
      # ========================================
      t.references :customer, foreign_key: true
      t.string :customer_po_number, limit: 100
      
      # ========================================
      # NOTES
      # ========================================
      t.text :notes
      t.text :internal_notes
      t.text :production_notes
      t.text :cancellation_reason
      
      # ========================================
      # CONFIRMATION
      # ========================================
      t.boolean :confirmed_by_planner, default: false
      t.datetime :confirmed_at
      
      # ========================================
      # METADATA
      # ========================================
      t.jsonb :calculation_details, default: {}
      t.jsonb :bom_explosion_details, default: {}
      t.jsonb :routing_details, default: {}
      t.jsonb :metadata, default: {}
      
      # ========================================
      # SYSTEM FLAGS
      # ========================================
      t.boolean :is_firmed, default: false  # Manual override
      t.boolean :is_system_generated, default: true
      t.boolean :is_rush_order, default: false
      t.boolean :requires_special_tooling, default: false
      
      # ========================================
      # EXPIRATION
      # ========================================
      t.date :valid_until
      t.boolean :auto_expired, default: false
      
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # ========================================
    # INDEXES
    # ========================================
    add_index :planned_work_orders, :planned_wo_number, unique: true
    add_index :planned_work_orders, [:organization_id, :status]
    add_index :planned_work_orders, [:organization_id, :required_completion_date]
    add_index :planned_work_orders, [:organization_id, :suggested_start_date]
    add_index :planned_work_orders, [:product_id, :status]
    add_index :planned_work_orders, :priority
    add_index :planned_work_orders, :has_exceptions
    add_index :planned_work_orders, :has_action_message
    add_index :planned_work_orders, :materials_available
    add_index :planned_work_orders, :capacity_available
    add_index :planned_work_orders, :is_firmed
    add_index :planned_work_orders, [:production_planner_id, :status]
    add_index :planned_work_orders, [:mrp_run_id, :status]
    add_index :planned_work_orders, [:primary_work_center_id, :status]
    add_index :planned_work_orders, :bom_level
    add_index :planned_work_orders, :deleted
    add_index :planned_work_orders, [:demand_source_type, :demand_source_id]
  end
end
