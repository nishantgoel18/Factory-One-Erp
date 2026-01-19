class CreateMrpActionMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :mrp_action_messages do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :mrp_run, null: false, foreign_key: true, index: true
      t.references :product, foreign_key: true, index: true
      
      # Related orders
      t.references :planned_purchase_order, foreign_key: true
      t.references :planned_work_order, foreign_key: true
      t.references :purchase_order, foreign_key: { to_table: :purchase_orders }
      t.references :work_order, foreign_key: true
      
      # User tracking
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :executed_by, foreign_key: { to_table: :users }
      
      # ========================================
      # ACTION MESSAGE IDENTIFICATION
      # ========================================
      t.string :action_message_number, limit: 50, null: false
      
      # ========================================
      # ACTION TYPE
      # ========================================
      t.string :action_type, limit: 30, null: false
      # Primary actions:
      # - 'EXPEDITE': Move date earlier
      # - 'DELAY': Move date later  
      # - 'INCREASE_QTY': Increase order quantity
      # - 'DECREASE_QTY': Decrease order quantity
      # - 'CANCEL': Cancel order
      # - 'SPLIT': Split order into multiple
      # - 'COMBINE': Combine multiple orders
      # - 'RELEASE': Release planned order now
      # - 'RESCHEDULE': Change both date and qty
      
      t.string :action_category, limit: 30
      # Categories: 'DATE_CHANGE', 'QUANTITY_CHANGE', 'ORDER_MANAGEMENT'
      
      # ========================================
      # RELATED ORDER INFO
      # ========================================
      t.string :order_type, limit: 30
      # 'PLANNED_PO', 'PLANNED_WO', 'PURCHASE_ORDER', 'WORK_ORDER'
      
      t.string :order_number, limit: 50
      
      # ========================================
      # CURRENT VALUES
      # ========================================
      t.date :current_date
      t.decimal :current_quantity, precision: 14, scale: 4
      t.string :current_status, limit: 30
      
      # ========================================
      # SUGGESTED/RECOMMENDED VALUES
      # ========================================
      t.date :suggested_date
      t.decimal :suggested_quantity, precision: 14, scale: 4
      
      # ========================================
      # CHANGES REQUIRED
      # ========================================
      t.integer :days_to_expedite  # Negative = delay, Positive = expedite
      t.decimal :quantity_change, precision: 14, scale: 4  # + or -
      
      # ========================================
      # REASON FOR ACTION
      # ========================================
      t.text :reason, null: false
      t.text :detailed_explanation
      t.text :business_impact
      
      # Options examples:
      # - 'Demand increased'
      # - 'Demand decreased'  
      # - 'Material available early'
      # - 'Capacity constraint'
      # - 'Customer requested earlier delivery'
      # - 'Supplier lead time changed'
      
      # ========================================
      # PRIORITY
      # ========================================
      t.string :priority, limit: 20, default: 'NORMAL', null: false
      # Options: 'CRITICAL', 'HIGH', 'NORMAL', 'LOW'
      
      t.integer :priority_score, default: 50  # 1-100
      
      # ========================================
      # STATUS
      # ========================================
      t.string :status, limit: 30, default: 'OPEN', null: false
      # Options: 'OPEN', 'ACKNOWLEDGED', 'IN_REVIEW', 'APPROVED', 
      #          'EXECUTED', 'REJECTED', 'CANCELLED', 'EXPIRED'
      
      # ========================================
      # WORKFLOW DATES
      # ========================================
      t.datetime :acknowledged_at
      t.datetime :reviewed_at
      t.datetime :approved_at
      t.datetime :executed_at
      t.datetime :rejected_at
      t.datetime :cancelled_at
      
      # ========================================
      # EXECUTION DETAILS
      # ========================================
      t.text :execution_notes
      t.text :rejection_reason
      t.date :actual_new_date  # What was actually changed to
      t.decimal :actual_new_quantity, precision: 14, scale: 4
      
      # ========================================
      # FEASIBILITY
      # ========================================
      t.boolean :is_feasible, default: true
      t.text :feasibility_notes
      t.string :constraints, array: true, default: []
      # ['SUPPLIER_CAPACITY', 'MATERIAL_AVAILABILITY', 'WORK_CENTER_CAPACITY']
      
      # ========================================
      # COST IMPACT
      # ========================================
      t.decimal :estimated_cost_impact, precision: 15, scale: 2
      t.string :cost_impact_type, limit: 30
      # 'INCREASE', 'DECREASE', 'NO_CHANGE'
      
      t.string :currency, limit: 3, default: 'USD'
      
      # ========================================
      # URGENCY
      # ========================================
      t.boolean :requires_immediate_action, default: false
      t.date :action_required_by  # Deadline
      t.integer :days_until_deadline
      
      # ========================================
      # SUPPLIER/CUSTOMER COMMUNICATION
      # ========================================
      t.boolean :requires_supplier_approval, default: false
      t.boolean :supplier_notified, default: false
      t.datetime :supplier_notified_at
      
      t.boolean :requires_customer_notification, default: false
      t.boolean :customer_notified, default: false
      t.datetime :customer_notified_at
      
      # ========================================
      # RELATED CUSTOMER/SUPPLIER
      # ========================================
      t.references :customer, foreign_key: true
      t.references :supplier, foreign_key: true
      
      # ========================================
      # AUTO-EXECUTION
      # ========================================
      t.boolean :can_auto_execute, default: false
      t.boolean :auto_executed, default: false
      t.datetime :auto_executed_at
      
      # ========================================
      # ALTERNATIVE ACTIONS
      # ========================================
      t.jsonb :alternative_actions, default: []
      # Store array of alternative solutions:
      # [
      #   { action: 'EXPEDITE', days: 5, cost: 500 },
      #   { action: 'SPLIT_ORDER', cost: 200 }
      # ]
      
      # ========================================
      # LINKED ACTIONS
      # ========================================
      t.references :parent_action, foreign_key: { to_table: :mrp_action_messages }
      t.boolean :has_child_actions, default: false
      
      # ========================================
      # RECURRENCE
      # ========================================
      t.boolean :is_recurring, default: false
      t.integer :occurrence_count, default: 1
      
      # ========================================
      # METADATA
      # ========================================
      t.jsonb :calculation_details, default: {}
      t.jsonb :metadata, default: {}
      
      # ========================================
      # NOTIFICATIONS
      # ========================================
      t.boolean :notification_sent, default: false
      t.datetime :notification_sent_at
      t.string :notification_recipients, array: true, default: []
      
      # ========================================
      # AUDIT & NOTES
      # ========================================
      t.text :notes
      t.text :internal_notes
      t.string :tags, array: true, default: []
      
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
    add_index :mrp_action_messages, :action_message_number, unique: true
    add_index :mrp_action_messages, [:organization_id, :status]
    add_index :mrp_action_messages, [:organization_id, :priority]
    add_index :mrp_action_messages, [:mrp_run_id, :action_type]
    add_index :mrp_action_messages, [:product_id, :status]
    add_index :mrp_action_messages, :action_type
    add_index :mrp_action_messages, :status
    add_index :mrp_action_messages, :priority
    add_index :mrp_action_messages, [:assigned_to_id, :status]
    add_index :mrp_action_messages, :requires_immediate_action
    add_index :mrp_action_messages, :can_auto_execute
    add_index :mrp_action_messages, :deleted
    add_index :mrp_action_messages, [:order_type, :order_number]
  end
end