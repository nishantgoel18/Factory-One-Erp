# app/controllers/production_calculator_controller.rb

class ProductionCalculatorController < ApplicationController
  before_action :authenticate_user!
  def index
    @products = Product.where(deleted: false)
                       .where(product_type: ["Finished Goods", "Semi-Finished Goods"])
                       .order(:name)
  end
  
  def calculate
    @product = Product.find(params[:product_id])
    @quantity = params[:quantity].to_i
    
    if @product.ready_for_production?
      @results = calculate_production_details(@product, @quantity)
      render json: @results
    else
      render json: { error: "Product not ready for production" }, status: :unprocessable_entity
    end
  end
  
  private
  
  def calculate_production_details(product, quantity)
    routing = product.default_routing
    bom = product.bill_of_materials.find_by(is_default: true, deleted: false)
    
    # Material costs (from BOM)
    material_cost_per_unit = product.standard_cost.to_d
    total_material_cost = material_cost_per_unit * quantity
    
    # Processing costs (from Routing)
    setup_cost = routing.routing_operations.sum { |op| op.calculate_setup_cost }
    run_cost_per_unit = routing.total_cost_per_unit
    total_run_cost = run_cost_per_unit * quantity
    total_processing_cost = setup_cost + total_run_cost
    
    # Time calculations
    setup_time = routing.total_setup_time_minutes
    run_time_per_unit = routing.total_run_time_per_unit_minutes
    total_run_time = run_time_per_unit * quantity
    total_time = setup_time + total_run_time
    
    # Lead time (in days, assuming 8-hour workday)
    lead_time_days = (total_time / 60.0 / 8.0).ceil
    
    # Grand totals
    total_cost = total_material_cost + total_processing_cost
    cost_per_unit = total_cost / quantity
    
    {
      product: {
        code: product.sku,
        name: product.name
      },
      quantity: quantity,
      material: {
        cost_per_unit: material_cost_per_unit.round(2),
        total_cost: total_material_cost.round(2),
        components: bom.bom_items.map do |item|
          {
            component: item.component.name,
            quantity: item.quantity,
            cost: (item.quantity * item.component.standard_cost.to_d).round(2)
          }
        end
      },
      processing: {
        setup_cost: setup_cost.round(2),
        run_cost_per_unit: run_cost_per_unit.round(2),
        total_run_cost: total_run_cost.round(2),
        total_cost: total_processing_cost.round(2),
        operations: routing.routing_operations.order(:operation_sequence).map do |op|
          {
            sequence: op.operation_sequence,
            name: op.operation_name,
            work_center: op.work_center.name,
            setup_cost: op.calculate_setup_cost.round(2),
            cost_per_unit: op.total_cost_per_unit.round(2)
          }
        end
      },
      time: {
        setup_time_minutes: setup_time.round(1),
        run_time_per_unit_minutes: run_time_per_unit.round(1),
        total_run_time_minutes: total_run_time.round(1),
        total_time_minutes: total_time.round(1),
        total_time_hours: (total_time / 60.0).round(1),
        lead_time_days: lead_time_days
      },
      totals: {
        material_cost: total_material_cost.round(2),
        processing_cost: total_processing_cost.round(2),
        total_cost: total_cost.round(2),
        cost_per_unit: cost_per_unit.round(2)
      }
    }
  end
end