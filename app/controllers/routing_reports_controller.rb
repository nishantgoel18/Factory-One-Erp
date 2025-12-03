# app/controllers/routing_reports_controller.rb
require 'csv'
class RoutingReportsController < ApplicationController
  def index
    # Main reports landing page
  end
  
  # ========================================
  # REPORT 1: Work Center Utilization
  # ========================================
  def work_center_utilization
    @work_centers = WorkCenter.where(deleted: false, is_active: true)
                              .includes(routing_operations: :routing)
                              .order(:code)
    
    @utilization_data = @work_centers.map do |wc|
      operations = wc.routing_operations.where(deleted: false)
      active_routings = operations.joins(:routing)
                                  .where(routings: { status: 'ACTIVE', deleted: false })
                                  .distinct
                                  .count
      
      {
        work_center: wc,
        total_operations: operations.count,
        active_operations: active_routings,
        total_setup_time: operations.sum(:setup_time_minutes),
        avg_run_time: operations.average(:run_time_per_unit_minutes)&.round(2) || 0,
        utilization_score: calculate_utilization_score(wc)
      }
    end
    
    respond_to do |format|
      format.html
      format.csv { send_data generate_wc_utilization_csv, filename: "work_center_utilization_#{Date.today}.csv" }
      format.pdf { render pdf: "work_center_utilization", layout: 'pdf' }
    end
  end
  
  # ========================================
  # REPORT 2: Routing Cost Analysis
  # ========================================
  def routing_cost_analysis
    @routings = Routing.where(deleted: false, status: 'ACTIVE')
                       .includes(:product, routing_operations: :work_center)
                       .order('products.name')
    
    @cost_analysis = @routings.map do |routing|
      operations = routing.routing_operations.where(deleted: false)
      
      {
        routing: routing,
        material_cost: routing.product.standard_cost.to_d,
        labor_cost: routing.total_labor_cost_per_unit,
        overhead_cost: routing.total_overhead_cost_per_unit,
        total_processing_cost: routing.total_cost_per_unit,
        total_product_cost: routing.product.total_production_cost,
        cost_breakdown_pct: {
          material: (routing.product.standard_cost.to_d / routing.product.total_production_cost * 100).round(1),
          labor: (routing.total_labor_cost_per_unit / routing.product.total_production_cost * 100).round(1),
          overhead: (routing.total_overhead_cost_per_unit / routing.product.total_production_cost * 100).round(1)
        },
        operations_count: operations.count,
        most_expensive_operation: operations.max_by(&:total_cost_per_unit)
      }
    end
    
    respond_to do |format|
      format.html
      format.csv { send_data generate_cost_analysis_csv, filename: "routing_cost_analysis_#{Date.today}.csv" }
      format.pdf { render pdf: "routing_cost_analysis", layout: 'pdf' }
    end
  end
  
  # ========================================
  # REPORT 3: Production Time Analysis
  # ========================================
  def production_time_analysis
    @routings = Routing.where(deleted: false, status: 'ACTIVE')
                       .includes(:product, routing_operations: :work_center)
                       .order('products.name')
    
    @time_analysis = @routings.map do |routing|
      operations = routing.routing_operations.where(deleted: false).order(:operation_sequence)
      
      total_wait_time = operations.sum(:wait_time_minutes)
      total_move_time = operations.sum(:move_time_minutes)
      
      {
        routing: routing,
        setup_time: routing.total_setup_time_minutes,
        run_time_per_unit: routing.total_run_time_per_unit_minutes,
        wait_time: total_wait_time,
        move_time: total_move_time,
        total_time_per_unit: routing.total_run_time_per_unit_minutes + total_wait_time + total_move_time,
        operations_count: operations.count,
        critical_operation: routing.critical_operation,
        bottleneck_pct: calculate_bottleneck_percentage(routing),
        time_for_batches: {
          batch_10: routing.calculate_total_time_for_batch(10),
          batch_50: routing.calculate_total_time_for_batch(50),
          batch_100: routing.calculate_total_time_for_batch(100)
        }
      }
    end
    
    respond_to do |format|
      format.html
      format.csv { send_data generate_time_analysis_csv, filename: "production_time_analysis_#{Date.today}.csv" }
      format.pdf { render pdf: "production_time_analysis", layout: 'pdf' }
    end
  end
  
  # ========================================
  # REPORT 4: Routing Comparison
  # ========================================
  def routing_comparison
    # ✅ CORRECT CODE:
    @products = Product.where(deleted: false)
                     .where(product_type: ["Finished Goods", "Semi-Finished Goods"])
                     .joins(:routings)
                     .where(routings: { deleted: false })
                     .group('products.id')
                     .having('COUNT(routings.id) > 1')
                     .order('products.name')
  
    @comparison_data = {}
    
    @products.each do |product|
      routings = product.routings.where(deleted: false).includes(routing_operations: :work_center)
      
      @comparison_data[product.id] = routings.map do |routing|
        {
          routing: routing,
          operations_count: routing.routing_operations.count,
          total_time: routing.total_run_time_per_unit_minutes,
          total_cost: routing.total_cost_per_unit,
          efficiency_score: calculate_efficiency_score(routing)
        }
      end
    end

    respond_to do |format|
      format.html
      format.csv { send_data generate_comparison_csv, filename: "routing_comparison_#{Date.today}.csv" }
    end
  end
  
  # ========================================
  # REPORT 5: Operations Summary
  # ========================================
  def operations_summary
    @operations_data = RoutingOperation.where(deleted: false)
                                       .joins(:routing, :work_center)
                                       .where(routings: { status: 'ACTIVE', deleted: false })
                                       .select(
                                         'work_centers.name as wc_name',
                                         'work_centers.code as wc_code',
                                         'COUNT(routing_operations.id) as operations_count',
                                         'SUM(routing_operations.setup_time_minutes) as total_setup',
                                         'AVG(routing_operations.run_time_per_unit_minutes) as avg_run_time',
                                         'SUM(routing_operations.labor_cost_per_unit) as total_labor_cost',
                                         'SUM(routing_operations.overhead_cost_per_unit) as total_overhead_cost'
                                       )
                                       .group('work_centers.id, work_centers.name, work_centers.code')
                                       .order('operations_count DESC')
    
    respond_to do |format|
      format.html
      format.csv { send_data generate_operations_summary_csv, filename: "operations_summary_#{Date.today}.csv" }
    end
  end
  
  private
  
  def calculate_utilization_score(work_center)
    # Simple score based on number of active operations using this WC
    operations_count = work_center.routing_operations
                                  .joins(:routing)
                                  .where(routings: { status: 'ACTIVE', deleted: false })
                                  .count
    
    # Score out of 100
    [operations_count * 10, 100].min
  end
  
  def calculate_bottleneck_percentage(routing)
    return 0 if routing.routing_operations.empty?
    
    critical_op = routing.critical_operation
    return 0 unless critical_op
    
    total_time = routing.routing_operations.sum(&:total_time_per_unit)
    return 0 if total_time.zero?
    
    ((critical_op.total_time_per_unit / total_time) * 100).round(1)
  end
  
  def calculate_efficiency_score(routing)
    # Simple efficiency score based on time and cost
    # Lower time and cost = higher score
    time_score = 100 - [routing.total_run_time_per_unit_minutes, 100].min
    cost_score = 100 - [routing.total_cost_per_unit, 100].min
    
    ((time_score + cost_score) / 2).round(1)
  end
  
  # CSV Generators
  def generate_wc_utilization_csv
    CSV.generate do |csv|
      csv << ['Work Center Code', 'Work Center Name', 'Type', 'Total Operations', 'Active Operations', 'Total Setup Time (min)', 'Avg Run Time (min)', 'Utilization Score']
      
      @utilization_data.each do |data|
        wc = data[:work_center]
        csv << [
          wc.code,
          wc.name,
          wc.type_label,
          data[:total_operations],
          data[:active_operations],
          data[:total_setup_time].round(2),
          data[:avg_run_time],
          data[:utilization_score]
        ]
      end
    end
  end
  
  def generate_cost_analysis_csv
    CSV.generate do |csv|
      csv << ['Product Code', 'Product Name', 'Routing Code', 'Material Cost', 'Labor Cost', 'Overhead Cost', 'Total Processing Cost', 'Total Product Cost', 'Operations Count']
      
      @cost_analysis.each do |data|
        routing = data[:routing]
        csv << [
          routing.product.code,
          routing.product.name,
          routing.code,
          data[:material_cost].round(2),
          data[:labor_cost].round(2),
          data[:overhead_cost].round(2),
          data[:total_processing_cost].round(2),
          data[:total_product_cost].round(2),
          data[:operations_count]
        ]
      end
    end
  end
  
  def generate_time_analysis_csv
    CSV.generate do |csv|
      csv << ['Product Code', 'Product Name', 'Routing Code', 'Setup Time (min)', 'Run Time/Unit (min)', 'Wait Time (min)', 'Move Time (min)', 'Total Time/Unit (min)', 'Operations Count', 'Time for 100 units (hours)']
      
      @time_analysis.each do |data|
        routing = data[:routing]
        csv << [
          routing.product.code,
          routing.product.name,
          routing.code,
          data[:setup_time].round(2),
          data[:run_time_per_unit].round(2),
          data[:wait_time].round(2),
          data[:move_time].round(2),
          data[:total_time_per_unit].round(2),
          data[:operations_count],
          (data[:time_for_batches][:batch_100] / 60.0).round(2)
        ]
      end
    end
  end
  
  def generate_comparison_csv
    CSV.generate do |csv|
      csv << ['Product Code', 'Product Name', 'Routing Code', 'Routing Name', 'Status', 'Operations Count', 'Total Time/Unit (min)', 'Total Cost/Unit', 'Efficiency Score']
      
      @comparison_data.each do |product_id, routings_data|
        product = Product.find(product_id)
        routings_data.each do |data|
          routing = data[:routing]
          csv << [
            product.code,
            product.name,
            routing.code,
            routing.name,
            routing.status,
            data[:operations_count],
            data[:total_time].round(2),
            data[:total_cost].round(2),
            data[:efficiency_score]
          ]
        end
      end
    end
  end
  
  def generate_operations_summary_csv
    CSV.generate do |csv|
      csv << ['Work Center Code', 'Work Center Name', 'Operations Count', 'Total Setup Time (min)', 'Avg Run Time (min)', 'Total Labor Cost', 'Total Overhead Cost']
      
      @operations_data.each do |data|
        csv << [
          data.wc_code,
          data.wc_name,
          data.operations_count,
          data.total_setup.round(2),
          data.avg_run_time.round(2),
          data.total_labor_cost.round(2),
          data.total_overhead_cost.round(2)
        ]
      end
    end
  end
end
