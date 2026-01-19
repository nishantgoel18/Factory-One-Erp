# frozen_string_literal: true
# app/controllers/settings/mrp_configurations_controller.rb

module Settings
  class MrpConfigurationsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    
    # GET /settings/mrp_configuration
    def show
      @mrp_config = current_mrp_config
    end
    
    # GET /settings/mrp_configuration/edit
    def edit
      @mrp_config = current_mrp_config
    end
    
    # PATCH /settings/mrp_configuration
    def update
      @mrp_config = current_mrp_config
      
      if @mrp_config.update(mrp_configuration_params)
        redirect_to settings_mrp_configuration_path, notice: "MRP configuration updated successfully!"
      else
        render :edit
      end
    end
    
    private
    
    def mrp_configuration_params
      params.require(:mrp_configuration).permit(
        # Planning Horizon
        :planning_horizon_days, :short_term_horizon_days,
        :medium_term_horizon_days, :long_term_horizon_days,
        :mrp_replanning_frequency, :auto_replan_trigger_enabled,
        :planning_time_fence_days, :frozen_zone_days,
        :demand_time_fence_days, :planning_calendar_working_days_only,
        
        # Lot Sizing
        :default_lot_sizing_method, :default_min_order_quantity,
        :default_max_order_quantity, :default_order_multiple,
        :lot_sizing_rounding_rule, :eoq_ordering_cost,
        :eoq_holding_cost_percent,
        
        # Safety Stock
        :safety_stock_calculation_method, :safety_stock_days,
        :service_level_target_percent, :demand_variability_factor,
        :safety_stock_review_frequency, :auto_adjust_safety_stock_enabled,
        
        # Reorder Point
        :reorder_point_calculation_method, :reorder_point_buffer_percent,
        :reorder_point_review_frequency, :auto_adjust_reorder_points_enabled,
        :reorder_point_alert_threshold_days,
        
        # Lead Times
        :default_purchase_lead_time, :default_manufacturing_lead_time,
        :lead_time_safety_buffer_days, :lead_time_variability_factor,
        
        # Demand Management
        :include_forecasts_in_mrp, :include_sales_orders_in_mrp,
        :forecast_consumption_method, :forecast_time_fence_days,
        :demand_priority, :demand_aggregation_level,
        
        # Supply Management
        :include_existing_pos_in_mrp, :include_existing_wos_in_mrp,
        :include_in_transit_inventory, :include_reserved_inventory,
        :inventory_allocation_method, :planned_order_firm_time_fence_days,
        
        # Vendor Selection
        :auto_vendor_selection_enabled, :vendor_selection_criteria,
        :vendor_price_weight_percent, :vendor_quality_weight_percent,
        :vendor_delivery_weight_percent, :price_tolerance_percent,
        :minimum_vendors_to_compare, :auto_create_rfq_for_planned_pos,
        :rfq_auto_send_to_vendors,
        
        # Exception Management
        :exception_alerts_enabled, :exception_threshold_days,
        :alert_recipients_emails, :alert_frequency,
        :critical_exception_immediate_alert,
        {exception_types_to_monitor: []},
        
        # Costing
        :default_costing_method, :overhead_allocation_method,
        :material_overhead_rate_percent, :labor_overhead_rate_percent,
        :cost_rolling_frequency, :cost_variance_tolerance_percent,
        
        # Item Overrides
        :allow_item_level_overrides,
        {item_override_settings: []},
        
        # MRP Run
        :mrp_run_mode, :mrp_processing_priority,
        :include_make_to_order_items, :include_make_to_stock_items,
        :pegging_depth_level, :action_message_generation_enabled,
        {action_message_types_enabled: []},
        
        # Approvals
        :planned_po_requires_approval, :planned_po_approval_threshold,
        :planned_wo_requires_approval, :approval_hierarchy_levels,
        :auto_approve_below_threshold, :approval_timeout_days,
        :email_notifications_for_approvals,
        
        # Notifications
        :email_notifications_enabled, :notify_on_planned_po_creation,
        :notify_on_planned_wo_creation, :notify_on_exceptions,
        :notify_on_po_approval, :notify_on_vendor_quote_received,
        :daily_mrp_summary_email, :weekly_planning_report
      )
    end
  end
end