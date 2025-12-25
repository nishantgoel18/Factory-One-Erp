# frozen_string_literal: true

# ============================================================================
# CONTROLLER: RfqsController
# Complete RFQ management with quote comparison and vendor selection
# ============================================================================
class RfqsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rfq, only: [:show, :edit, :update, :destroy, :send_to_suppliers,
                                  :comparison, :award, :close, :cancel]
  
  # ============================================================================
  # INDEX - List all RFQs
  # ============================================================================
  def index
    @rfqs = Rfq.non_deleted.includes(:created_by, :awarded_supplier, :buyer_assigned)
    
    # Filters
    @rfqs = @rfqs.where(status: params[:status]) if params[:status].present?
    @rfqs = @rfqs.where(is_urgent: true) if params[:urgent] == 'true'
    @rfqs = @rfqs.where(buyer_assigned: current_user) if params[:my_rfqs] == 'true'
    
    # Search
    if params[:search].present?
      @rfqs = @rfqs.where('rfq_number ILIKE ? OR title ILIKE ?', 
                          "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    # Sorting
    @rfqs = @rfqs.order(created_at: :desc)
    @rfqs = @rfqs.page(params[:page]).per(20)
    
    # Statistics
    @stats = {
      total: Rfq.non_deleted.count,
      draft: Rfq.draft.count,
      active: Rfq.active.count,
      awarded: Rfq.awarded.count,
      my_rfqs: Rfq.where(buyer_assigned: current_user).active.count
    }
    
    respond_to do |format|
      format.html
      format.json { render json: @rfqs }
      format.csv { send_data generate_csv, filename: "rfqs-#{Date.current}.csv" }
    end
  end
  
  # ============================================================================
  # SHOW - RFQ detail with all information
  # ============================================================================
  def show
    @rfq_items = @rfq.rfq_items.includes(:product, vendor_quotes: :supplier).order(:line_number)
    @rfq_suppliers = @rfq.rfq_suppliers.includes(:supplier, :supplier_contact).order(:invited_at)
    @vendor_quotes = @rfq.vendor_quotes.latest.includes(:supplier, :rfq_item)
    
    respond_to do |format|
      format.html
      format.csv { send_data generate_rfq_csv(@rfq), filename: "RFQ_#{@rfq.rfq_number}_#{Date.current}.csv" }
      format.json { render json: @rfq.as_json(include: [:rfq_items, :rfq_suppliers, :vendor_quotes]) }
    end
  end
  
  # ============================================================================
  # NEW - Form for creating new RFQ
  # ============================================================================
  def new
    @rfq = Rfq.new(
      rfq_date: Date.current,
      due_date: 14.days.from_now,
      response_deadline: 14.days.from_now,
      created_by: current_user,
      buyer_assigned: current_user
    )
    @rfq.rfq_items.build
  end
  
  # ============================================================================
  # CREATE - Save new RFQ
  # ============================================================================
  def create
    @rfq = Rfq.new(rfq_params)
    @rfq.created_by = current_user
    @rfq.buyer_assigned ||= current_user
    
    respond_to do |format|
      if @rfq.save
        format.html { redirect_to @rfq, notice: 'RFQ created successfully.' }
        format.json { render json: @rfq, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rfq.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # ============================================================================
  # EDIT - Form for editing RFQ
  # ============================================================================
  def edit
    # Can only edit DRAFT RFQs
    unless @rfq.draft?
      redirect_to @rfq, alert: 'Cannot edit RFQ after it has been sent.'
    end
  end
  
  # ============================================================================
  # UPDATE - Save RFQ changes
  # ============================================================================
  def update
    @rfq.updated_by = current_user
    
    respond_to do |format|
      if @rfq.update(rfq_params)
        format.html { redirect_to @rfq, notice: 'RFQ updated successfully.' }
        format.json { render json: @rfq }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @rfq.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # ============================================================================
  # DESTROY - Soft delete RFQ
  # ============================================================================
  def destroy
    @rfq.soft_delete!(current_user)
    redirect_to rfqs_path, notice: 'RFQ deleted successfully.'
  end
  
  # ============================================================================
  # SEND TO SUPPLIERS - Send RFQ to invited suppliers
  # ============================================================================
  def send_to_suppliers
    if @rfq.send_to_suppliers!(current_user)
      redirect_to @rfq, notice: 'RFQ sent to suppliers successfully.'
    else
      redirect_to @rfq, alert: 'Cannot send RFQ. Please add items and invite suppliers.'
    end
  end

  def remind_supplier
    @rfq = Rfq.non_deleted.find(params[:id])
    supplier_id = params[:supplier_id]
    rfq_supplier = @rfq.rfq_suppliers.find_by(supplier_id: supplier_id)
    
    if rfq_supplier.nil?
      flash[:error] = "Supplier not found"
      redirect_to rfq_path(@rfq) and return
    end
    
    supplier = rfq_supplier.supplier
    contact = rfq_supplier.supplier_contact || supplier.primary_contact
    
    if contact && contact.email.present?
      begin
        RfqMailer.rfq_reminder(@rfq, supplier, contact).deliver_later
        
        # Update tracking
        @rfq.increment!(:reminder_count) if @rfq.respond_to?(:reminder_count)
        @rfq.update(last_reminder_sent_at: Time.current) if @rfq.respond_to?(:last_reminder_sent_at)
        
        flash[:success] = "Reminder sent to #{supplier.display_name}"
      rescue => e
        flash[:error] = "Failed to send reminder: #{e.message}"
      end
    else
      flash[:error] = "No email address found for #{supplier.display_name}"
    end
    
    redirect_to rfq_path(@rfq, anchor: 'suppliers')
  end
  
  # ============================================================================
  # COMPARISON DASHBOARD - THE STAR FEATURE! ⭐
  # ============================================================================
  def comparison
    @rfq = Rfq.find(params[:id])
    
    # Get all RFQ items with their details
    @rfq_items = @rfq.rfq_items.includes(:product)
    
    # Get all invited suppliers who have submitted quotes
    @invited_suppliers = @rfq.rfq_suppliers.includes(:supplier)
    
    # Get all vendor quotes organized by item and supplier
    # This will help us build the comparison matrix
    @vendor_quotes = @rfq.vendor_quotes
                         .includes(:rfq_item, :supplier, :rfq_supplier)
                         .order('rfq_items.line_number, suppliers.name')
    
    # Build comparison data structure for easier template rendering
    @comparison_data = build_comparison_matrix
    
    # Calculate totals per supplier
    @supplier_totals = calculate_supplier_totals
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "RFQ_#{@rfq.rfq_number}_Comparison",
               template: 'rfqs/comparison_pdf',
               layout: 'pdf'
      end
    end
  end
  
  # ============================================================================
  # AWARD - Award RFQ to selected supplier
  # ============================================================================
  def award
    supplier = Supplier.find(params[:supplier_id])
    
    if @rfq.award_to_supplier!(supplier, current_user, reason: params[:reason])
      redirect_to @rfq, notice: "RFQ awarded to #{supplier.display_name}."
    else
      redirect_to @rfq, alert: 'Failed to award RFQ.'
    end
  end
  
  # ============================================================================
  # CLOSE - Close RFQ
  # ============================================================================
  def close
    @rfq.close!(current_user, reason: params[:reason])
    redirect_to @rfq, notice: 'RFQ closed successfully.'
  end
  
  # ============================================================================
  # CANCEL - Cancel RFQ
  # ============================================================================
  def cancel
    @rfq = Rfq.find(params[:id])
  
    unless @rfq.can_cancel_rfq?
      redirect_to @rfq, alert: 'Cannot cancel this RFQ. Purchase orders have already been confirmed or received.'
      return
    end
    
    begin
      ActiveRecord::Base.transaction do
        # If awarded, check for draft POs and delete them
        if @rfq.status == 'AWARDED'
          draft_pos = PurchaseOrder.where(rfq_id: @rfq.id, status: 'DRAFT')
          draft_pos.destroy_all
        end
        
        # Unselect all vendor quotes
        @rfq.vendor_quotes.update_all(is_selected: false)
        
        # Update RFQ status
        @rfq.update!(
          status: 'CANCELLED',
          cancelled_at: Time.current,
          cancelled_by_id: current_user.id,
          cancellation_reason: params[:cancellation_reason]
        )
        
        # Optional: Notify suppliers
        # RfqMailer.cancellation_notice(@rfq).deliver_later
      end
      
      redirect_to @rfq, notice: 'RFQ has been cancelled successfully.'
    rescue => e
      redirect_to @rfq, alert: "Error cancelling RFQ: #{e.message}"
    end
  end
  
  # ============================================================================
  # INVITE SUPPLIERS - Add suppliers to RFQ
  # ============================================================================
  def invite_suppliers
    @rfq = Rfq.find(params[:id])
    supplier_ids = params[:supplier_ids] || []
    
    @rfq.invite_multiple_suppliers!(supplier_ids, current_user)
    
    redirect_to @rfq, notice: "#{supplier_ids.count} suppliers invited."
  end
  
  # ============================================================================
  # SELECT QUOTES - Select winning quotes for each line item
  # ============================================================================
  def select_quotes
    @rfq = Rfq.find(params[:id])
    selected_quote_ids = params[:selected_quotes] || []
    
    if selected_quote_ids.empty?
      redirect_to comparison_rfq_path(@rfq), alert: 'Please select at least one quote to award.'
      return
    end
    
    begin
      ActiveRecord::Base.transaction do
        # Mark selected quotes as winners
        VendorQuote.where(id: selected_quote_ids).update_all(is_selected: true)
        
        # Mark other quotes for same items as not selected
        selected_quotes = VendorQuote.where(id: selected_quote_ids)
        item_ids = selected_quotes.pluck(:rfq_item_id).uniq
        
        VendorQuote.where(rfq_item_id: item_ids)
                   .where.not(id: selected_quote_ids)
                   .update_all(is_selected: false)
        
        # Update RFQ status
        @rfq.update!(status: 'awarded')
      end
      
      redirect_to @rfq, notice: 'Selected quotes have been awarded successfully!'
    rescue => e
      redirect_to comparison_rfq_path(@rfq), alert: "Error awarding quotes: #{e.message}"
    end
  end
  
  # ============================================================================
  # AUTOCOMPLETE - For search
  # ============================================================================
  def autocomplete
    rfqs = Rfq.non_deleted
               .where('rfq_number ILIKE ? OR title ILIKE ?', 
                      "%#{params[:term]}%", "%#{params[:term]}%")
               .limit(10)
    
    results = rfqs.map { |r| { id: r.id, label: r.display_name, value: r.rfq_number } }
    render json: results
  end


  
  private
  def calculate_supplier_totals
    totals = {}
    
    @invited_suppliers.each do |rfq_supplier|
      supplier_id = rfq_supplier.supplier_id
      
      # Sum all quoted amounts for this supplier
      # Using RFQ item quantity (not vendor's minimum_order_quantity)
      total = 0
      
      @vendor_quotes.where(supplier_id: supplier_id).each do |quote|
        # Get the original requested quantity from RFQ item
        rfq_item_qty = quote.rfq_item.quantity_requested
        total += (rfq_item_qty * quote.unit_price)
      end
      
      totals[supplier_id] = total
    end
    
    totals
  end

  def build_comparison_matrix
    # Structure: { rfq_item_id => { supplier_id => vendor_quote } }
    matrix = {}
    
    @rfq_items.each do |item|
      matrix[item.id] = {}
      
      @invited_suppliers.each do |rfq_supplier|
        # Find quote for this item from this supplier
        quote = @vendor_quotes.find do |vq|
          vq.rfq_item_id == item.id && vq.supplier_id == rfq_supplier.supplier_id
        end
        
        matrix[item.id][rfq_supplier.supplier_id] = quote
      end
    end
    
    matrix
  end
  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================
  def set_rfq
    @rfq = Rfq.non_deleted.find(params[:id])
  end
  
  def rfq_params
    params.require(:rfq).permit(
      :title, :description, :rfq_date, :due_date, :response_deadline,
      :required_delivery_date, :is_urgent, :priority,
      :terms_and_conditions, :payment_terms, :delivery_terms,
      :quality_requirements, :special_instructions, :incoterms,
      :estimated_budget, :comparison_basis,
      :auto_email_enabled, :send_to_all_contacts,
      :requires_technical_drawings, :requires_certifications, :requires_samples,
      :requester_id, :buyer_assigned_id, :approver_id,
      :internal_notes, :buyer_notes,
      rfq_items_attributes: [
        :id, :product_id, :line_number, :item_description,
        :quantity_requested, :unit_of_measure,
        :technical_specifications, :quality_requirements,
        :material_grade, :finish_requirement, :dimensional_requirements,
        :color_specification, :packaging_requirements,
        :requires_testing, :testing_standards,
        :required_delivery_date, :partial_delivery_acceptable,
        :delivery_location, :shipping_instructions,
        :customer_part_number, :drawing_number, :drawing_revision,
        :target_unit_price, :is_critical_item, :is_long_lead_item,
        :buyer_notes, :engineering_notes, :_destroy
      ],
      rfq_suppliers_attributes: [
        :id, :_destroy, :supplier_contact_id, :supplier_id
      ]
    )
  end
  
  def generate_rfq_csv(rfq)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      # Header section
      csv << ['RFQ HEADER INFORMATION']
      csv << ['RFQ Number', rfq.rfq_number]
      csv << ['Title', rfq.title]
      csv << ['Status', rfq.status]
      csv << ['RFQ Date', rfq.rfq_date.strftime('%Y-%m-%d')]
      csv << ['Due Date', rfq.due_date.strftime('%Y-%m-%d')]
      csv << ['Response Deadline', rfq.response_deadline.strftime('%Y-%m-%d')]
      csv << ['Urgent', rfq.is_urgent? ? 'YES' : 'NO']
      csv << ['Suppliers Invited', rfq.suppliers_invited_count]
      csv << ['Quotes Received', rfq.quotes_received_count]
      csv << ['Response Rate', "#{rfq.response_rate}%"]
      csv << []
      
      # Items section
      csv << ['RFQ ITEMS']
      csv << ['Line', 'Item Description', 'Product Code', 'Quantity', 'UOM', 'Target Price', 'Required Date', 'Critical']
      
      rfq.rfq_items.order(:line_number).each do |item|
        csv << [
          item.line_number,
          item.item_description,
          item.product&.sku,
          item.quantity_requested,
          item.unit_of_measure,
          item.target_unit_price,
          item.required_delivery_date&.strftime('%Y-%m-%d'),
          item.is_critical_item? ? 'YES' : 'NO'
        ]
      end
      
      csv << []
      
      # Suppliers section
      csv << ['INVITED SUPPLIERS']
      csv << ['Supplier Name', 'Contact', 'Email', 'Status', 'Quoted At', 'Response Time (hrs)', 'On Time']
      
      rfq.rfq_suppliers.includes(:supplier, :supplier_contact).each do |rfq_supplier|
        csv << [
          rfq_supplier.supplier.display_name,
          rfq_supplier.supplier_contact&.full_name,
          rfq_supplier.contact_email_used,
          rfq_supplier.invitation_status,
          rfq_supplier.quoted_at&.strftime('%Y-%m-%d %H:%M'),
          rfq_supplier.response_time_hours,
          rfq_supplier.responded_on_time ? 'YES' : 'NO'
        ]
      end
      
      csv << []
      
      # Quotes section
      if rfq.vendor_quotes.any?
        csv << ['RECEIVED QUOTES']
        csv << ['Supplier', 'Item', 'Quote #', 'Unit Price', 'Total Price', 'Lead Time', 'Overall Score', 'Selected']
        
        rfq.vendor_quotes.includes(:supplier, :rfq_item).order('overall_rank ASC').each do |quote|
          csv << [
            quote.supplier.display_name,
            quote.rfq_item.display_name,
            quote.quote_number,
            quote.unit_price,
            quote.total_price,
            "#{quote.lead_time_days} days",
            quote.overall_score,
            quote.is_selected ? 'YES' : 'NO'
          ]
        end
      end
      
      csv << []
      
      # Award information
      if rfq.awarded_supplier
        csv << ['AWARD INFORMATION']
        csv << ['Awarded To', rfq.awarded_supplier.display_name]
        csv << ['Award Date', rfq.award_date.strftime('%Y-%m-%d')]
        csv << ['Awarded Amount', rfq.awarded_total_amount]
        csv << ['Cost Savings', rfq.cost_savings]
        csv << ['Savings Percentage', "#{rfq.cost_savings_percentage}%"]
        csv << ['Award Reason', rfq.award_reason]
      end
    end
  end

  def generate_csv
    CSV.generate(headers: true) do |csv|
      csv << ['RFQ Number', 'Title', 'Status', 'RFQ Date', 'Due Date', 
              'Suppliers Invited', 'Quotes Received', 'Response Rate',
              'Lowest Quote', 'Awarded Supplier', 'Award Amount']
      
      @rfqs.each do |rfq|
        csv << [
          rfq.rfq_number,
          rfq.title,
          rfq.status,
          rfq.rfq_date,
          rfq.due_date,
          rfq.suppliers_invited_count,
          rfq.quotes_received_count,
          "#{rfq.response_rate}%",
          rfq.lowest_quote_amount,
          rfq.awarded_supplier&.display_name,
          rfq.awarded_total_amount
        ]
      end
    end
  end
end