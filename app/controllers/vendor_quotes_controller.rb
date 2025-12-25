# frozen_string_literal: true

# ============================================================================
# FILE: app/controllers/vendor_quotes_controller.rb
# Vendor Quote Management Controller
# Handles quote entry by buyer for suppliers
# ============================================================================

class VendorQuotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rfq
  before_action :set_vendor_quote, only: [:show, :edit, :update, :destroy]
  
  # GET /rfqs/:rfq_id/vendor_quotes
  def index
    @vendor_quotes = @rfq.vendor_quotes.includes(:supplier, :rfq_item).latest
    
    respond_to do |format|
      format.html
      format.json { render json: @vendor_quotes }
    end
  end
  
  # GET /rfqs/:rfq_id/vendor_quotes/:id
  def show
    respond_to do |format|
      format.html
      format.json { render json: @vendor_quote }
      format.pdf do
        render pdf: "Quote_#{@vendor_quote.quote_number}",
               template: 'vendor_quotes/show_pdf',
               layout: 'pdf'
      end
    end
  end
  
  # GET /rfqs/:rfq_id/vendor_quotes/new
  def new
    # Get supplier from params
    @supplier = Supplier.find(params[:supplier_id]) if params[:supplier_id]
    
    unless @supplier
      flash[:error] = "Please specify a supplier"
      redirect_to rfq_path(@rfq) and return
    end
    
    # Get available items (not yet quoted by this supplier)
    @available_items = @rfq.rfq_items.where.not(
      id: VendorQuote.where(rfq: @rfq, supplier: @supplier).select(:rfq_item_id)
    )
    
    if @available_items.empty?
      flash[:warning] = "All items already have quotes from #{@supplier.display_name}"
      redirect_to rfq_path(@rfq) and return
    end
    
    # Build new quote
    @rfq_item = params[:rfq_item_id] ? @rfq.rfq_items.find(params[:rfq_item_id]) : @available_items.first
    @vendor_quote = VendorQuote.new(
      rfq: @rfq,
      supplier: @supplier,
      rfq_item: @rfq_item,
      quote_date: Date.current,
      quote_valid_until: 30.days.from_now,
      currency: 'USD',
      can_meet_required_date: true,
      meets_specifications: true
    )
    
    respond_to do |format|
      format.html
      format.json { render json: @vendor_quote }
    end
  end
  
  # POST /rfqs/:rfq_id/vendor_quotes
  def create
    @rfq_item = @rfq.rfq_items.find_by(id: vendor_quote_params[:rfq_item_id])
    @supplier = Supplier.find_by(id: vendor_quote_params[:supplier_id])
    @rfq_supplier = @rfq.rfq_suppliers.find_by!(supplier: @supplier)
    
    # Check if quote already exists
    existing_quote = VendorQuote.find_by(
      rfq: @rfq,
      supplier: @supplier,
      rfq_item: @rfq_item
    )
    
    if existing_quote
      flash[:error] = "Quote already exists for this item from #{@supplier.display_name}"
      redirect_to rfq_path(@rfq, anchor: 'quotes') and return
    end
    
    # Build new quote
    @vendor_quote = VendorQuote.new(vendor_quote_params)
    @vendor_quote.rfq = @rfq
    @vendor_quote.rfq_supplier = @rfq_supplier
    @vendor_quote.rfq_item = @rfq_item
    @vendor_quote.supplier = @supplier
    @vendor_quote.created_by = current_user
    
    # Generate quote number if not present
    @vendor_quote.quote_number ||= generate_quote_number(@supplier)
    
    # Calculate total price
    calculate_total_price!(@vendor_quote)
    
    # Calculate scores
    calculate_scores!(@vendor_quote)
    if @vendor_quote.save
      # Update RFQ supplier status
      update_rfq_supplier_status(@supplier)
      
      # Update RFQ counter caches
      update_rfq_counters!
      
      # Recalculate all quotes for this item (rankings)
      recalculate_item_quotes!(@rfq_item)
      
      # Optional: Send notification email to buyer
      # RfqMailer.quote_received_notification(@rfq, @vendor_quote).deliver_later
      
      flash[:success] = "Quote from #{@supplier.display_name} saved successfully"
      
      respond_to do |format|
        format.html { redirect_to rfq_path(@rfq, anchor: 'quotes') }
        format.json { render json: { success: true, quote: @vendor_quote }, status: :created }
      end
    else
      flash[:error] = @vendor_quote.errors.full_messages.join(', ')
      
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @vendor_quote.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
  
  # GET /rfqs/:rfq_id/vendor_quotes/:id/edit
  def edit
    @supplier = @vendor_quote.supplier
    @rfq_item = @vendor_quote.rfq_item
    @available_items = [@rfq_item] # Can only edit current item
    
    respond_to do |format|
      format.html
      format.json { render json: @vendor_quote }
    end
  end
  
  # PATCH/PUT /rfqs/:rfq_id/vendor_quotes/:id
  def update
    @vendor_quote.updated_by = current_user
    
    # Store old values for comparison
    old_unit_price = @vendor_quote.unit_price
    old_lead_time = @vendor_quote.lead_time_days
    
    # Update attributes
    @vendor_quote.assign_attributes(vendor_quote_params)
    
    # Recalculate if prices or lead time changed
    if @vendor_quote.unit_price != old_unit_price || 
       @vendor_quote.lead_time_days != old_lead_time
      calculate_total_price!(@vendor_quote)
      calculate_scores!(@vendor_quote)
    end
    
    if @vendor_quote.save
      # Recalculate all quotes for this item
      recalculate_item_quotes!(@vendor_quote.rfq_item)
      
      flash[:success] = "Quote updated successfully"
      
      respond_to do |format|
        format.html { redirect_to rfq_path(@rfq, anchor: 'quotes') }
        format.json { render json: { success: true, quote: @vendor_quote } }
      end
    else
      flash[:error] = @vendor_quote.errors.full_messages.join(', ')
      
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @vendor_quote.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
  
  # DELETE /rfqs/:rfq_id/vendor_quotes/:id
  def destroy
    supplier = @vendor_quote.supplier
    rfq_item = @vendor_quote.rfq_item
    
    @vendor_quote.destroy!
    
    # Update RFQ supplier status
    update_rfq_supplier_status(supplier)
    
    # Update RFQ counter caches
    update_rfq_counters!
    
    # Recalculate remaining quotes for this item
    recalculate_item_quotes!(rfq_item)
    
    flash[:success] = "Quote deleted successfully"
    redirect_to rfq_path(@rfq, anchor: 'quotes')
  end
  
  private
  
  def set_rfq
    @rfq = Rfq.non_deleted.find(params[:rfq_id])
  end
  
  def set_vendor_quote
    @vendor_quote = VendorQuote.find(params[:id])
  end
  
  def vendor_quote_params
    params.require(:vendor_quote).permit(
      :supplier_id,
      :rfq_item_id,
      :quote_number,
      :quote_date,
      :quote_valid_until,
      :unit_price,
      :currency,
      :lead_time_days,
      :promised_delivery_date,
      :can_meet_required_date,
      :minimum_order_quantity,
      :order_multiple,
      :units_per_package,
      :tooling_cost,
      :setup_cost,
      :shipping_cost,
      :other_charges,
      :payment_terms,
      :warranty_period,
      :special_conditions,
      :meets_specifications,
      :certifications_included,
      :samples_available,
      :specification_deviations,
      :partial_delivery_offered,
      :notes,
      :volume_price_break_1_qty,
      :volume_price_break_1_price,
      :volume_price_break_2_qty,
      :volume_price_break_2_price,
      :volume_price_break_3_qty,
      :volume_price_break_3_price
    )
  end
  
  # ============================================================================
  # HELPER METHODS
  # ============================================================================
  
  # Generate unique quote number
  def generate_quote_number(supplier)
    prefix = supplier.code || supplier.id.to_s.rjust(3, '0')
    date_part = Date.current.strftime('%Y%m%d')
    sequence = VendorQuote.where(supplier: supplier).count + 1
    
    "QT-#{prefix}-#{date_part}-#{sequence.to_s.rjust(3, '0')}"
  end
  
  # Calculate total price
  def calculate_total_price!(quote)
    base_price = (quote.unit_price || 0) * (quote.rfq_item.quantity_requested || 0)
    
    additional_costs = (quote.tooling_cost || 0) + 
                       (quote.setup_cost || 0) + 
                       (quote.shipping_cost || 0) + 
                       (quote.other_charges || 0)
    
    quote.total_price = base_price + additional_costs
    quote
  end
  
  # Calculate scores for quote
  def calculate_scores!(quote)
    rfq = quote.rfq
    rfq_item = quote.rfq_item
    
    # Get all quotes for this item
    all_quotes = VendorQuote.where(rfq: rfq, rfq_item: rfq_item)
    
    # Price Score (lower price = higher score)
    all_prices = all_quotes.pluck(:unit_price).compact
    if all_prices.any?
      min_price = all_prices.min
      quote.price_score = min_price > 0 ? (min_price / quote.unit_price.to_f * 100).round(0) : 100
    else
      quote.price_score = 100
    end
    
    # Delivery Score (faster delivery = higher score)
    all_lead_times = all_quotes.pluck(:lead_time_days).compact
    if all_lead_times.any?
      min_lead_time = all_lead_times.min
      quote.delivery_score = quote.lead_time_days > 0 ? (min_lead_time.to_f / quote.lead_time_days * 100).round(0) : 100
    else
      quote.delivery_score = 100
    end
    
    # Quality Score (from supplier rating)
    quote.quality_score = quote.supplier.quality_score || 80
    
    # Service Score (from supplier rating)
    quote.service_score = quote.supplier.service_score || 80
    
    # Calculate overall score (weighted average)
    weights = rfq.weights || { price: 40, delivery: 20, quality: 25, service: 15 }
    
    quote.overall_score = (
      (quote.price_score || 0) * weights[:price] +
      (quote.delivery_score || 0) * weights[:delivery] +
      (quote.quality_score || 0) * weights[:quality] +
      (quote.service_score || 0) * weights[:service]
    ) / 100.0
    
    quote.overall_score = quote.overall_score.round(0)
    
    quote
  end
  
  # Update rankings for all quotes of an item
  def recalculate_item_quotes!(rfq_item)
    quotes = VendorQuote.where(rfq: @rfq, rfq_item: rfq_item)
    
    quotes.each do |quote|
      calculate_scores!(quote)
      
      # Determine rankings
      quote.is_lowest_price = (quotes.order(unit_price: :asc).first&.id == quote.id)
      quote.is_fastest_delivery = (quotes.order(lead_time_days: :asc).first&.id == quote.id)
      quote.is_best_value = (quotes.order(overall_score: :desc).first&.id == quote.id)
      quote.is_recommended = quote.is_best_value
      
      # Set overall rank
      ranked_quotes = quotes.order(overall_score: :desc).to_a
      quote.overall_rank = ranked_quotes.index(quote) + 1
      
      quote.save!
    end
  end
  
  # Update RFQ supplier status
  def update_rfq_supplier_status(supplier)
    rfq_supplier = @rfq.rfq_suppliers.find_by(supplier: supplier)
    return unless rfq_supplier
    
    # Count quotes from this supplier
    quote_count = VendorQuote.where(rfq: @rfq, supplier: supplier).count
    total_quoted = VendorQuote.where(rfq: @rfq, supplier: supplier).sum(:total_price)
    
    if quote_count > 0
      rfq_supplier.update!(
        invitation_status: 'QUOTED',
        quoted_at: Time.current,
        items_quoted_count: quote_count,
        total_quoted_amount: total_quoted
      )
    else
      rfq_supplier.update!(
        invitation_status: 'INVITED',
        quoted_at: nil,
        items_quoted_count: 0,
        total_quoted_amount: nil
      )
    end
  end
  
  # Update RFQ counter caches
  def update_rfq_counters!
    @rfq.update!(
      quotes_received_count: @rfq.vendor_quotes.count
    )
    
    # Update status if needed
    if @rfq.quotes_received_count > 0 && @rfq.sent?
      @rfq.update!(status: 'RESPONSES_RECEIVED')
    end
  end
end