# frozen_string_literal: true

# ============================================================================
# MODEL: MrpConfiguration (Module 4.2 - 4.13)
# ============================================================================
# Complete MRP settings for planning, lot sizing, safety stock, lead times,
# demand/supply management, vendor selection, costing, and alerts
# ============================================================================

class MrpConfiguration < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :organization
  
  # ========================================
  # VALIDATIONS
  # ========================================
  
  # Planning Horizon (4.2)
  validates :planning_horizon_days, presence: true, 
                                     numericality: { greater_than: 0, less_than_or_equal_to: 365 }
  validates :short_term_horizon_days, numericality: { greater_than: 0 }, allow_nil: true
  validates :medium_term_horizon_days, numericality: { greater_than: 0 }, allow_nil: true
  validates :long_term_horizon_days, numericality: { greater_than: 0 }, allow_nil: true
  validates :planning_time_fence_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :frozen_zone_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :demand_time_fence_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  validates :mrp_replanning_frequency, inclusion: { 
    in: %w[DAILY WEEKLY BIWEEKLY MONTHLY],
    allow_nil: true
  }
  
  # Lot Sizing (4.3)
  validates :default_lot_sizing_method, inclusion: { 
    in: %w[LOT_FOR_LOT FIXED_ORDER_QTY EOQ POQ MIN_MAX],
    allow_nil: true
  }
  validates :default_min_order_quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :default_max_order_quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :default_order_multiple, numericality: { greater_than: 0 }, allow_nil: true
  validates :eoq_ordering_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :eoq_holding_cost_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  
  # Safety Stock (4.4)
  validates :safety_stock_calculation_method, inclusion: { 
    in: %w[FIXED_QUANTITY DAYS_OF_SUPPLY PERCENTAGE STATISTICAL MANUAL],
    allow_nil: true
  }
  validates :safety_stock_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :service_level_target_percent, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  validates :demand_variability_factor, numericality: { greater_than: 0 }, allow_nil: true
  
  # Reorder Point (4.5)
  validates :reorder_point_calculation_method, inclusion: { 
    in: %w[LEAD_TIME_DEMAND MANUAL STATISTICAL],
    allow_nil: true
  }
  validates :reorder_point_buffer_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  
  # Lead Times (4.6)
  validates :default_purchase_lead_time, presence: true, 
                                          numericality: { greater_than: 0 }
  validates :default_manufacturing_lead_time, presence: true, 
                                               numericality: { greater_than: 0 }
  validates :lead_time_safety_buffer_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :lead_time_variability_factor, numericality: { greater_than: 0 }, allow_nil: true
  
  # Vendor Selection (4.9)
  validates :vendor_selection_criteria, inclusion: { 
    in: %w[LOWEST_COST BEST_PERFORMANCE BALANCED_SCORE PREFERRED_VENDOR ROUND_ROBIN],
    allow_nil: true
  }
  validates :vendor_price_weight_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  validates :vendor_quality_weight_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  validates :vendor_delivery_weight_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  validates :price_tolerance_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  validates :minimum_vendors_to_compare, numericality: { 
    greater_than: 0, 
    only_integer: true 
  }, allow_nil: true
  
  # Exception Management (4.10)
  validates :exception_threshold_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Costing (4.11)
  validates :default_costing_method, inclusion: { 
    in: %w[STANDARD_COST AVERAGE_COST FIFO LIFO],
    allow_nil: true
  }
  validates :material_overhead_rate_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  validates :labor_overhead_rate_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  validates :cost_variance_tolerance_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  
  # MRP Run Settings (4.13)
  validates :mrp_run_mode, inclusion: { 
    in: %w[REGENERATIVE NET_CHANGE],
    allow_nil: true
  }
  validates :mrp_processing_priority, inclusion: { 
    in: %w[CRITICAL_ITEMS_FIRST BY_ITEM_NUMBER BY_PLANNER],
    allow_nil: true
  }
  validates :pegging_depth_level, numericality: { 
    greater_than_or_equal_to: 0, 
    only_integer: true 
  }, allow_nil: true
  
  # Approval Workflows (4.14)
  validates :planned_po_approval_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :approval_timeout_days, numericality: { greater_than: 0 }, allow_nil: true
  
  # ========================================
  # DEFAULTS
  # ========================================
  after_initialize :set_defaults, if: :new_record?
  
  # ========================================
  # CONSTANTS
  # ========================================
  
  LOT_SIZING_METHODS = {
    'LOT_FOR_LOT' => 'Lot-for-Lot (Exact Requirement)',
    'FIXED_ORDER_QTY' => 'Fixed Order Quantity (FOQ)',
    'EOQ' => 'Economic Order Quantity (EOQ)',
    'POQ' => 'Period Order Quantity (POQ)',
    'MIN_MAX' => 'Minimum/Maximum'
  }.freeze
  
  SAFETY_STOCK_METHODS = {
    'FIXED_QUANTITY' => 'Fixed Quantity',
    'DAYS_OF_SUPPLY' => 'Days of Supply',
    'PERCENTAGE' => 'Percentage of Demand',
    'STATISTICAL' => 'Statistical (Demand Variability)',
    'MANUAL' => 'Manual Override'
  }.freeze
  
  REORDER_POINT_METHODS = {
    'LEAD_TIME_DEMAND' => '(Lead Time × Avg Daily Demand) + Safety Stock',
    'MANUAL' => 'Manual Override',
    'STATISTICAL' => 'Statistical Calculation'
  }.freeze
  
  VENDOR_SELECTION_CRITERIA = {
    'LOWEST_COST' => 'Lowest Cost',
    'BEST_PERFORMANCE' => 'Best Performance Rating',
    'BALANCED_SCORE' => 'Balanced Score (Weighted)',
    'PREFERRED_VENDOR' => 'Preferred Vendor',
    'ROUND_ROBIN' => 'Round Robin'
  }.freeze
  
  COSTING_METHODS = {
    'STANDARD_COST' => 'Standard Cost',
    'AVERAGE_COST' => 'Average Cost',
    'FIFO' => 'First In First Out (FIFO)',
    'LIFO' => 'Last In First Out (LIFO)'
  }.freeze
  
  MRP_RUN_MODES = {
    'REGENERATIVE' => 'Regenerative (Full Recalculation)',
    'NET_CHANGE' => 'Net Change (Only Changed Items)'
  }.freeze
  
  EXCEPTION_TYPES = [
    'MATERIAL_SHORTAGE',
    'LATE_PURCHASE_ORDERS',
    'LATE_WORK_ORDERS',
    'EXCESS_INVENTORY',
    'EXPIRED_SAFETY_STOCK',
    'CAPACITY_OVERLOAD'
  ].freeze
  
  ACTION_MESSAGE_TYPES = [
    'EXPEDITE',
    'DELAY',
    'INCREASE_QUANTITY',
    'DECREASE_QUANTITY',
    'CANCEL'
  ].freeze
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Calculate EOQ (Economic Order Quantity)
  def calculate_eoq(annual_demand)
    return nil unless eoq_ordering_cost.present? && eoq_holding_cost_percent.present?
    return nil if annual_demand.to_f <= 0
    
    holding_cost = annual_demand * (eoq_holding_cost_percent / 100.0)
    
    Math.sqrt((2 * annual_demand * eoq_ordering_cost) / holding_cost).round(0)
  end
  
  # Calculate reorder point
  def calculate_reorder_point(avg_daily_demand, lead_time_days, safety_stock_qty = 0)
    case reorder_point_calculation_method
    when 'LEAD_TIME_DEMAND'
      base_rop = (avg_daily_demand * lead_time_days).round(2)
      buffer = base_rop * (reorder_point_buffer_percent.to_f / 100)
      (base_rop + buffer + safety_stock_qty).round(2)
    when 'MANUAL'
      nil # User sets manually
    when 'STATISTICAL'
      # More complex statistical calculation
      # For now, similar to LEAD_TIME_DEMAND with higher buffer
      base_rop = (avg_daily_demand * lead_time_days).round(2)
      buffer = base_rop * ((reorder_point_buffer_percent.to_f + 10) / 100)
      (base_rop + buffer + safety_stock_qty).round(2)
    else
      (avg_daily_demand * lead_time_days + safety_stock_qty).round(2)
    end
  end
  
  # Calculate safety stock
  def calculate_safety_stock(avg_daily_demand, lead_time_days)
    case safety_stock_calculation_method
    when 'FIXED_QUANTITY'
      nil # User sets fixed quantity
    when 'DAYS_OF_SUPPLY'
      (avg_daily_demand * safety_stock_days.to_i).round(2)
    when 'PERCENTAGE'
      demand_during_lead_time = avg_daily_demand * lead_time_days
      (demand_during_lead_time * (service_level_target_percent.to_f / 100)).round(2)
    when 'STATISTICAL'
      # Statistical formula: Z-score × σ × √lead_time
      # Simplified: use demand variability factor
      demand_during_lead_time = avg_daily_demand * lead_time_days
      (demand_during_lead_time * demand_variability_factor.to_f * Math.sqrt(lead_time_days)).round(2)
    when 'MANUAL'
      nil # User sets manually
    else
      (avg_daily_demand * safety_stock_days.to_i).round(2)
    end
  end
  
  # Check if date is in frozen zone
  def in_frozen_zone?(date)
    return false unless frozen_zone_days.present?
    date <= (Date.current + frozen_zone_days.days)
  end
  
  # Check if date is within planning time fence
  def within_planning_time_fence?(date)
    return false unless planning_time_fence_days.present?
    date <= (Date.current + planning_time_fence_days.days)
  end
  
  # Check if date is within demand time fence
  def within_demand_time_fence?(date)
    return false unless demand_time_fence_days.present?
    date <= (Date.current + demand_time_fence_days.days)
  end
  
  # Get planning horizon end date
  def planning_horizon_end_date
    Date.current + planning_horizon_days.days
  end
  
  # Check if vendor weights are balanced (should sum to 100%)
  def vendor_weights_balanced?
    return true unless vendor_selection_criteria == 'BALANCED_SCORE'
    
    total = (vendor_price_weight_percent.to_f + 
             vendor_quality_weight_percent.to_f + 
             vendor_delivery_weight_percent.to_f)
    
    (total - 100.0).abs < 0.01
  end
  
  # Calculate vendor score
  def calculate_vendor_score(price_score, quality_score, delivery_score)
    return nil unless vendor_selection_criteria == 'BALANCED_SCORE'
    return nil unless vendor_weights_balanced?
    
    (price_score * vendor_price_weight_percent.to_f / 100) +
    (quality_score * vendor_quality_weight_percent.to_f / 100) +
    (delivery_score * vendor_delivery_weight_percent.to_f / 100)
  end
  
  # Check if exception monitoring is enabled for a type
  def exception_enabled?(exception_type)
    return false unless exception_alerts_enabled?
    exception_types_to_monitor.include?(exception_type)
  end
  
  # Check if action message type is enabled
  def action_message_enabled?(message_type)
    return false unless action_message_generation_enabled?
    action_message_types_enabled.include?(message_type)
  end
  
  # Get alert recipients array
  def alert_recipients_array
    return [] if alert_recipients_emails.blank?
    alert_recipients_emails.split(',').map(&:strip)
  end
  
  # Check if approval is required for planned PO
  def planned_po_requires_approval?(amount)
    return false unless planned_po_requires_approval?
    return false if planned_po_approval_threshold.blank?
    
    amount >= planned_po_approval_threshold
  end
  
  # Get next MRP run date based on frequency
  def next_mrp_run_date(from_date = Date.current)
    return nil unless auto_replan_trigger_enabled?
    
    case mrp_replanning_frequency
    when 'DAILY'
      from_date + 1.day
    when 'WEEKLY'
      from_date + 1.week
    when 'BIWEEKLY'
      from_date + 2.weeks
    when 'MONTHLY'
      from_date + 1.month
    else
      from_date + 1.week
    end
  end
  
  private
  
  def set_defaults
    # 4.2 Planning Horizon
    self.planning_horizon_days ||= 90
    self.short_term_horizon_days ||= 30
    self.medium_term_horizon_days ||= 60
    self.long_term_horizon_days ||= 90
    self.mrp_replanning_frequency ||= 'WEEKLY'
    self.auto_replan_trigger_enabled ||= false
    self.planning_time_fence_days ||= 30
    self.frozen_zone_days ||= 7
    self.demand_time_fence_days ||= 30
    self.planning_calendar_working_days_only ||= true
    
    # 4.3 Lot Sizing
    self.default_lot_sizing_method ||= 'LOT_FOR_LOT'
    self.default_min_order_quantity ||= 1
    self.default_order_multiple ||= 1
    self.lot_sizing_rounding_rule ||= 'UP'
    self.eoq_ordering_cost ||= 50.0
    self.eoq_holding_cost_percent ||= 20.0
    
    # 4.4 Safety Stock
    self.safety_stock_calculation_method ||= 'DAYS_OF_SUPPLY'
    self.safety_stock_days ||= 7
    self.service_level_target_percent ||= 95.0
    self.demand_variability_factor ||= 1.5
    self.safety_stock_review_frequency ||= 'QUARTERLY'
    self.auto_adjust_safety_stock_enabled ||= false
    
    # 4.5 Reorder Point
    self.reorder_point_calculation_method ||= 'LEAD_TIME_DEMAND'
    self.reorder_point_buffer_percent ||= 10.0
    self.reorder_point_review_frequency ||= 'MONTHLY'
    self.auto_adjust_reorder_points_enabled ||= false
    self.reorder_point_alert_threshold_days ||= 5
    
    # 4.6 Lead Times
    self.default_purchase_lead_time ||= 14
    self.default_manufacturing_lead_time ||= 7
    self.lead_time_safety_buffer_days ||= 2
    self.lead_time_variability_factor ||= 1.2
    
    # 4.7 Demand Management
    self.include_forecasts_in_mrp ||= true
    self.include_sales_orders_in_mrp ||= true
    self.forecast_consumption_method ||= 'FORWARD'
    self.forecast_time_fence_days ||= 30
    self.demand_priority ||= 'SALES_ORDER'
    self.demand_aggregation_level ||= 'DAILY'
    
    # 4.8 Supply Management
    self.include_existing_pos_in_mrp ||= true
    self.include_existing_wos_in_mrp ||= true
    self.include_in_transit_inventory ||= true
    self.include_reserved_inventory ||= false
    self.inventory_allocation_method ||= 'FIFO'
    self.planned_order_firm_time_fence_days ||= 7
    
    # 4.9 Vendor Selection
    self.auto_vendor_selection_enabled ||= false
    self.vendor_selection_criteria ||= 'BALANCED_SCORE'
    self.vendor_price_weight_percent ||= 40.0
    self.vendor_quality_weight_percent ||= 30.0
    self.vendor_delivery_weight_percent ||= 30.0
    self.price_tolerance_percent ||= 5.0
    self.minimum_vendors_to_compare ||= 3
    self.auto_create_rfq_for_planned_pos ||= false
    self.rfq_auto_send_to_vendors ||= false
    
    # 4.10 Exception Management
    self.exception_alerts_enabled ||= true
    self.exception_threshold_days ||= 3
    self.exception_types_to_monitor ||= EXCEPTION_TYPES
    self.alert_recipients_emails ||= ''
    self.alert_frequency ||= 'DAILY_DIGEST'
    self.critical_exception_immediate_alert ||= true
    
    # 4.11 Costing
    self.default_costing_method ||= 'STANDARD_COST'
    self.overhead_allocation_method ||= 'DIRECT_LABOR'
    self.material_overhead_rate_percent ||= 10.0
    self.labor_overhead_rate_percent ||= 15.0
    self.cost_rolling_frequency ||= 'MONTHLY'
    self.cost_variance_tolerance_percent ||= 5.0
    
    # 4.12 Item-Level Overrides
    self.allow_item_level_overrides ||= true
    self.item_override_settings ||= [
      'LOT_SIZING_RULE',
      'SAFETY_STOCK',
      'REORDER_POINT',
      'LEAD_TIMES',
      'MOQ_MAX',
      'PREFERRED_VENDOR'
    ]
    
    # 4.13 MRP Run Settings
    self.mrp_run_mode ||= 'NET_CHANGE'
    self.mrp_processing_priority ||= 'CRITICAL_ITEMS_FIRST'
    self.include_make_to_order_items ||= true
    self.include_make_to_stock_items ||= true
    self.pegging_depth_level ||= 5
    self.action_message_generation_enabled ||= true
    self.action_message_types_enabled ||= ACTION_MESSAGE_TYPES
    
    # 4.14 Approval Workflows
    self.planned_po_requires_approval ||= false
    self.planned_po_approval_threshold ||= 10000.0
    self.planned_wo_requires_approval ||= false
    self.approval_hierarchy_levels ||= 1
    self.auto_approve_below_threshold ||= true
    self.approval_timeout_days ||= 3
    self.email_notifications_for_approvals ||= true
    
    # 4.15 Notifications
    self.email_notifications_enabled ||= true
    self.notify_on_planned_po_creation ||= true
    self.notify_on_planned_wo_creation ||= true
    self.notify_on_exceptions ||= true
    self.notify_on_po_approval ||= true
    self.notify_on_vendor_quote_received ||= false
    self.daily_mrp_summary_email ||= false
    self.weekly_planning_report ||= false
  end
end