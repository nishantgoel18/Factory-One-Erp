# app/controllers/inventory/dashboard_controller.rb

module Inventory
  class DashboardController < BaseController
    def index
      # Key Metrics
      @total_products = Product.where(deleted: false, is_stocked: true).count
      @total_warehouses = Warehouse.where(deleted: false, is_active: true).count
      @low_stock_count = low_stock_products.count
      @total_stock_value = calculate_total_stock_value
      
      # Recent Activities
      @recent_grns = GoodsReceipt.posted
                                 .order(posted_at: :desc)
                                 .limit(5)
                                 .includes(:warehouse, :supplier)
      
      @recent_issues = StockIssue.where(status: 'POSTED', deleted: false)
                                 .order(created_at: :desc)
                                 .limit(5)
                                 .includes(:warehouse)
      
      @pending_pos = PurchaseOrder.open_pos
                                  .order(expected_date: :asc)
                                  .limit(5)
                                  .includes(:supplier)
      
      # Stock Alerts
      @low_stock_items = low_stock_products
      @overdue_pos = PurchaseOrder.active
                                  .where('expected_date < ?', Date.current)
                                  .where(status: ['CONFIRMED', 'PARTIALLY_RECEIVED'])
                                  .count
      
      # Charts Data
      @stock_movement_data = stock_movement_chart_data
      @warehouse_stock_data = warehouse_stock_distribution
      @top_products_data = top_moving_products
    end
    
    private
    
    def low_stock_products
      Product.where(deleted: false, is_stocked: true)
             .where('reorder_point > 0')
             .select do |product|
               current_stock = StockLevel.where(product: product, deleted: false)
                                        .sum(:on_hand_qty)
               current_stock <= product.reorder_point
             end
    end
    
    def calculate_total_stock_value
      total = 0
      StockLevel.where(deleted: false).includes(:product).find_each do |level|
        product = level.product
        cost = product.standard_cost || 0
        total += (level.on_hand_qty * cost)
      end
      total.round(2)
    end
    
    def stock_movement_chart_data
      # Last 30 days movements
      data = []
      30.downto(0) do |i|
        date = i.days.ago.to_date
        
        receipts = StockTransaction.where(
          txn_type: 'RECEIPT',
          deleted: false,
          created_at: date.beginning_of_day..date.end_of_day
        ).sum(:quantity)
        
        issues = StockTransaction.where(
          txn_type: 'ISSUE',
          deleted: false,
          created_at: date.beginning_of_day..date.end_of_day
        ).sum(:quantity)
        
        data << {
          date: date.strftime('%b %d'),
          receipts: receipts.to_i,
          issues: issues.to_i
        }
      end
      data
    end
    
    def warehouse_stock_distribution
      warehouses = Warehouse.where(deleted: false, is_active: true)
      
      warehouses.map do |warehouse|
        total_qty = StockLevel.joins(:location)
                              .where(locations: { warehouse_id: warehouse.id })
                              .where(deleted: false)
                              .sum(:on_hand_qty)
        
        {
          name: warehouse.name,
          quantity: total_qty.to_i
        }
      end
    end
    
    def top_moving_products
      # Products with most transactions in last 30 days
      product_counts = StockTransaction.where(deleted: false)
                                      .where('created_at >= ?', 30.days.ago)
                                      .group(:product_id)
                                      .count
      
      top_product_ids = product_counts.sort_by { |_, count| -count }.first(10).map(&:first)
      
      Product.where(id: top_product_ids).map do |product|
        txn_count = product_counts[product.id] || 0
        {
          name: product.sku,
          transactions: txn_count
        }
      end
    end
  end
end