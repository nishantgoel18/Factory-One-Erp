# frozen_string_literal: true

# ============================================================================
# CONTROLLER: SuppliersController
# Main controller for supplier management with comprehensive features
# ============================================================================
class SuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier, only: [:show, :edit, :update, :destroy, :dashboard, 
                                       :approve, :suspend, :blacklist, :reactivate]
  before_action :check_deletion_allowed, only: [:destroy]
  
  # ============================================================================
  # INDEX - List all suppliers with filtering, search, sorting
  # ============================================================================
  def index
    @suppliers = Supplier.non_deleted.includes(:primary_contact, :primary_address, :default_buyer)
    
    # Apply filters
    apply_filters
    apply_search
    apply_sorting
    
    # Statistics
    @stats = calculate_statistics
    
    # Pagination
    @suppliers = @suppliers.page(params[:page]).per(20)
    
    respond_to do |format|
      format.html
      format.json { render json: @suppliers }
      format.csv { send_data generate_csv, filename: "suppliers-#{Date.current}.csv" }
      format.pdf { send_data generate_pdf, filename: "suppliers-#{Date.current}.pdf", type: 'application/pdf' }
    end
  end
  
  # ============================================================================
  # SHOW - Supplier detail page with full information
  # ============================================================================
  def show
    @addresses = @supplier.addresses.active.order(is_default: :desc)
    @contacts = @supplier.contacts.active.order(is_primary_contact: :desc)
    @product_catalog = @supplier.product_catalog.includes(:product).order('products.item_code')
    @quality_issues = @supplier.quality_issues.order(issue_date: :desc).limit(10)
    @recent_activities = @supplier.recent_activities(10)
    @documents = @supplier.active_documents.order(created_at: :desc)
    @performance_reviews = @supplier.performance_reviews.recent.limit(5)
    
    # Performance metrics for charts
    @performance_data = calculate_performance_data
    
    respond_to do |format|
      format.html
      format.json { render json: @supplier.as_json(include: [:addresses, :contacts, :products]) }
    end
  end
  
  # ============================================================================
  # NEW - Form for creating new supplier
  # ============================================================================
  def new
    @supplier = Supplier.new(
      is_active: true,
      supplier_status: 'PENDING',
      currency: 'USD',
      default_payment_terms: 'NET_30'
    )
    @supplier.addresses.build(is_active: true, address_type: 'PRIMARY_OFFICE')
    @supplier.contacts.build(is_active: true, contact_role: 'PRIMARY')
  end
  
  # ============================================================================
  # CREATE - Save new supplier
  # ============================================================================
  def create
    @supplier = Supplier.new(supplier_params)
    @supplier.created_by = current_user
    
    respond_to do |format|
      if @supplier.save
        @supplier.log_activity!('NOTE', 'Supplier Created', "Supplier #{@supplier.code} was created", current_user)
        
        format.html { redirect_to @supplier, notice: 'Supplier created successfully.' }
        format.json { render json: @supplier, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # ============================================================================
  # EDIT - Form for editing supplier
  # ============================================================================
  def edit
    # Form will be rendered
  end
  
  # ============================================================================
  # UPDATE - Save supplier changes
  # ============================================================================
  def update
    @supplier.updated_by = current_user
    
    respond_to do |format|
      if @supplier.update(supplier_params)
        format.html { redirect_to @supplier, notice: 'Supplier updated successfully.' }
        format.json { render json: @supplier }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # ============================================================================
  # DESTROY - Soft delete supplier
  # ============================================================================
  def destroy
    @supplier.soft_delete!(current_user)
    
    respond_to do |format|
      format.html { redirect_to suppliers_path, notice: 'Supplier deleted successfully.' }
      format.json { render json: { success: true, message: 'Supplier deleted successfully' } }
    end
  end
  
  # ============================================================================
  # DASHBOARD - Analytics and performance dashboard
  # ============================================================================
  def dashboard
    @chart_data = {
      revenue_trend: calculate_revenue_trend,
      order_trend: calculate_order_trend,
      quality_trend: calculate_quality_trend,
      delivery_performance: calculate_delivery_performance
    }
    
    @key_metrics = {
      total_spend: @supplier.total_purchase_value,
      ytd_spend: @supplier.purchase_value_ytd,
      total_orders: @supplier.total_po_count,
      on_time_rate: @supplier.on_time_delivery_rate,
      quality_rate: @supplier.quality_acceptance_rate,
      overall_rating: @supplier.overall_rating
    }
  end
  
  # ============================================================================
  # STATUS MANAGEMENT ACTIONS
  # ============================================================================
  def approve
    @supplier.approve!(current_user, notes: params[:notes])
    redirect_to @supplier, notice: 'Supplier approved successfully.'
  end
  
  def suspend
    @supplier.suspend!(params[:reason], current_user)
    redirect_to @supplier, alert: 'Supplier suspended.'
  end
  
  def blacklist
    @supplier.blacklist!(params[:reason], current_user)
    redirect_to @supplier, alert: 'Supplier blacklisted.'
  end
  
  def reactivate
    @supplier.reactivate!(current_user, notes: params[:notes])
    redirect_to @supplier, notice: 'Supplier reactivated successfully.'
  end
  
  # ============================================================================
  # AUTOCOMPLETE - For search/selection
  # ============================================================================
  def autocomplete
    suppliers = Supplier.non_deleted.active
                       .search(params[:term])
                       .limit(10)
    
    results = suppliers.map do |s|
      {
        id: s.id,
        code: s.code,
        name: s.display_name,
        label: s.full_display_name,
        value: s.full_display_name
      }
    end
    
    render json: results
  end
  
  # ============================================================================
  # BULK ACTIONS
  # ============================================================================
  def bulk_action
    supplier_ids = params[:supplier_ids] || []
    action = params[:bulk_action]
    
    case action
    when 'export_csv'
      suppliers = Supplier.where(id: supplier_ids)
      send_data generate_csv(suppliers), filename: "suppliers-#{Date.current}.csv"
    when 'export_pdf'
      suppliers = Supplier.where(id: supplier_ids)
      send_data generate_pdf(suppliers), filename: "suppliers-#{Date.current}.pdf"
    when 'activate'
      Supplier.where(id: supplier_ids).update_all(is_active: true, updated_by_id: current_user.id)
      redirect_to suppliers_path, notice: "#{supplier_ids.count} suppliers activated."
    when 'deactivate'
      Supplier.where(id: supplier_ids).update_all(is_active: false, updated_by_id: current_user.id)
      redirect_to suppliers_path, notice: "#{supplier_ids.count} suppliers deactivated."
    when 'delete'
      Supplier.where(id: supplier_ids).each { |s| s.soft_delete!(current_user) }
      redirect_to suppliers_path, notice: "#{supplier_ids.count} suppliers deleted."
    else
      redirect_to suppliers_path, alert: 'Invalid bulk action.'
    end
  end
  
  # ============================================================================
  # COMPARISON - Compare multiple suppliers
  # ============================================================================
  def comparison
    @supplier_ids = params[:supplier_ids] || []
    @suppliers = Supplier.where(id: @supplier_ids).includes(:product_suppliers)
    @common_products = find_common_products(@suppliers)
  end
  
  private
  
  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================
  def set_supplier
    @supplier = Supplier.non_deleted.find(params[:id])
  end
  
  def supplier_params
    params.require(:supplier).permit(
      # Basic Info
      :legal_name, :trade_name, :tax_id, :vat_number, :gst_number,
      :business_registration_number, :is_1099_vendor,
      
      # Classification
      :supplier_type, :supplier_category, :supplier_status, :status_reason,
      :status_effective_date, :supplier_since,
      
      # Contact
      :primary_email, :primary_phone, :primary_fax, :website,
      :linkedin_url, :facebook_url, :company_profile,
      
      # Financial
      :default_payment_terms, :payment_method, :currency,
      :credit_limit_extended, :requires_advance_payment, :advance_payment_percentage,
      :early_payment_discount_percentage, :early_payment_discount_days,
      :requires_tax_withholding, :tax_withholding_percentage,
      :bank_name, :bank_account_number, :bank_routing_number,
      :bank_swift_code, :bank_iban, :bank_branch,
      
      # Manufacturing
      :default_lead_time_days, :minimum_order_quantity, :maximum_order_quantity,
      :order_multiple, :production_capacity_monthly,
      
      # Certifications
      :iso_9001_certified, :iso_14001_certified, :iso_45001_certified,
      :iso_9001_expiry, :iso_14001_expiry, :iso_45001_expiry,
      
      # Strategic Flags
      :is_preferred_supplier, :is_strategic_supplier, :is_local_supplier,
      :is_minority_owned, :is_woman_owned, :is_veteran_owned,
      
      # Status
      :is_active, :can_receive_pos, :can_receive_rfqs,
      
      # Notes
      :internal_notes, :purchasing_notes,
      
      # References
      :default_buyer_id, :supplier_territory,
      
      # Arrays
      manufacturing_processes: [], quality_control_capabilities: [],
      testing_capabilities: [], materials_specialization: [],
      geographic_coverage: [], factory_locations: [], certifications: [],
      
      # Nested Attributes
      addresses_attributes: [
        :id, :address_type, :address_label, :is_default, :is_active,
        :attention_to, :street_address_1, :street_address_2, :city,
        :state_province, :postal_code, :country, :contact_phone,
        :contact_email, :operating_hours, :receiving_hours,
        :shipping_instructions, :requires_appointment, :_destroy
      ],
      contacts_attributes: [
        :id, :first_name, :last_name, :title, :department, :contact_role,
        :is_primary_contact, :is_decision_maker, :is_active,
        :email, :phone, :mobile, :fax, :extension,
        :skype_id, :linkedin_url, :preferred_contact_method,
        :receive_pos, :receive_rfqs, :receive_quality_alerts,
        :working_hours, :timezone, :_destroy
      ]
    )
  end
  
  def apply_filters
    # Status filter
    if params[:status].present?
      @suppliers = @suppliers.where(supplier_status: params[:status])
    end
    
    # Type filter
    if params[:supplier_type].present?
      @suppliers = @suppliers.where(supplier_type: params[:supplier_type])
    end
    
    # Category filter
    if params[:supplier_category].present?
      @suppliers = @suppliers.where(supplier_category: params[:supplier_category])
    end
    
    # Rating filter
    if params[:min_rating].present?
      @suppliers = @suppliers.where('overall_rating >= ?', params[:min_rating])
    end
    
    # Active/Inactive filter
    if params[:is_active].present?
      @suppliers = @suppliers.where(is_active: params[:is_active])
    end
    
    # Strategic suppliers
    if params[:strategic] == 'true'
      @suppliers = @suppliers.where(is_strategic_supplier: true)
    end
    
    # Preferred suppliers
    if params[:preferred] == 'true'
      @suppliers = @suppliers.where(is_preferred_supplier: true)
    end
    
    # Territory filter
    if params[:territory].present?
      @suppliers = @suppliers.where(supplier_territory: params[:territory])
    end
  end
  
  def apply_search
    if params[:search].present?
      @suppliers = @suppliers.search(params[:search])
    end
  end
  
  def apply_sorting
    sort_column = params[:sort] || 'legal_name'
    sort_direction = params[:direction] || 'asc'
    
    case sort_column
    when 'name'
      @suppliers = @suppliers.order(legal_name: sort_direction)
    when 'code'
      @suppliers = @suppliers.order(code: sort_direction)
    when 'rating'
      @suppliers = @suppliers.order(overall_rating: sort_direction)
    when 'total_spend'
      @suppliers = @suppliers.order(total_purchase_value: sort_direction)
    when 'last_order'
      @suppliers = @suppliers.order(Arel.sql("last_po_date #{sort_direction} NULLS LAST"))
    when 'created_at'
      @suppliers = @suppliers.order(created_at: sort_direction)
    else
      @suppliers = @suppliers.order(legal_name: :asc)
    end
  end
  
  def calculate_statistics
    suppliers = Supplier.non_deleted
    {
      total: suppliers.count,
      active: suppliers.active.count,
      approved: suppliers.approved.count,
      pending: suppliers.pending.count,
      suspended: suppliers.suspended.count,
      high_rated: suppliers.high_rated.count,
      medium_rated: suppliers.medium_rated.count,
      low_rated: suppliers.low_rated.count
    }
  end
  
  def calculate_performance_data
    # Will be implemented with actual PO data
    {
      on_time_deliveries: @supplier.on_time_delivery_rate,
      quality_acceptance: @supplier.quality_acceptance_rate,
      total_spend: @supplier.total_purchase_value,
      order_count: @supplier.total_po_count
    }
  end
  
  def calculate_revenue_trend
    # Mock data - will use actual PO data
    (1..12).map do |i|
      {
        month: i.months.ago.strftime('%b %Y'),
        amount: rand(10000..50000)
      }
    end.reverse
  end
  
  def calculate_order_trend
    # Mock data
    (1..12).map do |i|
      {
        month: i.months.ago.strftime('%b %Y'),
        orders: rand(5..20)
      }
    end.reverse
  end
  
  def calculate_quality_trend
    # Mock data
    (1..12).map do |i|
      {
        month: i.months.ago.strftime('%b %Y'),
        rate: rand(90.0..100.0).round(2)
      }
    end.reverse
  end
  
  def calculate_delivery_performance
    {
      on_time: @supplier.on_time_delivery_rate,
      late: 100 - @supplier.on_time_delivery_rate
    }
  end
  
  def generate_csv(suppliers = @suppliers)
    CSV.generate(headers: true) do |csv|
      csv << ['Code', 'Legal Name', 'Type', 'Category', 'Status', 'Rating', 'Total Spend', 'Email', 'Phone']
      suppliers.each do |s|
        csv << [s.code, s.legal_name, s.supplier_type, s.supplier_category, 
                s.supplier_status, s.overall_rating, s.total_purchase_value,
                s.primary_email, s.primary_phone]
      end
    end
  end
  
  def generate_pdf(suppliers = @suppliers)
    # PDF generation logic (use Prawn or similar)
    "PDF content here"
  end
  
  def check_deletion_allowed
    # Check if supplier has active purchase orders
    # if @supplier.purchase_orders.active.any?
    #   redirect_to @supplier, alert: 'Cannot delete supplier with active purchase orders.'
    # end
  end
  
  def find_common_products(suppliers)
    return [] if suppliers.empty?
    
    product_ids = suppliers.first.products.pluck(:id)
    suppliers[1..-1].each do |supplier|
      product_ids &= supplier.products.pluck(:id)
    end
    
    Product.where(id: product_ids)
  end
end
