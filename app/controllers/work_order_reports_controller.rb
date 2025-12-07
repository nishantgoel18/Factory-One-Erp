# app/controllers/reports/work_order_reports_controller.rb
require "csv"
class WorkOrderReportsController < ApplicationController
  before_action :authenticate_user!
  
  # ========================================
  # STATUS REPORT
  # ========================================
  def status_report
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current.end_of_month
    
    @work_orders = WorkOrder.non_deleted
                            .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                            .includes(:product, :warehouse, :created_by)
                            .order(created_at: :desc)
    
    # Apply filters
    @work_orders = @work_orders.by_status(params[:status]) if params[:status].present?
    @work_orders = @work_orders.by_priority(params[:priority]) if params[:priority].present?
    @work_orders = @work_orders.by_warehouse(params[:warehouse_id]) if params[:warehouse_id].present?
    
    # Summary statistics
    @stats = {
      total_wos: @work_orders.count,
      total_quantity: @work_orders.sum(:quantity_to_produce),
      completed_quantity: @work_orders.where(status: 'COMPLETED').sum(:quantity_completed),
      
      by_status: {
        not_started: @work_orders.where(status: 'NOT_STARTED').count,
        released: @work_orders.where(status: 'RELEASED').count,
        in_progress: @work_orders.where(status: 'IN_PROGRESS').count,
        completed: @work_orders.where(status: 'COMPLETED').count,
        cancelled: @work_orders.where(status: 'CANCELLED').count
      },
      
      by_priority: {
        urgent: @work_orders.where(priority: 'URGENT').count,
        high: @work_orders.where(priority: 'HIGH').count,
        normal: @work_orders.where(priority: 'NORMAL').count,
        low: @work_orders.where(priority: 'LOW').count
      },
      
      on_time_completion: calculate_on_time_completion(@work_orders),
      avg_completion_days: calculate_avg_completion_days(@work_orders)
    }
    
    # For filters
    @warehouses = Warehouse.non_deleted.where(is_active: true).order(:name)
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "work_order_status_report_#{@start_date}_to_#{@end_date}",
               template: "reports/work_order_reports/status_report_pdf",
               layout: "pdf",
               page_size: "A4",
               orientation: "Landscape"
      end
      format.csv do
        send_data generate_status_csv(@work_orders),
                  filename: "work_order_status_report_#{Date.current}.csv"
      end
    end
  end
  
  # ========================================
  # COST VARIANCE REPORT
  # ========================================
  def cost_variance_report
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current.end_of_month
    
    @work_orders = WorkOrder.non_deleted
                            .where(status: 'COMPLETED')
                            .where(completed_at: @start_date.beginning_of_day..@end_date.end_of_day)
                            .includes(:product, :warehouse)
                            .order(completed_at: :desc)
    
    # Calculate variances
    @total_planned_cost = @work_orders.sum(:planned_material_cost) + 
                         @work_orders.sum(:planned_labor_cost) + 
                         @work_orders.sum(:planned_overhead_cost)
    
    @total_actual_cost = @work_orders.sum(:actual_material_cost) + 
                        @work_orders.sum(:actual_labor_cost) + 
                        @work_orders.sum(:actual_overhead_cost)
    
    @total_variance = @total_planned_cost - @total_actual_cost
    @variance_percent = @total_planned_cost > 0 ? 
                       ((@total_variance / @total_planned_cost) * 100).round(2) : 0
    
    # Top 5 over budget
    @over_budget_wos = @work_orders.select { |wo| wo.cost_variance < 0 }
                                   .sort_by { |wo| wo.cost_variance }
                                   .first(5)
    
    # Top 5 under budget
    @under_budget_wos = @work_orders.select { |wo| wo.cost_variance > 0 }
                                    .sort_by { |wo| -wo.cost_variance }
                                    .first(5)
    
    # Variance breakdown
    @material_variance = @work_orders.sum(:planned_material_cost) - @work_orders.sum(:actual_material_cost)
    @labor_variance = @work_orders.sum(:planned_labor_cost) - @work_orders.sum(:actual_labor_cost)
    @overhead_variance = @work_orders.sum(:planned_overhead_cost) - @work_orders.sum(:actual_overhead_cost)
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "cost_variance_report_#{@start_date}_to_#{@end_date}",
               template: "reports/work_order_reports/cost_variance_report_pdf",
               layout: "pdf",
               page_size: "A4"
      end
      format.csv do
        send_data generate_cost_variance_csv(@work_orders),
                  filename: "cost_variance_report_#{Date.current}.csv"
      end
    end
  end
  
  # ========================================
  # PRODUCTION EFFICIENCY REPORT
  # ========================================
  def efficiency_report
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current.end_of_day
    
    @operations = WorkOrderOperation.non_deleted
                                    .where(status: 'COMPLETED')
                                    .where(completed_at: @start_date.beginning_of_day..@end_date.end_of_day)
                                    .includes(:work_order, :work_center, :operator, :assigned_operator)
    
    # Overall efficiency
    total_planned_minutes = @operations.sum(:planned_total_minutes)
    total_actual_minutes = @operations.sum(:actual_total_minutes)
    
    @overall_efficiency = total_actual_minutes > 0 ? 
                         ((total_planned_minutes.to_f / total_actual_minutes) * 100).round(2) : 0
    
    # By Work Center
    @work_center_efficiency = @operations.group(:work_center_id)
                                        .select('work_center_id, 
                                                SUM(planned_total_minutes) as total_planned,
                                                SUM(actual_total_minutes) as total_actual')
                                        .map do |stat|
      wc = WorkCenter.find(stat.work_center_id)
      efficiency = stat.total_actual > 0 ? 
                  ((stat.total_planned.to_f / stat.total_actual) * 100).round(2) : 0
      {
        work_center: wc,
        planned_minutes: stat.total_planned,
        actual_minutes: stat.total_actual,
        efficiency: efficiency
      }
    end.sort_by { |s| -s[:efficiency] }
    
    # By Operator (UPDATED WITH ASSIGNMENT TRACKING)
    @operator_stats = @operations.where.not(operator_id: nil)
                                .group(:operator_id)
                                .select('operator_id, 
                                        COUNT(*) as operations_count,
                                        SUM(planned_total_minutes) as total_planned,
                                        SUM(actual_total_minutes) as total_actual,
                                        SUM(quantity_completed) as total_completed,
                                        SUM(quantity_scrapped) as total_scrapped')
                                .map do |stat|
      operator = User.find(stat.operator_id)
      efficiency = stat.total_actual > 0 ? 
                  ((stat.total_planned.to_f / stat.total_actual) * 100).round(2) : 0
      scrap_rate = stat.total_completed > 0 ?
                  ((stat.total_scrapped.to_f / stat.total_completed) * 100).round(2) : 0
      
      # NEW: Assignment tracking
      assigned_ops = @operations.where(assigned_operator_id: operator.id).count
      completed_assigned_ops = @operations.where(assigned_operator_id: operator.id, 
                                                 operator_id: operator.id).count
      helped_others = @operations.where(operator_id: operator.id)
                                 .where.not(assigned_operator_id: operator.id)
                                 .where.not(assigned_operator_id: nil)
                                 .count
      
      {
        operator: operator,
        operations_count: stat.operations_count,
        assigned_count: assigned_ops,
        completed_assigned: completed_assigned_ops,
        helped_others: helped_others,
        assignment_compliance: assigned_ops > 0 ? 
                              (completed_assigned_ops.to_f / assigned_ops * 100).round(1) : 0,
        efficiency: efficiency,
        scrap_rate: scrap_rate,
        total_completed: stat.total_completed,
        total_scrapped: stat.total_scrapped
      }
    end.sort_by { |s| -s[:efficiency] }
    
    # Time variance trends
    @time_variances = @operations.map do |op|
      {
        operation: op,
        variance_minutes: op.time_variance_minutes,
        variance_percent: op.efficiency_percentage
      }
    end
    
    # NEW: Assignment accuracy metrics
    total_with_assignment = @operations.where.not(assigned_operator_id: nil).count
    completed_as_assigned = @operations.where('assigned_operator_id = operator_id').count
    
    @assignment_accuracy = total_with_assignment > 0 ?
                          (completed_as_assigned.to_f / total_with_assignment * 100).round(1) : 0
    @reassigned_operations = @operations.where.not(assigned_operator_id: nil)
                                       .where('assigned_operator_id != operator_id OR operator_id IS NULL')
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "efficiency_report_#{@start_date}_to_#{@end_date}",
               template: "reports/work_order_reports/efficiency_report_pdf",
               layout: "pdf",
               page_size: "A4"
      end
      format.csv do
        send_data generate_efficiency_csv(@operations),
                  filename: "efficiency_report_#{Date.current}.csv"
      end
    end
  end
  
  # ========================================
  # MATERIAL CONSUMPTION REPORT
  # ========================================
  def material_consumption_report
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current.end_of_day
    
    @materials = WorkOrderMaterial.non_deleted
                                  .where(status: 'CONSUMED')
                                  .joins(:work_order)
                                  .where(work_orders: { 
                                    completed_at: @start_date.beginning_of_day..@end_date.end_of_day 
                                  })
                                  .includes(:product, :work_order, :uom)
    
    # Group by product
    consumption_data = WorkOrderMaterial.connection.select_all(
      WorkOrderMaterial.non_deleted
                       .where(status: 'CONSUMED')
                       .joins(:work_order)
                       .where(work_orders: { 
                         completed_at: @start_date.beginning_of_day..@end_date.end_of_day 
                       })
                       .group('work_order_materials.product_id')
                       .select('work_order_materials.product_id,
                               SUM(quantity_required) as total_required,
                               SUM(quantity_consumed) as total_consumed,
                               SUM(total_cost) as total_cost')
                       .to_sql
    )
    @consumption_by_product = consumption_data.map do |stat|
      product = Product.find(stat['product_id'])
      variance = stat['total_required'].to_f - stat['total_consumed'].to_f
      variance_percent = stat['total_required'].to_f > 0 ?
                        ((variance / stat['total_required'].to_f) * 100).round(2) : 0
      {
        product: product,
        required: stat['total_required'].to_f,
        consumed: stat['total_consumed'].to_f,
        variance: variance,
        variance_percent: variance_percent,
        total_cost: stat['total_cost'].to_f
      }
    end.sort_by { |s| -s[:total_cost] }
    
    # Over-consumed materials (variance negative)
    @over_consumed = @consumption_by_product.select { |s| s[:variance] < 0 }
                                            .sort_by { |s| s[:variance] }
                                            .first(10)
    
    # Total statistics
    @total_cost = @materials.sum(:total_cost)
    @total_materials = @consumption_by_product.count
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "material_consumption_report_#{@start_date}_to_#{@end_date}",
               template: "reports/work_order_reports/material_consumption_report_pdf",
               layout: "pdf",
               page_size: "A4"
      end
      format.csv do
        send_data generate_material_consumption_csv(@consumption_by_product),
                  filename: "material_consumption_report_#{Date.current}.csv"
      end
    end
  end

  def operator_assignment_report
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current.end_of_month
    
    @operations = WorkOrderOperation.non_deleted
                                    .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                                    .includes(:assigned_operator, :operator, :work_order => :product)
    
    # Summary stats
    @total_operations = @operations.count
    @assigned_operations = @operations.where.not(assigned_operator_id: nil).count
    @unassigned_operations = @operations.where(assigned_operator_id: nil).count
    
    @completed_as_assigned = @operations.where('assigned_operator_id = operator_id').count
    @reassigned = @operations.where.not(assigned_operator_id: nil)
                            .where.not(operator_id: nil)
                            .where('assigned_operator_id != operator_id')
                            .count
    
    @assignment_rate = @total_operations > 0 ? 
                      (@assigned_operations.to_f / @total_operations * 100).round(1) : 0
    
    @compliance_rate = @assigned_operations > 0 ?
                      (@completed_as_assigned.to_f / @assigned_operations * 100).round(1) : 0
    
    # By operator
    operator_ids = @operations.where.not(assigned_operator_id: nil)
                             .distinct
                             .pluck(:assigned_operator_id)
    
    @operator_assignments = User.where(id: operator_ids).map do |operator|
      assigned = @operations.where(assigned_operator_id: operator.id)
      completed = assigned.where(status: 'COMPLETED')
      completed_by_self = completed.where(operator_id: operator.id)
      completed_by_others = completed.where.not(operator_id: operator.id)
      
      {
        operator: operator,
        total_assigned: assigned.count,
        pending: assigned.where(status: ['PENDING', 'IN_PROGRESS']).count,
        completed: completed.count,
        completed_by_self: completed_by_self.count,
        completed_by_others: completed_by_others.count,
        compliance_rate: completed.count > 0 ?
                        (completed_by_self.count.to_f / completed.count * 100).round(1) : 0
      }
    end.sort_by { |s| -s[:total_assigned] }
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "operator_assignment_report_#{@start_date}_to_#{@end_date}",
               template: "reports/work_order_reports/operator_assignment_report_pdf",
               layout: "pdf"
      end
      format.csv do
        send_data generate_operator_assignment_csv(@operator_assignments),
                  filename: "operator_assignment_report_#{Date.current}.csv"
      end
    end
  end
  
  private
  
  def calculate_on_time_completion(work_orders)
    completed = work_orders.where(status: 'COMPLETED')
    return 0 if completed.count.zero?
    
    on_time = completed.select do |wo|
      wo.actual_end_date.present? && wo.scheduled_end_date.present? &&
      wo.actual_end_date.to_date <= wo.scheduled_end_date
    end
    
    ((on_time.count.to_f / completed.count) * 100).round(2)
  end
  
  def calculate_avg_completion_days(work_orders)
    completed = work_orders.where(status: 'COMPLETED')
                          .where.not(actual_start_date: nil, actual_end_date: nil)
    return 0 if completed.count.zero?
    
    total_days = completed.sum do |wo|
      (wo.actual_end_date.to_date - wo.actual_start_date.to_date).to_i
    end
    
    (total_days.to_f / completed.count).round(1)
  end
  
  def generate_status_csv(work_orders)
    CSV.generate(headers: true) do |csv|
      csv << ['WO Number', 'Product Code', 'Product Name', 'Status', 'Priority', 
              'Quantity', 'UOM', 'Scheduled Start', 'Scheduled End', 
              'Actual Start', 'Actual End', 'Warehouse', 'Created By']
      
      work_orders.each do |wo|
        csv << [
          wo.wo_number,
          wo.product.sku,
          wo.product.name,
          wo.status,
          wo.priority,
          wo.quantity_to_produce,
          wo.uom.symbol,
          wo.scheduled_start_date,
          wo.scheduled_end_date,
          wo.actual_start_date&.strftime("%Y-%m-%d %H:%M"),
          wo.actual_end_date&.strftime("%Y-%m-%d %H:%M"),
          wo.warehouse.name,
          wo.created_by&.full_name
        ]
      end
    end
  end
  
  def generate_cost_variance_csv(work_orders)
    CSV.generate(headers: true) do |csv|
      csv << ['WO Number', 'Product', 'Quantity', 
              'Planned Material', 'Actual Material', 'Material Variance',
              'Planned Labor', 'Actual Labor', 'Labor Variance',
              'Planned Overhead', 'Actual Overhead', 'Overhead Variance',
              'Total Planned', 'Total Actual', 'Total Variance', 'Variance %']
      
      work_orders.each do |wo|
        total_variance = wo.cost_variance
        variance_pct = wo.cost_variance_percent
        
        csv << [
          wo.wo_number,
          "#{wo.product.sku} - #{wo.product.name}",
          wo.quantity_completed,
          wo.planned_material_cost,
          wo.actual_material_cost,
          wo.planned_material_cost - wo.actual_material_cost,
          wo.planned_labor_cost,
          wo.actual_labor_cost,
          wo.planned_labor_cost - wo.actual_labor_cost,
          wo.planned_overhead_cost,
          wo.actual_overhead_cost,
          wo.planned_overhead_cost - wo.actual_overhead_cost,
          wo.total_planned_cost,
          wo.total_actual_cost,
          total_variance,
          "#{variance_pct}%"
        ]
      end
    end
  end
  
  def generate_efficiency_csv(operations)
    CSV.generate(headers: true) do |csv|
      csv << ['WO Number', 'Operation', 'Work Center', 'Operator',
              'Planned Minutes', 'Actual Minutes', 'Variance Minutes',
              'Efficiency %', 'Quantity Completed', 'Quantity Scrapped']
      
      operations.each do |op|
        csv << [
          op.work_order.wo_number,
          op.operation_name,
          "#{op.work_center.code} - #{op.work_center.name}",
          op.operator&.full_name,
          op.planned_total_minutes,
          op.actual_total_minutes,
          op.time_variance_minutes,
          op.efficiency_percentage,
          op.quantity_completed,
          op.quantity_scrapped
        ]
      end
    end
  end
  
  def generate_material_consumption_csv(consumption_data)
    CSV.generate(headers: true) do |csv|
      csv << ['Product Code', 'Product Name', 'Required Quantity', 
              'Consumed Quantity', 'Variance', 'Variance %', 'Total Cost']
      
      consumption_data.each do |data|
        csv << [
          data[:product].sku,
          data[:product].name,
          data[:required],
          data[:consumed],
          data[:variance],
          "#{data[:variance_percent]}%",
          data[:total_cost]
        ]
      end
    end
  end

  def generate_operator_assignment_csv(assignments)
    CSV.generate(headers: true) do |csv|
      csv << ['Operator', 'Email', 'Total Assigned', 'Pending', 'Completed', 
              'Completed by Self', 'Completed by Others', 'Compliance Rate %']
      
      assignments.each do |data|
        csv << [
          data[:operator].full_name,
          data[:operator].email,
          data[:total_assigned],
          data[:pending],
          data[:completed],
          data[:completed_by_self],
          data[:completed_by_others],
          data[:compliance_rate]
        ]
      end
    end
  end
end
