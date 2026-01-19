class CreateMrpConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :mrp_configurations do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }
      
      # 4.2 Planning Horizon
      t.integer :planning_horizon_days, default: 90
      t.integer :short_term_horizon_days, default: 30
      t.integer :medium_term_horizon_days, default: 60
      t.integer :long_term_horizon_days, default: 90
      t.string :mrp_replanning_frequency, default: 'WEEKLY'
      t.boolean :auto_replan_trigger_enabled, default: false
      t.integer :planning_time_fence_days, default: 30
      t.integer :frozen_zone_days, default: 7
      t.integer :demand_time_fence_days, default: 14
      t.boolean :planning_calendar_working_days_only, default: true
      
      # 4.3 Lot Sizing
      t.string :default_lot_sizing_method, default: 'LOT_FOR_LOT'
      t.decimal :default_min_order_quantity, precision: 15, scale: 3
      t.decimal :default_max_order_quantity, precision: 15, scale: 3
      t.decimal :default_order_multiple, precision: 15, scale: 3, default: 1.0
      t.string :lot_sizing_rounding_rule, default: 'UP'
      t.decimal :eoq_ordering_cost, precision: 15, scale: 2, default: 50.0
      t.decimal :eoq_holding_cost_percent, precision: 5, scale: 2, default: 10.0
      
      # 4.4 Safety Stock
      t.string :safety_stock_calculation_method, default: 'DAYS_OF_SUPPLY'
      t.integer :safety_stock_days, default: 7
      t.decimal :service_level_target_percent, precision: 5, scale: 2, default: 95.0
      t.decimal :demand_variability_factor, precision: 5, scale: 2, default: 1.5
      t.string :safety_stock_review_frequency, default: 'MONTHLY'
      t.boolean :auto_adjust_safety_stock_enabled, default: false
      
      # 4.5 Reorder Point
      t.string :reorder_point_calculation_method, default: 'LEAD_TIME_DEMAND'
      t.decimal :reorder_point_buffer_percent, precision: 5, scale: 2, default: 10.0
      t.string :reorder_point_review_frequency, default: 'MONTHLY'
      t.boolean :auto_adjust_reorder_points_enabled, default: false
      t.integer :reorder_point_alert_threshold_days, default: 3
      
      # 4.6 Lead Times
      t.integer :default_purchase_lead_time, default: 14
      t.integer :default_manufacturing_lead_time, default: 7
      t.integer :lead_time_safety_buffer_days, default: 2
      t.decimal :lead_time_variability_factor, precision: 5, scale: 2, default: 1.2
      
      # 4.7 Demand Management
      t.boolean :include_forecasts_in_mrp, default: true
      t.boolean :include_sales_orders_in_mrp, default: true
      t.string :forecast_consumption_method, default: 'FORWARD'
      t.integer :forecast_time_fence_days, default: 30
      t.string :demand_priority, default: 'SALES_ORDER'
      t.string :demand_aggregation_level, default: 'DAILY'
      
      # 4.8 Supply Management
      t.boolean :include_existing_pos_in_mrp, default: true
      t.boolean :include_existing_wos_in_mrp, default: true
      t.boolean :include_in_transit_inventory, default: true
      t.boolean :include_reserved_inventory, default: false
      t.string :inventory_allocation_method, default: 'FIFO'
      t.integer :planned_order_firm_time_fence_days, default: 7
      
      # 4.9 Vendor Selection
      t.boolean :auto_vendor_selection_enabled, default: false
      t.string :vendor_selection_criteria, default: 'LOWEST_COST'
      t.decimal :vendor_price_weight_percent, precision: 5, scale: 2, default: 40.0
      t.decimal :vendor_quality_weight_percent, precision: 5, scale: 2, default: 30.0
      t.decimal :vendor_delivery_weight_percent, precision: 5, scale: 2, default: 30.0
      t.decimal :price_tolerance_percent, precision: 5, scale: 2, default: 5.0
      t.integer :minimum_vendors_to_compare, default: 3
      t.boolean :auto_create_rfq_for_planned_pos, default: false
      t.boolean :rfq_auto_send_to_vendors, default: false
      
      # 4.10 Exception Management
      t.boolean :exception_alerts_enabled, default: true
      t.integer :exception_threshold_days, default: 3
      t.string :exception_types_to_monitor, array: true, default: [
        'MATERIAL_SHORTAGE',
        'LATE_POS',
        'LATE_WOS',
        'EXCESS_INVENTORY'
      ]
      t.text :alert_recipients_emails
      t.string :alert_frequency, default: 'DAILY_DIGEST'
      t.boolean :critical_exception_immediate_alert, default: true
      
      # 4.11 Costing
      t.string :default_costing_method, default: 'STANDARD_COST'
      t.string :overhead_allocation_method, default: 'DIRECT_LABOR'
      t.decimal :material_overhead_rate_percent, precision: 5, scale: 2, default: 10.0
      t.decimal :labor_overhead_rate_percent, precision: 5, scale: 2, default: 15.0
      t.string :cost_rolling_frequency, default: 'MONTHLY'
      t.decimal :cost_variance_tolerance_percent, precision: 5, scale: 2, default: 5.0
      
      # 4.12 Item-Level Overrides
      t.boolean :allow_item_level_overrides, default: true
      t.string :item_override_settings, array: true, default: [
        'LOT_SIZING_RULE',
        'SAFETY_STOCK',
        'REORDER_POINT',
        'LEAD_TIMES'
      ]
      
      # 4.13 MRP Run Settings
      t.string :mrp_run_mode, default: 'NET_CHANGE'
      t.string :mrp_processing_priority, default: 'CRITICAL_ITEMS_FIRST'
      t.boolean :include_make_to_order_items, default: true
      t.boolean :include_make_to_stock_items, default: true
      t.integer :pegging_depth_level, default: 5
      t.boolean :action_message_generation_enabled, default: true
      t.string :action_message_types_enabled, array: true, default: [
        'EXPEDITE',
        'DELAY',
        'INCREASE_QUANTITY',
        'DECREASE_QUANTITY',
        'CANCEL'
      ]
      
      # 4.14 Approval Workflows
      t.boolean :planned_po_requires_approval, default: true
      t.decimal :planned_po_approval_threshold, precision: 15, scale: 2, default: 10000.0
      t.boolean :planned_wo_requires_approval, default: false
      t.integer :approval_hierarchy_levels, default: 2
      t.boolean :auto_approve_below_threshold, default: true
      t.integer :approval_timeout_days, default: 3
      t.boolean :email_notifications_for_approvals, default: true
      
      # 4.15 Notification Settings
      t.boolean :email_notifications_enabled, default: true
      t.boolean :notify_on_planned_po_creation, default: true
      t.boolean :notify_on_planned_wo_creation, default: true
      t.boolean :notify_on_exceptions, default: true
      t.boolean :notify_on_po_approval, default: true
      t.boolean :notify_on_vendor_quote_received, default: true
      t.boolean :daily_mrp_summary_email, default: false
      t.boolean :weekly_planning_report, default: true
      
      t.timestamps
    end
  end
end
