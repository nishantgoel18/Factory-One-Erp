class CreatePlannedPurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :planned_purchase_orders do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :mrp_run, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.references :supplier, foreign_key: true, index: true  # Suggested vendor
      t.references :uom, foreign_key: { to_table: :unit_of_measures }
      
      # Workflow references
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      
      # Conversion tracking
      t.references :purchase_order
      t.references :rfq, foreign_key: true
      
      # ========================================
      # PLANNED ORDER IDENTIFICATION
      # ========================================
      t.string :planned_po_number, limit: 50, null: false
      t.string :reference_number, limit: 100  # User reference
      
      # ========================================
      # QUANTITIES
      # ========================================
      t.decimal :required_quantity, precision: 14, scale: 4, null: false
      t.decimal :suggested_order_quantity, precision: 14, scale: 4, null: false
      # (May be different due to MOQ, lot sizing, etc.)
      
      t.decimal :minimum_order_quantity, precision: 14, scale: 4
      t.decimal :order_multiple, precision: 14, scale: 4
      
      # ========================================
      # DATES
      # ========================================
      t.date :required_date, null: false  # Need-by date (when we need material)
      t.date :suggested_order_date, null: false  # When to place order (req date - lead time)
      t.date :expected_receipt_date  # When supplier will deliver
      
      t.integer :lead_time_days  # Lead time used in calculation
      
      # ========================================
      # COST ESTIMATION
      # ========================================
      t.decimal :estimated_unit_cost, precision: 12, scale: 2
      t.decimal :estimated_total_cost, precision: 15, scale: 2
      t.string :currency, limit: 3, default: 'USD'
      
      # ========================================
      # SOURCE OF DEMAND (Pegging)
      # ========================================
      t.string :demand_source_type, limit: 50
      # Options: 'SALES_ORDER', 'FORECAST', 'SAFETY_STOCK', 'REORDER_POINT', 'WORK_ORDER'
      
      t.bigint :demand_source_id  # Polymorphic reference
      t.string :demand_source_reference  # SO-123, FC-456, etc.
      
      # For traceability
      t.references :sales_order, foreign_key: { to_table: :sales_orders }
      t.references :sales_forecast, foreign_key: true
      t.references :work_order, foreign_key: true  # If this is for a WO component
      
      # ========================================
      # SUPPLIER SELECTION
      # ========================================
      t.string :supplier_selection_method, limit: 50
      # 'PRIMARY_SUPPLIER', 'LOWEST_COST', 'FASTEST_DELIVERY', 'BEST_QUALITY', 'MANUAL'
      
      t.text :supplier_selection_notes
      
      # ========================================
      # STATUS & WORKFLOW
      # ========================================
      t.string :status, limit: 30, default: 'SUGGESTED', null: false
      # Workflow: SUGGESTED → UNDER_REVIEW → RFQ_SENT → QUOTES_RECEIVED → 
      #           APPROVED → CONVERTED_TO_PO → CANCELLED → EXPIRED
      
      t.string :substatus, limit: 50  # Additional status detail
      
      # ========================================
      # PRIORITY
      # ========================================
      t.string :priority, limit: 20, default: 'NORMAL'
      # Options: 'CRITICAL', 'HIGH', 'NORMAL', 'LOW'
      
      t.integer :priority_score  # Numeric score for sorting (1-100)
      
      # ========================================
      # DATES FOR WORKFLOW
      # ========================================
      t.datetime :reviewed_at
      t.datetime :rfq_sent_at
      t.datetime :quotes_received_at
      t.datetime :approved_at
      t.datetime :converted_at
      t.datetime :cancelled_at
      t.datetime :expired_at
      
      # ========================================
      # CONVERSION TRACKING
      # ========================================
      t.string :conversion_status, limit: 30
      # 'NOT_CONVERTED', 'RFQ_CREATED', 'PO_CREATED', 'PARTIAL_CONVERSION'
      
      t.decimal :converted_quantity, precision: 14, scale: 4, default: 0.0
      t.decimal :remaining_quantity, precision: 14, scale: 4
      
      # ========================================
      # EXCEPTION HANDLING
      # ========================================
      t.boolean :has_exceptions, default: false
      t.string :exception_type, limit: 50
      # 'NO_SUPPLIER', 'LEAD_TIME_ISSUE', 'CAPACITY_ISSUE', 'COST_ISSUE'
      
      t.text :exception_message
      
      # ========================================
      # ACTION MESSAGES
      # ========================================
      t.boolean :has_action_message, default: false
      t.string :action_type, limit: 30
      # 'EXPEDITE', 'DELAY', 'INCREASE_QTY', 'DECREASE_QTY', 'CANCEL', 'SPLIT'
      
      t.date :action_new_date  # If date change recommended
      t.decimal :action_new_quantity, precision: 14, scale: 4  # If qty change recommended
      
      # ========================================
      # PLANNING DATA
      # ========================================
      t.string :lot_sizing_rule_applied, limit: 30
      t.decimal :gross_requirement, precision: 14, scale: 4  # Before adjustments
      t.decimal :net_requirement, precision: 14, scale: 4  # After considering inventory
      
      # Low-level code (for BOM explosion order)
      t.integer :low_level_code, default: 0
      
      # ========================================
      # BUYER ASSIGNMENT
      # ========================================
      t.references :buyer_assigned, foreign_key: { to_table: :users }
      t.datetime :assigned_at
      
      # ========================================
      # NOTES & ATTACHMENTS
      # ========================================
      t.text :notes
      t.text :internal_notes
      t.text :supplier_notes
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
      # Store detailed calculation breakdown for transparency
      
      t.jsonb :metadata, default: {}
      
      # ========================================
      # SYSTEM FLAGS
      # ========================================
      t.boolean :is_firmed, default: false  # Manual override - don't change in next MRP run
      t.boolean :is_system_generated, default: true
      t.boolean :is_rush_order, default: false
      t.boolean :is_blanket_order, default: false
      
      # ========================================
      # EXPIRATION
      # ========================================
      t.date :valid_until  # Auto-expire after this date
      t.boolean :auto_expired, default: false
      
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # ========================================
    # INDEXES
    # ========================================
    add_index :planned_purchase_orders, :planned_po_number, unique: true
    add_index :planned_purchase_orders, [:organization_id, :status]
    add_index :planned_purchase_orders, [:organization_id, :required_date]
    add_index :planned_purchase_orders, [:organization_id, :suggested_order_date]
    add_index :planned_purchase_orders, [:product_id, :status]
    add_index :planned_purchase_orders, [:supplier_id, :status]
    add_index :planned_purchase_orders, :priority
    add_index :planned_purchase_orders, :has_exceptions
    add_index :planned_purchase_orders, :has_action_message
    add_index :planned_purchase_orders, :is_firmed
    add_index :planned_purchase_orders, [:buyer_assigned_id, :status]
    add_index :planned_purchase_orders, [:mrp_run_id, :status]
    add_index :planned_purchase_orders, :deleted
    add_index :planned_purchase_orders, [:demand_source_type, :demand_source_id]
  end
end
