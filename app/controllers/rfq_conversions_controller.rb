class RfqConversionsController < ApplicationController
  before_action :set_rfq
  before_action :check_conversion_eligibility, only: [:new, :create]
  
  # ===================================
  # GET /rfqs/:rfq_id/conversion/new
  # ===================================
  # Shows conversion preview/confirmation form
  def new
    @items_by_supplier = @rfq.items_by_supplier
    @warehouses = Warehouse.where(is_active: true).order(:name)
    
    # Calculate preview totals
    @conversion_preview = calculate_conversion_preview
  end
  
  # ===================================
  # POST /rfqs/:rfq_id/conversion
  # ===================================
  # Executes the conversion
  def create
    @warehouse = Warehouse.find(params[:warehouse_id])
    
    # Get conversion options
    conversion_options = {
      payment_terms: params[:payment_terms],
      expected_date: params[:expected_date].present? ? Date.parse(params[:expected_date]) : nil,
      notes: params[:additional_notes]
    }
    
    # Execute conversion
    @purchase_orders = @rfq.convert_to_purchase_orders!(
      user: current_user,
      warehouse_id: @warehouse.id,
      **conversion_options
    )
    
    if @purchase_orders.present?
      flash[:success] = build_success_message(@purchase_orders)
      
      # Redirect based on number of POs created
      if @purchase_orders.count == 1
        redirect_to inventory_purchase_order_path(@purchase_orders.first)
      else
        redirect_to rfq_path(@rfq)
      end
    else
      flash.now[:danger] = "Failed to convert RFQ to Purchase Order(s). Please try again."
      @items_by_supplier = @rfq.items_by_supplier
      @warehouses = Warehouse.where(is_active: true).order(:name)
      @conversion_preview = calculate_conversion_preview
      render :new
    end
    
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:danger] = "Conversion failed: #{e.message}"
    @items_by_supplier = @rfq.items_by_supplier
    @warehouses = Warehouse.where(is_active: true).order(:name)
    @conversion_preview = calculate_conversion_preview
    render :new
    
  rescue StandardError => e
    Rails.logger.error "RFQ Conversion Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    flash.now[:danger] = "An unexpected error occurred: #{e.message}"
    @items_by_supplier = @rfq.items_by_supplier
    @warehouses = Warehouse.where(is_active: true).order(:name)
    @conversion_preview = calculate_conversion_preview
    render :new
  end
  
  private
  
  def set_rfq
    @rfq = Rfq.find(params[:rfq_id])
  end
  
  def check_conversion_eligibility
    unless @rfq.can_convert_to_po?
      flash[:warning] = "This RFQ cannot be converted to Purchase Order. " \
                       "Ensure it is AWARDED and has selected items."
      redirect_to rfq_path(@rfq)
    end
  end
  
  # Calculate conversion preview data
  def calculate_conversion_preview
    items_by_supplier = @rfq.items_by_supplier
    preview = {
      suppliers: [],
      total_pos_to_create: items_by_supplier.keys.count,
      total_line_items: @rfq.selected_items.count,
      grand_total: BigDecimal("0")
    }
    
    items_by_supplier.each do |supplier_id, items|
      supplier = Supplier.find(supplier_id)
      
      supplier_data = {
        supplier: supplier,
        item_count: items.count,
        items: items,
        subtotal: BigDecimal("0")
      }
      
      items.each do |item|
        line_total = (item.selected_unit_price || 0) * (item.quantity_requested || 0)
        supplier_data[:subtotal] += line_total
      end
      
      preview[:grand_total] += supplier_data[:subtotal]
      preview[:suppliers] << supplier_data
    end
    
    preview
  end
  
  # Build success flash message
  def build_success_message(purchase_orders)
    if purchase_orders.count == 1
      po = purchase_orders.first
      "✓ Purchase Order #{po.po_number} created successfully from RFQ #{@rfq.rfq_number}."
    else
      po_numbers = purchase_orders.map(&:po_number).join(', ')
      "✓ #{purchase_orders.count} Purchase Orders created successfully: #{po_numbers}"
    end
  end
end