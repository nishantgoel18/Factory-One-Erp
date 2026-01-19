class CreateItemPlanningParameters < ActiveRecord::Migration[8.1]
  def change
    create_table :item_planning_parameters do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.references :mrp_planner, foreign_key: { to_table: :users }, index: true  # Who is responsible
      
      # ========================================
      # PLANNING METHOD
      # ========================================
      t.string :planning_method, limit: 30, default: 'MRP', null: false
      # Options: 'MRP', 'REORDER_POINT', 'MANUAL', 'NONE'
      
      # ========================================
      # SAFETY STOCK & REORDER SETTINGS
      # ========================================
      t.decimal :safety_stock_quantity, precision: 14, scale: 4, default: 0.0
      t.decimal :reorder_point, precision: 14, scale: 4, default: 0.0
      t.decimal :minimum_stock_level, precision: 14, scale: 4, default: 0.0
      t.decimal :maximum_stock_level, precision: 14, scale: 4, default: 0.0
      
      # ========================================
      # LEAD TIME (in days)
      # ========================================
      t.integer :purchasing_lead_time_days, default: 0  # For purchased items
      t.integer :manufacturing_lead_time_days, default: 0  # For manufactured items
      t.integer :safety_lead_time_days, default: 0  # Buffer time
      
      # ========================================
      # LOT SIZING RULES
      # ========================================
      t.string :lot_sizing_rule, limit: 30, default: 'LOT_FOR_LOT'
      # Options: 
      # - 'LOT_FOR_LOT' (exact quantity needed)
      # - 'FIXED_ORDER_QTY' (always order fixed_order_quantity)
      # - 'EOQ' (Economic Order Quantity)
      # - 'PERIOD_ORDER_QTY' (order for X periods)
      # - 'MIN_MAX' (order to max when below min)
      
      t.decimal :fixed_order_quantity, precision: 14, scale: 4
      t.decimal :minimum_order_quantity, precision: 14, scale: 4, default: 1.0
      t.decimal :maximum_order_quantity, precision: 14, scale: 4
      t.decimal :order_multiple, precision: 14, scale: 4, default: 1.0  # Round up to multiples
      
      # For EOQ calculation (if using EOQ lot sizing)
      t.decimal :annual_demand, precision: 14, scale: 4
      t.decimal :ordering_cost_per_order, precision: 10, scale: 2
      t.decimal :carrying_cost_percent, precision: 5, scale: 2
      
      # For Period Order Qty
      t.integer :periods_of_supply, default: 1  # Order for how many periods
      
      # ========================================
      # PLANNING HORIZON
      # ========================================
      t.integer :planning_horizon_days, default: 90
      t.integer :planning_time_fence_days, default: 7  # Frozen zone - no changes
      
      # ========================================
      # ITEM CATEGORIZATION
      # ========================================
      t.string :abc_classification, limit: 1  # A, B, C
      t.string :xyz_classification, limit: 1  # X (stable), Y (variable), Z (irregular)
      t.boolean :is_critical_item, default: false
      t.boolean :is_phantom_item, default: false  # BOM component not stocked
      
      # ========================================
      # MAKE OR BUY
      # ========================================
      t.string :make_or_buy, limit: 20, default: 'BUY'
      # Options: 'MAKE', 'BUY', 'MAKE_AND_BUY'
      
      # ========================================
      # SHRINKAGE & YIELD
      # ========================================
      t.decimal :shrinkage_percent, precision: 5, scale: 2, default: 0.0
      t.decimal :yield_percent, precision: 5, scale: 2, default: 100.0
      
      # ========================================
      # MRP SETTINGS
      # ========================================
      t.boolean :include_in_mrp, default: true
      t.boolean :create_planned_pos, default: true  # Auto-create planned purchase orders
      t.boolean :create_planned_wos, default: true  # Auto-create planned work orders
      t.boolean :consider_work_calendar, default: false  # Skip non-working days
      
      # ========================================
      # TIME BUCKETING
      # ========================================
      t.string :time_bucket, limit: 20, default: 'DAILY'
      # Options: 'DAILY', 'WEEKLY', 'MONTHLY'
      
      # ========================================
      # AUDIT & STATUS
      # ========================================
      t.boolean :is_active, default: true
      t.text :notes
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # ========================================
    # INDEXES FOR PERFORMANCE
    # ========================================
    add_index :item_planning_parameters, [:organization_id, :product_id], 
              unique: true, 
              where: "deleted = false",
              name: 'idx_item_planning_params_org_product_unique'
              
    add_index :item_planning_parameters, :planning_method
    add_index :item_planning_parameters, :abc_classification
    add_index :item_planning_parameters, :is_critical_item
    add_index :item_planning_parameters, :include_in_mrp
    add_index :item_planning_parameters, :deleted
  end
end
