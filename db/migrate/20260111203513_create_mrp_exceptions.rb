class CreateMrpExceptions < ActiveRecord::Migration[8.1]
  def change
    create_table :mrp_exceptions do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :mrp_run, null: false, foreign_key: true, index: true
      t.references :product, foreign_key: true, index: true
      
      # Related entities (polymorphic)
      t.references :related_planned_po, foreign_key: { to_table: :planned_purchase_orders }
      t.references :related_planned_wo, foreign_key: { to_table: :planned_work_orders }
      t.references :related_purchase_order, foreign_key: { to_table: :purchase_orders }
      t.references :related_work_order, foreign_key: {to_table: :work_orders}
      
      # Assignment
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :resolved_by, foreign_key: { to_table: :users }
      
      # ========================================
      # EXCEPTION IDENTIFICATION
      # ========================================
      t.string :exception_number, limit: 50, null: false
      
      # ========================================
      # EXCEPTION TYPE
      # ========================================
      t.string :exception_type, limit: 50, null: false
      # Critical types:
      # - 'SHORTAGE': Insufficient supply for demand
      # - 'EXCESS_INVENTORY': Projected inventory > maximum
      # - 'PAST_DUE_PO': Existing PO past due date
      # - 'PAST_DUE_WO': Existing WO past due date
      # - 'CAPACITY_OVERLOAD': Work center over capacity
      # - 'INVALID_BOM': Missing or inactive BOM
      # - 'MISSING_VENDOR': No vendor assigned
      # - 'LEAD_TIME_BREACH': Cannot meet required date
      # - 'MATERIAL_SHORTAGE': Component not available
      # - 'NO_ROUTING': Missing routing for manufactured item
      # - 'QUALITY_HOLD': Inventory on quality hold
      # - 'NEGATIVE_INVENTORY': Projected negative stock
      # - 'LOT_SIZE_VIOLATION': Cannot meet lot sizing rules
      # - 'PLANNING_PARAMETER_MISSING': Missing planning data
      
      t.string :exception_category, limit: 30
      # Categories: 'SUPPLY', 'DEMAND', 'CAPACITY', 'DATA', 'SYSTEM'
      
      # ========================================
      # SEVERITY
      # ========================================
      t.string :severity, limit: 20, default: 'MEDIUM', null: false
      # Options: 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'
      
      t.integer :severity_score, default: 50  # 1-100 for sorting
      
      # ========================================
      # EXCEPTION DETAILS
      # ========================================
      t.text :exception_message, null: false
      t.text :detailed_description
      t.text :impact_analysis
      
      # ========================================
      # EXCEPTION DATE & TIME
      # ========================================
      t.date :exception_date  # Date when problem occurs
      t.datetime :detected_at, null: false
      
      # ========================================
      # QUANTITIES (if applicable)
      # ========================================
      t.decimal :shortage_quantity, precision: 14, scale: 4
      t.decimal :excess_quantity, precision: 14, scale: 4
      t.decimal :required_quantity, precision: 14, scale: 4
      t.decimal :available_quantity, precision: 14, scale: 4
      
      # ========================================
      # DATES (if applicable)
      # ========================================
      t.date :required_date
      t.date :current_date
      t.integer :days_late
      t.integer :days_early
      
      # ========================================
      # RECOMMENDED ACTION
      # ========================================
      t.text :recommended_action
      t.string :action_required, limit: 50
      # 'EXPEDITE_ORDER', 'CREATE_PO', 'CREATE_WO', 'ADJUST_SCHEDULE', 
      # 'UPDATE_PARAMETERS', 'MANUAL_REVIEW', 'NO_ACTION'
      
      # ========================================
      # STATUS
      # ========================================
      t.string :status, limit: 30, default: 'OPEN', null: false
      # Options: 'OPEN', 'ACKNOWLEDGED', 'IN_PROGRESS', 'RESOLVED', 'IGNORED', 'CLOSED'
      
      # ========================================
      # WORKFLOW DATES
      # ========================================
      t.datetime :acknowledged_at
      t.datetime :assigned_at
      t.datetime :resolved_at
      t.datetime :closed_at
      
      # ========================================
      # RESOLUTION
      # ========================================
      t.text :resolution_notes
      t.text :resolution_action_taken
      t.string :resolution_type, limit: 50
      # 'AUTO_RESOLVED', 'MANUAL_ACTION', 'ORDER_PLACED', 'SCHEDULE_CHANGED', 
      # 'DATA_CORRECTED', 'ACCEPTED_AS_IS'
      
      # ========================================
      # RECURRENCE TRACKING
      # ========================================
      t.boolean :is_recurring, default: false
      t.integer :occurrence_count, default: 1
      t.references :related_exception, foreign_key: { to_table: :mrp_exceptions }
      t.date :first_occurrence_date
      t.date :last_occurrence_date
      
      # ========================================
      # PRIORITY & URGENCY
      # ========================================
      t.string :priority, limit: 20, default: 'NORMAL'
      # 'CRITICAL', 'HIGH', 'NORMAL', 'LOW'
      
      t.boolean :requires_immediate_action, default: false
      t.date :action_required_by  # Deadline
      
      # ========================================
      # FINANCIAL IMPACT
      # ========================================
      t.decimal :estimated_cost_impact, precision: 15, scale: 2
      t.decimal :estimated_revenue_risk, precision: 15, scale: 2
      t.string :currency, limit: 3, default: 'USD'
      
      # ========================================
      # NOTIFICATION
      # ========================================
      t.boolean :notification_sent, default: false
      t.datetime :notification_sent_at
      t.string :notification_recipients, array: true, default: []
      
      # ========================================
      # ALERTS
      # ========================================
      t.boolean :create_alert, default: false
      t.boolean :send_email, default: false
      t.boolean :send_sms, default: false
      
      # ========================================
      # RELATED CUSTOMER (if applicable)
      # ========================================
      t.references :customer, foreign_key: true
      t.string :customer_impact, limit: 50
      # 'ORDER_DELAY', 'PARTIAL_FULFILLMENT', 'CANCELLATION_RISK', 'NO_IMPACT'
      
      # ========================================
      # METADATA
      # ========================================
      t.jsonb :exception_data, default: {}
      # Store detailed calculation data, snapshots, etc.
      
      t.jsonb :metadata, default: {}
      
      # ========================================
      # AUDIT TRAIL
      # ========================================
      t.text :comments
      t.string :tags, array: true, default: []
      
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # ========================================
    # INDEXES
    # ========================================
    add_index :mrp_exceptions, :exception_number, unique: true
    add_index :mrp_exceptions, [:organization_id, :status]
    add_index :mrp_exceptions, [:organization_id, :severity]
    add_index :mrp_exceptions, [:mrp_run_id, :exception_type]
    add_index :mrp_exceptions, [:product_id, :status]
    add_index :mrp_exceptions, :exception_type
    add_index :mrp_exceptions, :severity
    add_index :mrp_exceptions, :status
    add_index :mrp_exceptions, [:assigned_to_id, :status]
    add_index :mrp_exceptions, :exception_date
    add_index :mrp_exceptions, :requires_immediate_action
    add_index :mrp_exceptions, :is_recurring
    add_index :mrp_exceptions, :deleted
    add_index :mrp_exceptions, [:exception_category, :status]
  end
end