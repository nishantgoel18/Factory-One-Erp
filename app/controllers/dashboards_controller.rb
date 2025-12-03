class DashboardsController < ApplicationController
  before_action :authenticate_user!
  def home
    @routing_metrics = calculate_routing_metrics
    @work_center_metrics = calculate_work_center_metrics
    @production_readiness = calculate_production_readiness
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
end
