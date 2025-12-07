class DashboardsController < ApplicationController
  before_action :authenticate_user!
  def home
    @routing_metrics = calculate_routing_metrics
    @work_center_metrics = calculate_work_center_metrics
    @production_readiness = calculate_production_readiness
  end

   def production_dashboard
    # Time period
    @today = Date.current
    @this_week_start = @today.beginning_of_week
    @this_month_start = @today.beginning_of_month
    
    # Active Work Orders
    @active_wos = WorkOrder.non_deleted
                          .where(status: ['RELEASED', 'IN_PROGRESS'])
                          .includes(:product, :warehouse)
                          .order(priority: :desc, scheduled_end_date: :asc)
                          .limit(10)
    
    # Today's statistics
    @today_stats = {
      wos_to_start: WorkOrder.non_deleted
                             .where(status: 'RELEASED')
                             .where(scheduled_start_date: @today)
                             .count,
      
      wos_to_complete: WorkOrder.non_deleted
                                .where(status: 'IN_PROGRESS')
                                .where(scheduled_end_date: @today)
                                .count,
      
      operations_pending: WorkOrderOperation.non_deleted
                                           .where(status: 'PENDING')
                                           .joins(:work_order)
                                           .where(work_orders: { status: ['RELEASED', 'IN_PROGRESS'] })
                                           .count,
      
      operations_in_progress: WorkOrderOperation.non_deleted
                                               .where(status: 'IN_PROGRESS')
                                               .count
    }
    
    # This week statistics
    @week_stats = {
      wos_created: WorkOrder.non_deleted
                           .where(created_at: @this_week_start..@today.end_of_day)
                           .count,
      
      wos_completed: WorkOrder.non_deleted
                             .where(status: 'COMPLETED')
                             .where(completed_at: @this_week_start..@today.end_of_day)
                             .count,
      
      quantity_produced: WorkOrder.non_deleted
                                 .where(status: 'COMPLETED')
                                 .where(completed_at: @this_week_start..@today.end_of_day)
                                 .sum(:quantity_completed),
      
      avg_completion_time: calculate_avg_completion_time(@this_week_start, @today)
    }
    
    # This month statistics
    @month_stats = {
      wos_completed: WorkOrder.non_deleted
                             .where(status: 'COMPLETED')
                             .where(completed_at: @this_month_start..@today.end_of_day)
                             .count,
      
      total_production_cost: calculate_total_production_cost(@this_month_start, @today),
      
      avg_cost_variance: calculate_avg_cost_variance(@this_month_start, @today),
      
      on_time_completion_rate: calculate_on_time_rate(@this_month_start, @today)
    }
    
    # Overdue Work Orders
    @overdue_wos = WorkOrder.non_deleted
                           .where(status: ['RELEASED', 'IN_PROGRESS'])
                           .where('scheduled_end_date < ?', @today)
                           .includes(:product)
                           .order(scheduled_end_date: :asc)
                           .limit(5)
    
    # Urgent Work Orders
    @urgent_wos = WorkOrder.non_deleted
                          .where(status: ['NOT_STARTED', 'RELEASED', 'IN_PROGRESS'])
                          .where(priority: 'URGENT')
                          .includes(:product)
                          .order(scheduled_end_date: :asc)
                          .limit(5)
    
    # Work Center Utilization
    @work_center_utilization = calculate_work_center_utilization
    
    # Production Trends (Last 7 days)
    @production_trend = (6.days.ago.to_date..@today).map do |date|
      {
        date: date,
        completed: WorkOrder.non_deleted
                           .where(status: 'COMPLETED')
                           .where(completed_at: date.beginning_of_day..date.end_of_day)
                           .count
      }
    end
    
    # Cost Trends (Last 7 days)
    @cost_trend = (6.days.ago.to_date..@today).map do |date|
      completed_wos = WorkOrder.non_deleted
                               .where(status: 'COMPLETED')
                               .where(completed_at: date.beginning_of_day..date.end_of_day)
      
      {
        date: date,
        planned: completed_wos.sum { |wo| wo.total_planned_cost },
        actual: completed_wos.sum { |wo| wo.total_actual_cost }
      }
    end
  end

  private
  def calculate_routing_metrics
    {
      total: Routing.where(deleted: false).count,
      active: Routing.where(deleted: false, status: 'ACTIVE').count,
      draft: Routing.where(deleted: false, status: 'DRAFT').count,
      default: Routing.where(deleted: false, is_default: true).count,
      total_operations: RoutingOperation.joins(:routing)
                                        .where(deleted: false, routings: { deleted: false })
                                        .count,
      avg_operations_per_routing: RoutingOperation.joins(:routing)
                                                  .where(deleted: false, routings: { deleted: false, status: 'ACTIVE' })
                                                  .group('routings.id')
                                                  .count
                                                  .values
                                                  .sum / [Routing.where(deleted: false, status: 'ACTIVE').count, 1].max.to_f
    }
  end
  
  def calculate_work_center_metrics
    {
      total: WorkCenter.where(deleted: false).count,
      active: WorkCenter.where(deleted: false, is_active: true).count,
      utilized: WorkCenter.where(deleted: false, is_active: true)
                         .joins(:routing_operations)
                         .where(routing_operations: { deleted: false })
                         .distinct
                         .count,
      avg_cost_per_hour: WorkCenter.where(deleted: false, is_active: true)
                                   .average('labor_cost_per_hour + overhead_cost_per_hour')
                                   .to_f
                                   .round(2)
    }
  end
  
  def calculate_production_readiness
    finished_goods = Product.where(deleted: false, product_type: ['Finished Goods', 'Semi-Finished Goods'])
    
    total = finished_goods.count
    with_bom = finished_goods.joins(:bill_of_materials)
                            .where(bill_of_materials: { deleted: false, status: 'ACTIVE' })
                            .distinct
                            .count
    with_routing = finished_goods.joins(:routings)
                                 .where(routings: { deleted: false, status: 'ACTIVE' })
                                 .distinct
                                 .count
    ready = finished_goods.joins(:bill_of_materials, :routings)
                         .where(bill_of_materials: { deleted: false, status: 'ACTIVE' })
                         .where(routings: { deleted: false, status: 'ACTIVE' })
                         .distinct
                         .count
    
    {
      total_products: total,
      with_bom: with_bom,
      with_routing: with_routing,
      ready_for_production: ready,
      readiness_percentage: total > 0 ? ((ready.to_f / total) * 100).round(1) : 0
    }
  end

  def calculate_avg_completion_time(start_date, end_date)
    completed = WorkOrder.non_deleted
                        .where(status: 'COMPLETED')
                        .where(completed_at: start_date..end_date.end_of_day)
                        .where.not(actual_start_date: nil)
    
    return 0 if completed.count.zero?
    
    total_hours = completed.sum do |wo|
      ((wo.actual_end_date - wo.actual_start_date) / 3600).round(2)
    end
    
    (total_hours / completed.count).round(2)
  end
  
  def calculate_total_production_cost(start_date, end_date)
    WorkOrder.non_deleted
            .where(status: 'COMPLETED')
            .where(completed_at: start_date..end_date.end_of_day)
            .sum { |wo| wo.total_actual_cost }
  end
  
  def calculate_avg_cost_variance(start_date, end_date)
    completed = WorkOrder.non_deleted
                        .where(status: 'COMPLETED')
                        .where(completed_at: start_date..end_date.end_of_day)
    
    return 0 if completed.count.zero?
    
    total_variance = completed.sum { |wo| wo.cost_variance }
    (total_variance / completed.count).round(2)
  end
  
  def calculate_on_time_rate(start_date, end_date)
    completed = WorkOrder.non_deleted
                        .where(status: 'COMPLETED')
                        .where(completed_at: start_date..end_date.end_of_day)
    
    return 0 if completed.count.zero?
    
    on_time = completed.select do |wo|
      wo.actual_end_date.to_date <= wo.scheduled_end_date
    end
    
    ((on_time.count.to_f / completed.count) * 100).round(2)
  end
  
  def calculate_work_center_utilization
    today = Date.current
    active_operations = WorkOrderOperation.non_deleted
                                         .where(status: 'IN_PROGRESS')
                                         .includes(:work_center)
    
    work_centers = WorkCenter.active.limit(10)
    
    work_centers.map do |wc|
      ops_count = active_operations.where(work_center_id: wc.id).count
      {
        work_center: wc,
        active_operations: ops_count,
        utilization_percent: ops_count > 0 ? 100 : 0  # Simplified
      }
    end.sort_by { |s| -s[:utilization_percent] }
  end
end
