class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [:show, :edit, :update, :destroy, :dashboard]
  before_action :set_filter_options, only: [:index]
  
  # ========================================
  # INDEX - List all customers with filters
  # ========================================
  def index
    @customers = Customer.non_deleted.includes(:default_sales_rep, :addresses, :contacts)
    
    # Apply filters
    @customers = apply_filters(@customers)
    
    # Apply search
    if params[:search].present?
      @customers = @customers.search(params[:search])
    end
    
    # Apply sorting
    @customers = apply_sorting(@customers)
    
    # Pagination
    @customers = @customers.page(params[:page]).per(20)
    
    # Statistics for dashboard cards
    @stats = calculate_customer_stats
    
    respond_to do |format|
      format.html
      format.json { render json: @customers }
      format.csv { send_data generate_csv(@customers), filename: "customers-#{Date.current}.csv" }
      format.pdf { render pdf: "customers", template: "customers/index_pdf" }
    end
  end
  
  # ========================================
  # SHOW - Customer detail page with tabs
  # ========================================
  def show
    # Eager load associations for performance
    @customer = Customer.includes(
      :addresses, 
      :contacts, 
      :documents, 
      :activities,
      :default_sales_rep,
      :default_warehouse
    ).find(params[:id])
    
    # Recent activities
    @recent_activities = @customer.activities.order(activity_date: :desc).limit(10)
    
    # Pending follow-ups
    @pending_followups = @customer.pending_followups
    
    # Expiring documents
    @expiring_docs = @customer.expiring_documents(30)
    
    # Performance data for charts
    @performance_data = calculate_customer_performance(@customer)
    
    respond_to do |format|
      format.html
      format.json { render json: @customer.as_json(include: [:addresses, :contacts]) }
      format.pdf { render pdf: "customer-#{@customer.code}", template: "customers/show_pdf" }
    end
  end
  
  # ========================================
  # DASHBOARD - Analytics view
  # ========================================
  def dashboard
    @revenue_chart_data = generate_revenue_chart_data(@customer)
    @order_trend_data = generate_order_trend_data(@customer)
    @payment_performance_data = generate_payment_performance_data(@customer)
  end
  
  # ========================================
  # NEW - New customer form
  # ========================================
  def new
    @customer = Customer.new
    
    # Build nested associations for form
    @customer.addresses.build(address_type: "BILLING", is_default: true)
    @customer.addresses.build(address_type: "SHIPPING")
    @customer.contacts.build(contact_role: "PRIMARY", is_primary_contact: true)
    
    load_form_options
  end
  
  # ========================================
  # CREATE - Create new customer
  # ========================================
  def create
    @customer = Customer.new(customer_params)
    @customer.created_by = current_user
    
    respond_to do |format|
      if @customer.save
        # Log creation activity
        @customer.log_activity!(
          activity_type: "NOTE",
          subject: "Customer created",
          description: "New customer record created by #{current_user.email}",
          activity_date: Time.current,
          related_user: current_user,
          created_by: current_user
        )
        
        format.html { redirect_to @customer, notice: "Customer successfully created." }
        format.json { render :show, status: :created, location: @customer }
      else
        load_form_options
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # ========================================
  # EDIT - Edit customer form
  # ========================================
  def edit
    load_form_options
  end
  
  # ========================================
  # UPDATE - Update customer
  # ========================================
  def update
    respond_to do |format|
      if @customer.update(customer_params)
        @customer.update(last_modified_by: current_user)
        
        # Log update activity
        @customer.log_activity!(
          activity_type: "NOTE",
          subject: "Customer updated",
          description: "Customer record updated by #{current_user.email}",
          activity_date: Time.current,
          related_user: current_user,
          created_by: current_user
        )
        
        format.html { redirect_to @customer, notice: "Customer successfully updated." }
        format.json { render :show, status: :ok, location: @customer }
      else
        load_form_options
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # ========================================
  # DESTROY - Soft delete customer
  # ========================================
  def destroy
    @customer.destroy!
    
    respond_to do |format|
      format.html { redirect_to customers_path, notice: "Customer successfully deleted." }
      format.json { head :no_content }
    end
  end
  
  # ========================================
  # CUSTOM ACTIONS
  # ========================================
  
  # Credit hold management
  def credit_hold
    @customer = Customer.find(params[:id])
    
    if params[:action_type] == "place"
      @customer.place_on_credit_hold!(params[:reason])
      message = "Customer placed on credit hold."
    else
      @customer.remove_credit_hold!
      message = "Credit hold removed."
    end
    
    redirect_to @customer, notice: message
  end
  
  # Export customer statement
  def statement
    @customer = Customer.find(params[:id])
    
    respond_to do |format|
      format.pdf do
        render pdf: "statement-#{@customer.code}",
               template: "customers/statement_pdf",
               layout: "pdf"
      end
    end
  end
  
  # Quick search for autocomplete
  def autocomplete
    customers = Customer.active
                       .search(params[:term])
                       .limit(10)
                       .select(:id, :code, :full_name, :email)
    
    results = customers.map do |c|
      {
        id: c.id,
        label: "#{c.code} - #{c.full_name}",
        value: c.full_name,
        code: c.code,
        email: c.email
      }
    end
    
    render json: results
  end
  
  # Bulk actions
  def bulk_action
    customer_ids = params[:customer_ids]
    action_type = params[:bulk_action_type]
    
    case action_type
    when "activate"
      Customer.where(id: customer_ids).update_all(is_active: true)
      message = "Selected customers activated."
    when "deactivate"
      Customer.where(id: customer_ids).update_all(is_active: false)
      message = "Selected customers deactivated."
    when "export"
      customers = Customer.where(id: customer_ids)
      send_data generate_csv(customers), filename: "selected-customers-#{Date.current}.csv"
      return
    when "delete"
      Customer.where(id: customer_ids).update_all(deleted: true)
      message = "Selected customers deleted."
    end
    
    redirect_to customers_path, notice: message
  end
  
  private
  
  # ========================================
  # PRIVATE HELPER METHODS
  # ========================================
  
  def set_customer
    @customer = Customer.non_deleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customers_path, alert: "Customer not found."
  end
  
  def set_filter_options
    @categories = Customer::CUSTOMER_CATEGORIES
    @types = Customer::CUSTOMER_TYPES
    @payment_terms = Customer::PAYMENT_TERMS
    @sales_reps = User.all.select(:id, :email)
  end
  
  def load_form_options
    @customer_types = Customer::CUSTOMER_TYPES
    @customer_categories = Customer::CUSTOMER_CATEGORIES
    @payment_terms = Customer::PAYMENT_TERMS
    @freight_terms = Customer::FREIGHT_TERMS
    @currencies = Customer::CURRENCIES
    @communication_methods = Customer::COMMUNICATION_METHODS
    @acquisition_sources = Customer::ACQUISITION_SOURCES
    @order_frequencies = Customer::ORDER_FREQUENCIES
    
    @tax_codes = TaxCode.active.select(:id, :code, :name)
    @accounts = Account.where(account_type: "ASSET").select(:id, :code, :name)
    @sales_reps = User.all.select(:id, :email)
    @warehouses = Warehouse.non_deleted.select(:id, :code, :name)
  end
  
  def customer_params
    params.require(:customer).permit(
      # Basic info
      :code, :full_name, :legal_name, :dba_name, :customer_type, :customer_category,
      
      # Contact info
      :email, :phone_number, :mobile, :fax, :website,
      :linkedin_url, :facebook_url, :twitter_url,
      
      # Billing address (keep for backward compatibility)
      :billing_street, :billing_city, :billing_state, :billing_postal_code, :billing_country,
      
      # Shipping address (keep for backward compatibility)
      :shipping_street, :shipping_city, :shipping_state, :shipping_postal_code, :shipping_country,
      
      # Primary/Secondary contacts (keep for backward compatibility)
      :primary_contact_name, :primary_contact_email, :primary_contact_phone,
      :secondary_contact_name, :secondary_contact_email, :secondary_contact_phone,
      
      # Financial
      :credit_limit, :payment_terms, :default_currency, :discount_percentage,
      :early_payment_discount, :late_fee_applicable,
      :bank_name, :bank_account_number, :bank_routing_number,
      
      # Tax
      :tax_exempt, :tax_exempt_number, :customer_tax_region, :ein_number, :business_number,
      :default_tax_code_id,
      
      # Sales
      :default_sales_rep_id, :sales_territory, :customer_acquisition_source,
      :expected_order_frequency, :annual_revenue_potential,
      
      # Operations
      :default_warehouse_id, :default_ar_account_id,
      :shipping_method, :preferred_delivery_method, :freight_terms,
      :delivery_instructions, :special_handling_requirements,
      :allow_backorders, :require_po_number,
      
      # Preferences
      :preferred_communication_method, :marketing_emails_allowed,
      :auto_invoice_email,
      
      # Classification
      :industry_type, :customer_since,
      
      # Status
      :is_active, :internal_notes,
      
      # Nested attributes
      addresses_attributes: [
        :id, :address_type, :address_label, :is_default, :is_active,
        :attention_to, :contact_phone, :contact_email,
        :street_address_1, :street_address_2, :city, :state_province,
        :postal_code, :country, :delivery_instructions, :dock_gate_info,
        :delivery_hours, :residential_address, :requires_appointment, :access_code,
        :_destroy
      ],
      
      contacts_attributes: [
        :id, :first_name, :last_name, :title, :department, :contact_role,
        :is_primary_contact, :is_decision_maker, :is_active,
        :email, :phone, :mobile, :fax, :extension,
        :linkedin_url, :skype_id, :preferred_contact_method,
        :contact_notes, :receive_order_confirmations, :receive_shipping_notifications,
        :receive_invoice_copies, :receive_marketing_emails,
        :birthday, :anniversary, :personal_notes,
        :_destroy
      ]
    )
  end
  
  # ========================================
  # FILTERING & SORTING
  # ========================================
  
  def apply_filters(scope)
    # Filter by status
    if params[:status].present?
      case params[:status]
      when "active"
        scope = scope.where(is_active: true)
      when "inactive"
        scope = scope.where(is_active: false)
      when "credit_hold"
        scope = scope.where(credit_hold: true)
      end
    end
    
    # Filter by category
    scope = scope.by_category(params[:category]) if params[:category].present?
    
    # Filter by type
    scope = scope.by_type(params[:type]) if params[:type].present?
    
    # Filter by territory
    scope = scope.by_territory(params[:territory]) if params[:territory].present?
    
    # Filter by sales rep
    scope = scope.by_sales_rep(params[:sales_rep_id]) if params[:sales_rep_id].present?
    
    # Filter by recent activity
    if params[:activity].present?
      case params[:activity]
      when "recent_orders"
        scope = scope.recent_orders
      when "no_recent_orders"
        scope = scope.no_recent_orders
      end
    end
    
    # Filter by revenue
    if params[:min_revenue].present?
      scope = scope.where("total_revenue_all_time >= ?", params[:min_revenue])
    end
    
    scope
  end
  
  def apply_sorting(scope)
    sort_by = params[:sort_by] || "full_name"
    sort_dir = params[:sort_dir] || "asc"
    
    case sort_by
    when "code"
      scope.order(code: sort_dir)
    when "full_name"
      scope.order(full_name: sort_dir)
    when "revenue"
      scope.order(total_revenue_all_time: sort_dir)
    when "last_order"
      scope.order(last_order_date: sort_dir)
    when "created_at"
      scope.order(created_at: sort_dir)
    when "credit_limit"
      scope.order(credit_limit: sort_dir)
    else
      scope.order(full_name: :asc)
    end
  end
  
  # ========================================
  # STATISTICS & ANALYTICS
  # ========================================
  
  def calculate_customer_stats
    {
      total: Customer.non_deleted.count,
      active: Customer.active.count,
      inactive: Customer.inactive.count,
      credit_hold: Customer.credit_hold.count,
      
      category_a: Customer.by_category("A").count,
      category_b: Customer.by_category("B").count,
      category_c: Customer.by_category("C").count,
      
      total_revenue_ytd: Customer.non_deleted.sum(:total_revenue_ytd),
      avg_order_value: Customer.non_deleted.average(:average_order_value).to_f.round(2),
      
      high_value: Customer.high_value.count,
      recent_orders: Customer.recent_orders.count,
      no_recent_orders: Customer.no_recent_orders.count
    }
  end
  
  def calculate_customer_performance(customer)
    {
      health_score: customer.customer_health_score,
      health_label: customer.customer_health_label,
      credit_utilization: customer.credit_utilization_percentage,
      payment_performance: customer.payment_performance_label,
      
      total_orders: customer.total_orders_count,
      total_revenue: customer.total_revenue_all_time,
      revenue_ytd: customer.total_revenue_ytd,
      avg_order_value: customer.average_order_value,
      
      last_order_date: customer.last_order_date,
      orders_per_month: customer.orders_per_month,
      on_time_payment_rate: customer.on_time_payment_rate,
      
      addresses_count: customer.addresses.count,
      contacts_count: customer.contacts.count,
      activities_count: customer.activities.count
    }
  end
  
  # Chart data generators
  def generate_revenue_chart_data(customer)
    # Last 12 months revenue
    (11.downto(0)).map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month.strftime("%b %Y"),
        revenue: 0  # TODO: Calculate from sales orders when integrated
      }
    end
  end
  
  def generate_order_trend_data(customer)
    # Last 12 months order count
    (11.downto(0)).map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month.strftime("%b %Y"),
        orders: 0  # TODO: Calculate from sales orders when integrated
      }
    end
  end
  
  def generate_payment_performance_data(customer)
    {
      on_time: customer.on_time_payment_rate.to_f,
      late: 100 - customer.on_time_payment_rate.to_f
    }
  end
  
  # ========================================
  # EXPORT FUNCTIONS
  # ========================================
  
  def generate_csv(customers)
    CSV.generate(headers: true) do |csv|
      csv << [
        "Code", "Customer Name", "Legal Name", "Type", "Category",
        "Email", "Phone", "City", "State", "Country",
        "Credit Limit", "Current Balance", "Available Credit",
        "Payment Terms", "Sales Rep", "Territory",
        "Total Orders", "Total Revenue", "Last Order Date",
        "On-Time Payment %", "Status", "Customer Since"
      ]
      
      customers.each do |customer|
        csv << [
          customer.code,
          customer.full_name,
          customer.legal_name,
          customer.customer_type,
          customer.customer_category,
          customer.email,
          customer.phone_number,
          customer.billing_city,
          customer.billing_state,
          customer.billing_country,
          customer.credit_limit,
          customer.current_balance,
          customer.available_credit,
          customer.payment_terms,
          customer.default_sales_rep&.email,
          customer.sales_territory,
          customer.total_orders_count,
          customer.total_revenue_all_time,
          customer.last_order_date,
          customer.on_time_payment_rate,
          customer.status_label,
          customer.customer_since
        ]
      end
    end
  end
end
