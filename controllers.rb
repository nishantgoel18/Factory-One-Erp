# frozen_string_literal: true

# ============================================================================
# COMBINED RAILS CONTROLLERS FILE
# ============================================================================
# Generated: 2025-12-08 01:10:04
# Total Files: 33
# Source Directory: app/controllers
# ============================================================================

# ============ REQUIRES ============

require "csv"
require 'csv'

# ============ CONTROLLERS ============

# ============ ROOT CONTROLLERS ============

============================================================================
# FILE: accounts_controller.rb
# PATH: accounts_controller.rb
============================================================================

class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: %i[ show edit update destroy ]

  # GET /accounts or /accounts.json
  def index
    @accounts = Account.all
  end

  # GET /accounts/1 or /accounts/1.json
  def show
  end

  # GET /accounts/new
  def new
    @account = Account.new
  end

  # GET /accounts/1/edit
  def edit
  end

  # POST /accounts or /accounts.json
  def create
    @account = Account.new(account_params)

    respond_to do |format|
      if @account.save
        format.html { redirect_to @account, notice: "Account was successfully created." }
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /accounts/1 or /accounts/1.json
  def update
    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to @account, notice: "Account was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @account }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accounts/1 or /accounts/1.json
  def destroy
    @account.destroy!

    respond_to do |format|
      format.html { redirect_to accounts_path, notice: "Account was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = Account.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def account_params
      params.expect(account: [ :code, :name, :sub_type, :account_type, :is_active, :deleted, :is_cash_flow_account ])
    end
end

============================================================================
# FILE: application_controller.rb
# PATH: application_controller.rb
============================================================================

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end

============================================================================
# FILE: bill_of_materials_controller.rb
# PATH: bill_of_materials_controller.rb
============================================================================

class BillOfMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_bill_of_material, only: %i[ show edit update destroy activate ]

  def show
  end

  def new
    @bill_of_material = BillOfMaterial.new
  end

  def create
    @bill_of_material = BillOfMaterial.new(bill_of_material_params)
    @bill_of_material.created_by = current_user

    if @bill_of_material.save
      process_bom_items
      redirect_to [@product, @bill_of_material], notice: "BOM created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @bill_of_material.update(bill_of_material_params)
      process_bom_items
      redirect_to [@product, @bill_of_material], notice: "BOM updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @bill_of_material.update_attribute(:deleted, true)
    redirect_to product_path(@product), alert: "BOM deleted."
  end

  def activate
    if @bill_of_material.update(status: 'ACTIVE')
      redirect_to product_path(@product), alert: "BOM Activated."
    else
      redirect_to product_path(@product), alert: "BOM could not be activated due to following errors: #{@bill_of_material.errors.to_sentence}"
    end

  end

  private

  def set_bill_of_material
    @bill_of_material = BillOfMaterial.non_deleted.find_by(id: params[:id], product_id: params[:product_id])
    redirect_to @product, notice: 'BOM not found!' if @bill_of_material.blank?
  end

  def set_product
    @product = Product.non_deleted.find_by(id: params[:product_id])
    redirect_to products_path, notice: 'Product not found!' if @product.blank?
  end

  def process_bom_items

    new_items = (params["bom_item"]["new"] || {})
    existing_items = (params["bom_item"]["existing"] || {})
    @bill_of_material.bom_items.non_deleted.where.not(id: existing_items.keys).delete_all

    new_items.each do |id, value|
      item = @bill_of_material.bom_items.build(component_id: value[:component], uom_id: value[:uom], quantity: value[:quantity], scrap_percent: value[:scrap_percent], line_note: value[:line_note])
      item.save(validate: false)
    end
    existing_items.each do |id, value|
      item = @bill_of_material.bom_items.build(component_id: value[:component], uom_id: value[:uom], quantity: value[:quantity], scrap_percent: value[:scrap_percent], line_note: value[:line_note])
      item.save(validate: false)
    end
  end

  def bom_item_params
    params.permit(
      :component_id, :quantity, :uom_id, :scrap_percent, :line_note
    )
  end

  def bill_of_material_params
    params.require(:bill_of_material).permit(
      :product_id,
      :code,
      :name,
      :revision,
      :status,
      :effective_from,
      :effective_to,
      :is_default,
      :notes,
    )
  end
end

============================================================================
# FILE: customers_controller.rb
# PATH: customers_controller.rb
============================================================================

class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: %i[ show edit update destroy ]

  # GET /customers or /customers.json
  def index
    @customers = Customer.non_deleted
  end

  # GET /customers/1 or /customers/1.json
  def show
  end

  # GET /customers/new
  def new
    @customer = Customer.new
  end

  # GET /customers/1/edit
  def edit
  end

  # POST /customers or /customers.json
  def create
    @customer = Customer.new(customer_params)

    respond_to do |format|
      if @customer.save
        format.html { redirect_to @customer, notice: "Customer was successfully created." }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customers/1 or /customers/1.json
  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: "Customer was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customers/1 or /customers/1.json
  def destroy
    @customer.destroy!

    respond_to do |format|
      format.html { redirect_to customers_path, notice: "Customer was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Customer.non_deleted.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def customer_params
      params.require(:customer).permit(
        :code, :full_name, :legal_name, :customer_type, :dba_name,
        :email, :phone, :mobile, :website, :fax,
        :billing_street, :billing_city, :billing_state,
        :billing_postal_code, :billing_country,
        :shipping_street, :shipping_city, :shipping_state,
        :shipping_postal_code, :shipping_country,
        :tax_exempt, :tax_exempt_number, :customer_tax_region,
        :default_tax_code_id, :ein_number, :business_number,
        :credit_limit, :payment_terms, :default_ar_account_id,
        :allow_backorders, :default_price_list_id,
        :default_currency, :default_sales_rep_id,
        :default_warehouse_id,
        :primary_contact_name, :primary_contact_email, :primary_contact_phone,
        :secondary_contact_name, :secondary_contact_email, :secondary_contact_phone,
        :freight_terms, :shipping_method, :delivery_instructions,
        :internal_notes, :is_active
      )
    end
end

============================================================================
# FILE: dashboards_controller.rb
# PATH: dashboards_controller.rb
============================================================================

class DashboardsController < ApplicationController
  before_action :authenticate_user!
  def home
    @routing_metrics = calculate_routing_metrics
    @work_center_metrics = calculate_work_center_metrics
    @production_readiness = calculate_production_readiness
  end

   def production_dashboard
    # Time period
    @today = Date.current
    @this_week_start = @today.beginning_of_week
    @this_month_start = @today.beginning_of_month
    
    # Active Work Orders
    @active_wos = WorkOrder.non_deleted
                          .where(status: ['RELEASED', 'IN_PROGRESS'])
                          .includes(:product, :warehouse)
                          .order(priority: :desc, scheduled_end_date: :asc)
                          .limit(10)
    
    # Today's statistics
    @today_stats = {
      wos_to_start: WorkOrder.non_deleted
                             .where(status: 'RELEASED')
                             .where(scheduled_start_date: @today)
                             .count,
      
      wos_to_complete: WorkOrder.non_deleted
                                .where(status: 'IN_PROGRESS')
                                .where(scheduled_end_date: @today)
                                .count,
      
      operations_pending: WorkOrderOperation.non_deleted
                                           .where(status: 'PENDING')
                                           .joins(:work_order)
                                           .where(work_orders: { status: ['RELEASED', 'IN_PROGRESS'] })
                                           .count,
      
      operations_in_progress: WorkOrderOperation.non_deleted
                                               .where(status: 'IN_PROGRESS')
                                               .count
    }
    
    # This week statistics
    @week_stats = {
      wos_created: WorkOrder.non_deleted
                           .where(created_at: @this_week_start..@today.end_of_day)
                           .count,
      
      wos_completed: WorkOrder.non_deleted
                             .where(status: 'COMPLETED')
                             .where(completed_at: @this_week_start..@today.end_of_day)
                             .count,
      
      quantity_produced: WorkOrder.non_deleted
                                 .where(status: 'COMPLETED')
                                 .where(completed_at: @this_week_start..@today.end_of_day)
                                 .sum(:quantity_completed),
      
      avg_completion_time: calculate_avg_completion_time(@this_week_start, @today)
    }
    
    # This month statistics
    @month_stats = {
      wos_completed: WorkOrder.non_deleted
                             .where(status: 'COMPLETED')
                             .where(completed_at: @this_month_start..@today.end_of_day)
                             .count,
      
      total_production_cost: calculate_total_production_cost(@this_month_start, @today),
      
      avg_cost_variance: calculate_avg_cost_variance(@this_month_start, @today),
      
      on_time_completion_rate: calculate_on_time_rate(@this_month_start, @today)
    }
    
    # Overdue Work Orders
    @overdue_wos = WorkOrder.non_deleted
                           .where(status: ['RELEASED', 'IN_PROGRESS'])
                           .where('scheduled_end_date < ?', @today)
                           .includes(:product)
                           .order(scheduled_end_date: :asc)
                           .limit(5)
    
    # Urgent Work Orders
    @urgent_wos = WorkOrder.non_deleted
                          .where(status: ['NOT_STARTED', 'RELEASED', 'IN_PROGRESS'])
                          .where(priority: 'URGENT')
                          .includes(:product)
                          .order(scheduled_end_date: :asc)
                          .limit(5)
    
    # Work Center Utilization
    @work_center_utilization = calculate_work_center_utilization
    
    # Production Trends (Last 7 days)
    @production_trend = (6.days.ago.to_date..@today).map do |date|
      {
        date: date,
        completed: WorkOrder.non_deleted
                           .where(status: 'COMPLETED')
                           .where(completed_at: date.beginning_of_day..date.end_of_day)
                           .count
      }
    end
    
    # Cost Trends (Last 7 days)
    @cost_trend = (6.days.ago.to_date..@today).map do |date|
      completed_wos = WorkOrder.non_deleted
                               .where(status: 'COMPLETED')
                               .where(completed_at: date.beginning_of_day..date.end_of_day)
      
      {
        date: date,
        planned: completed_wos.sum { |wo| wo.total_planned_cost },
        actual: completed_wos.sum { |wo| wo.total_actual_cost }
      }
    end
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

  def calculate_avg_completion_time(start_date, end_date)
    completed = WorkOrder.non_deleted
                        .where(status: 'COMPLETED')
                        .where(completed_at: start_date..end_date.end_of_day)
                        .where.not(actual_start_date: nil)
    
    return 0 if completed.count.zero?
    
    total_hours = completed.sum do |wo|
      ((wo.actual_end_date - wo.actual_start_date) / 3600).round(2)
    end
    
    (total_hours / completed.count).round(2)
  end
  
  def calculate_total_production_cost(start_date, end_date)
    WorkOrder.non_deleted
            .where(status: 'COMPLETED')
            .where(completed_at: start_date..end_date.end_of_day)
            .sum { |wo| wo.total_actual_cost }
  end
  
  def calculate_avg_cost_variance(start_date, end_date)
    completed = WorkOrder.non_deleted
                        .where(status: 'COMPLETED')
                        .where(completed_at: start_date..end_date.end_of_day)
    
    return 0 if completed.count.zero?
    
    total_variance = completed.sum { |wo| wo.cost_variance }
    (total_variance / completed.count).round(2)
  end
  
  def calculate_on_time_rate(start_date, end_date)
    completed = WorkOrder.non_deleted
                        .where(status: 'COMPLETED')
                        .where(completed_at: start_date..end_date.end_of_day)
    
    return 0 if completed.count.zero?
    
    on_time = completed.select do |wo|
      wo.actual_end_date.to_date <= wo.scheduled_end_date
    end
    
    ((on_time.count.to_f / completed.count) * 100).round(2)
  end
  
  def calculate_work_center_utilization
    today = Date.current
    active_operations = WorkOrderOperation.non_deleted
                                         .where(status: 'IN_PROGRESS')
                                         .includes(:work_center)
    
    work_centers = WorkCenter.active.limit(10)
    
    work_centers.map do |wc|
      ops_count = active_operations.where(work_center_id: wc.id).count
      {
        work_center: wc,
        active_operations: ops_count,
        utilization_percent: ops_count > 0 ? 100 : 0  # Simplified
      }
    end.sort_by { |s| -s[:utilization_percent] }
  end
end

============================================================================
# FILE: journal_entries_controller.rb
# PATH: journal_entries_controller.rb
============================================================================

class JournalEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_journal_entry, only: %i[ show edit update destroy ]

  # GET /journal_entries or /journal_entries.json
  def index
    @journal_entries = JournalEntry.all
  end

  # GET /journal_entries/1 or /journal_entries/1.json
  def show
  end

  # GET /journal_entries/new
  def new
    @journal_entry = JournalEntry.new
    2.times { @journal_entry.journal_lines.build }
  end

  # GET /journal_entries/1/edit
  def edit
    if !(@journal_entry.posted_at.nil? && !@journal_entry.reversed? && !@journal_entry.is_reversal?)
      redirect_to @journal_entry, alert: "Journal entry can be edited as it has either posted or reversed."
    end
  end

  # POST /journal_entries or /journal_entries.json
  def create
    @journal_entry = JournalEntry.new(journal_entry_params)

    respond_to do |format|
      if @journal_entry.save
        format.html { redirect_to @journal_entry, notice: "Journal entry was successfully created." }
        format.json { render :show, status: :created, location: @journal_entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @journal_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /journal_entries/1 or /journal_entries/1.json
  def update
    respond_to do |format|
      if @journal_entry.update(journal_entry_params)
        format.html { redirect_to @journal_entry, notice: "Journal entry was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @journal_entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @journal_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /journal_entries/1 or /journal_entries/1.json
  def destroy
    @journal_entry.destroy!

    respond_to do |format|
      format.html { redirect_to journal_entries_path, notice: "Journal entry was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def post
    @journal_entry = JournalEntry.find(params[:id])
    status = @journal_entry.post!(current_user)
    redirect_to @journal_entry, notice: status
  end

  def reverse
    original = JournalEntry.find(params[:id])

    if original.posted_at.blank?
      redirect_to original, alert: "Only posted entries can be reversed."
      return
    end

    if original.reversed? || original.reversal_entry_id.present?
      redirect_to original, alert: "Reversal entry cannot be reversed again."
      return
    end

    reversal = JournalEntry.new(
      entry_date: Date.today,
      description: "Reversal of #{original.entry_number}",
      accounting_period: original.accounting_period,
      reference_id: original.reference_id,
      reference_type: original.reference_type,
      is_reversal: true
    )

    original.journal_lines.non_deleted.each do |line|
      reversal.journal_lines.build(
        account_id: line.account_id,
        debit: line.credit,   # reverse!!!
        credit: line.debit,   # reverse!!!
        description: "Reversal of line ##{line.id}"
      )
    end

    if reversal.save
      reversal.post!(current_user)
      original.update!(
        reversed: true,
        reversed_at: Time.current,
        reversal_entry_id: reversal.id
      )

      redirect_to reversal, notice: "Reversal entry #{reversal.entry_number} created and posted."
    else
      redirect_to original, alert: "Reversal failed: #{reversal.errors.full_messages.join(', ')}"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_journal_entry
      @journal_entry = JournalEntry.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def journal_entry_params
      params.require(:journal_entry).permit(
        :entry_date,
        :description,
        :accounting_period,
        :reference_id,
        :reference_type,
        journal_lines_attributes: [
          :id, :account_id, :debit, :credit, :description, :_destroy
        ]
      )
    end
end

============================================================================
# FILE: labor_time_entries_controller.rb
# PATH: labor_time_entries_controller.rb
============================================================================

# app/controllers/labor_time_entries_controller.rb

class LaborTimeEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_order_operation, only: [:clock_in, :clock_out]
  
   # ========================================
  # CLOCK IN (WITH VALIDATION)
  # ========================================
  def clock_in
    begin
      # Check if operator can clock in
      unless @operation.can_clock_in?(current_user)
        # Check where they're currently clocked in
        if LaborTimeEntry.operator_clocked_in?(current_user.id)
          current_entry = LaborTimeEntry.current_for_operator(current_user.id)
          other_operation = current_entry.work_order_operation
          
          flash[:error] = "You are already clocked in to Operation #{other_operation.sequence_no} " \
                         "on Work Order #{other_operation.work_order.wo_number}. " \
                         "Please clock out first."
        elsif @operation.has_active_clock_in_by?(current_user)
          flash[:error] = "You are already clocked in to this operation!"
        else
          flash[:error] = "Cannot clock in to this operation at this time."
        end
        
        redirect_to work_order_path(@operation.work_order) and return
      end
      
      entry_type = params[:entry_type] || 'REGULAR'
      notes = params[:notes]
      
      @entry = @operation.clock_in_operator!(
        current_user, 
        entry_type: entry_type,
        notes: notes
      )
      
      flash[:success] = "Clocked in successfully at #{@entry.clock_in_at.strftime('%I:%M %p')}"
      redirect_to work_order_path(@operation.work_order)
      
    rescue => e
      flash[:error] = "Clock in failed: #{e.message}"
      redirect_to work_order_path(@operation.work_order)
    end
  end
  
  # ========================================
  # CLOCK OUT (WITH VALIDATION)
  # ========================================
  def clock_out
    begin
      # Validate operator is clocked in to THIS operation
      unless @operation.operator_clocked_in?(current_user)
        flash[:error] = "You are not currently clocked in to this operation!"
        redirect_to work_order_path(@operation.work_order) and return
      end
      
      @entry = @operation.clock_out_operator!(current_user)
      
      flash[:success] = "Clocked out successfully. Time worked: #{@entry.elapsed_time_display}"
      redirect_to work_order_path(@operation.work_order)
      
    rescue => e
      flash[:error] = "Clock out failed: #{e.message}"
      redirect_to work_order_path(@operation.work_order)
    end
  end
  
  # ========================================
  # MY TIMESHEET
  # ========================================
  def my_timesheet
    @date = params[:date]&.to_date || Date.current
    
    @entries = LaborTimeEntry.non_deleted
                             .for_operator(current_user.id)
                             .for_date(@date)
                             .includes(:work_order_operation => { :work_order => :product })
                             .order(clock_in_at: :desc)
    
    @summary = {
      total_hours: @entries.sum(:hours_worked).round(2),
      total_entries: @entries.count,
      operations_count: @entries.distinct.count(:work_order_operation_id)
    }
  end
  
  # ========================================
  # SHOP FLOOR VIEW
  # ========================================
  def shop_floor
    # Current active clock-in
    @current_entry = LaborTimeEntry.current_for_operator(current_user.id)
    
    # My pending operations
    assigned_operations = current_user.assigned_work_order_operations
    @pending_operations = assigned_operations.non_deleted
                                            .joins(:work_order)
                                            .where(work_orders: { status: ['RELEASED', 'IN_PROGRESS'] })
                                            .where(work_order_operations: { status: ['PENDING', 'IN_PROGRESS'] })
                                            .includes([{:work_order => :product}, :work_center])
                                            .order(:sequence_no)
                                            .limit(10)
    
    # Today's completed operations
    @completed_today = assigned_operations.non_deleted
                                         .joins(:labor_time_entries)
                                         .where(labor_time_entries: { 
                                           operator_id: current_user.id,
                                           deleted: false
                                         })
                                         .where('DATE(labor_time_entries.clock_in_at) = ?', Date.current)
                                         .distinct
                                         .includes(:work_order => :product)
    
    # Today's hours
    @today_hours = LaborTimeEntry.non_deleted
                                 .for_operator(current_user.id)
                                 .for_date(Date.current)
                                 .sum(:hours_worked)
                                 .round(2)
  end
  
  private
  
  def set_work_order_operation
    @operation = WorkOrderOperation.find(params[:wo_op])
  end
end

============================================================================
# FILE: locations_controller.rb
# PATH: locations_controller.rb
============================================================================

class LocationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_location, only: %i[ show edit update destroy ]

  # GET /locations or /locations.json
  def index
    @locations = Location.all
  end

  # GET /locations/1 or /locations/1.json
  def show
  end

  # GET /locations/new
  def new
    @location = Location.new
  end

  # GET /locations/1/edit
  def edit
  end

  # POST /locations or /locations.json
  def create
    @location = Location.new(location_params)

    respond_to do |format|
      if @location.save
        format.html { redirect_to @location, notice: "Location was successfully created." }
        format.json { render :show, status: :created, location: @location }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /locations/1 or /locations/1.json
  def update
    respond_to do |format|
      if @location.update(location_params)
        format.html { redirect_to @location, notice: "Location was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @location }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /locations/1 or /locations/1.json
  def destroy
    @location.destroy!

    respond_to do |format|
      format.html { redirect_to locations_path, notice: "Location was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_location
      @location = Location.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def location_params
      params.expect(location: [ :warehouse_id, :code, :name, :is_pickable, :is_receivable, :deleted ])
    end
end

============================================================================
# FILE: operator_assignments_controller.rb
# PATH: operator_assignments_controller.rb
============================================================================

# app/controllers/operator_assignments_controller.rb

class OperatorAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_order, only: [:edit, :update]
  
  # ========================================
  # BULK ASSIGNMENT VIEW
  # ========================================
  def edit
    # Get all pending/in-progress operations for this WO
    @operations = @work_order.work_order_operations
                            .where(status: ['PENDING', 'IN_PROGRESS'])
                            .order(:sequence_no)
    
    # Get available operators (you might want to filter by role or work center)
    @operators = User.all.order(:full_name)
  end
  
  # ========================================
  # BULK UPDATE
  # ========================================
  def update
    assignments_made = 0
    errors = []
    binding.pry
    params[:operations]&.each do |operation_id, assignment_data|
      operation = @work_order.work_order_operations.find(operation_id)
      operator_id = assignment_data[:assigned_operator_id]
      
      if operator_id.present?
        operator = User.find(operator_id)
        operation.assign_to_operator!(operator, assigned_by: current_user)
        assignments_made += 1
      elsif operation.assigned?
        operation.unassign_operator!
      end
    rescue => e
      errors << "Operation #{operation.sequence_no}: #{e.message}"
    end
    
    if errors.any?
      flash[:warning] = "Some assignments failed: #{errors.join(', ')}"
    else
      flash[:success] = "Successfully assigned #{assignments_made} operation(s)"
    end
    
    redirect_to work_order_path(@work_order)
  end
  
  # ========================================
  # SINGLE ASSIGNMENT (AJAX)
  # ========================================
  def assign_single
    @operation = WorkOrderOperation.find(params[:operation_id])
    operator_id = params[:operator_id]
    
    if operator_id.present?
      operator = User.find(operator_id)
      @operation.assign_to_operator!(operator, assigned_by: current_user)
      message = "Operation assigned to #{operator.full_name}"
    else
      @operation.unassign_operator!
      message = "Operation unassigned"
    end
    
    respond_to do |format|
      format.json { render json: { success: true, message: message } }
      format.html do
        flash[:success] = message
        redirect_to work_order_path(@operation.work_order)
      end
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { success: false, message: e.message }, status: :unprocessable_entity }
      format.html do
        flash[:error] = e.message
        redirect_to work_order_path(@operation.work_order)
      end
    end
  end
  
  private
  
  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end
end

============================================================================
# FILE: product_categories_controller.rb
# PATH: product_categories_controller.rb
============================================================================

class ProductCategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_category, only: %i[ show edit update destroy ]

  # GET /product_categories or /product_categories.json
  def index
    @product_categories = ProductCategory.all
  end

  # GET /product_categories/1 or /product_categories/1.json
  def show
  end

  # GET /product_categories/new
  def new
    @product_category = ProductCategory.new
  end

  # GET /product_categories/1/edit
  def edit
  end

  # POST /product_categories or /product_categories.json
  def create
    @product_category = ProductCategory.new(product_category_params)

    respond_to do |format|
      if @product_category.save
        format.html { redirect_to @product_category, notice: "Product category was successfully created." }
        format.json { render :show, status: :created, location: @product_category }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_categories/1 or /product_categories/1.json
  def update
    respond_to do |format|
      if @product_category.update(product_category_params)
        format.html { redirect_to @product_category, notice: "Product category was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @product_category }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_categories/1 or /product_categories/1.json
  def destroy
    @product_category.destroy!

    respond_to do |format|
      format.html { redirect_to product_categories_path, notice: "Product category was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_category
      @product_category = ProductCategory.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def product_category_params
      params.expect(product_category: [ :name, :parent_id, :deleted ])
    end
end

============================================================================
# FILE: production_calculator_controller.rb
# PATH: production_calculator_controller.rb
============================================================================

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

============================================================================
# FILE: products_controller.rb
# PATH: products_controller.rb
============================================================================

class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: %i[ show edit update destroy ]

  # GET /products or /products.json
  def index
    @products = Product.non_deleted.includes([{bill_of_materials: :bom_items}, :product_category, :unit_of_measure])
  end

  # GET /products/1 or /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products or /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: "Product was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    @product.destroy!

    respond_to do |format|
      format.html { redirect_to products_path, notice: "Product was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.non_deleted.includes([{bill_of_materials: :bom_items}, :product_category, :unit_of_measure]).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.expect(product: [ :sku, :name, :product_category_id, :unit_of_measure_id, :is_batch_tracked, :is_serial_tracked, :is_stocked, :reorder_point, :is_active, :deleted, :product_type, :standard_cost ])
    end
end

============================================================================
# FILE: routing_reports_controller.rb
# PATH: routing_reports_controller.rb
============================================================================

# app/controllers/routing_reports_controller.rb
class RoutingReportsController < ApplicationController
  before_action :authenticate_user!
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
    # Simple Ruby approach - more reliable!
    work_centers = WorkCenter.where(deleted: false, is_active: true)
                             .includes(routing_operations: :routing)
    
    @operations_data = work_centers.map do |wc|
      operations = wc.routing_operations
                     .joins(:routing)
                     .where(deleted: false, routings: { status: 'ACTIVE', deleted: false })
      
      OpenStruct.new(
        wc_id: wc.id,
        wc_code: wc.code,
        wc_name: wc.name,
        operations_count: operations.count,
        total_setup: operations.sum(:setup_time_minutes).to_f,
        avg_run_time: operations.average(:run_time_per_unit_minutes).to_f.round(2),
        total_labor_cost: operations.sum(:labor_cost_per_unit).to_f,
        total_overhead_cost: operations.sum(:overhead_cost_per_unit).to_f
      )
    end.select { |data| data.operations_count > 0 }
       .sort_by { |data| -data.operations_count }
    
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

============================================================================
# FILE: routings_controller.rb
# PATH: routings_controller.rb
============================================================================

# app/controllers/routings_controller.rb

class RoutingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_routing, only: [:show, :edit, :update, :destroy, :toggle_status, :duplicate]
  before_action :load_dropdowns, only: [:new, :edit, :create, :update]
  
  # ========================================
  # INDEX - List all routings
  # ========================================
  def index
    @routings = Routing.where(deleted: false)
                       .includes(:product, :created_by, routing_operations: :work_center)
                       .order(created_at: :desc)
    
    # Filters
    if params[:product_id].present?
      @routings = @routings.where(product_id: params[:product_id])
    end
    
    if params[:status].present?
      @routings = @routings.where(status: params[:status])
    end
    
    # Search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @routings = @routings.where(
        "routings.code ILIKE ? OR routings.name ILIKE ? OR routings.description ILIKE ?", 
        search_term, search_term, search_term
      )
    end
    
    @routings = @routings.page(params[:page]).per(20)
  end
  
  # ========================================
  # SHOW - View single routing
  # ========================================
  def show
    @operations = @routing.routing_operations
                          .includes(:work_center)
                          .order(:operation_sequence)
  end
  
  # ========================================
  # NEW - Form for new routing
  # ========================================
  def new
    @routing = Routing.new
    @routing.code = Routing.generate_next_code
    @routing.status = "DRAFT"
    @routing.effective_from = Date.today
    @routing.revision = "1"
    
    # Add one blank operation by default
    @routing.routing_operations.build(operation_sequence: 10)
  end
  
  # ========================================
  # CREATE - Save new routing
  # ========================================
  def create
    @routing = Routing.new(routing_params)
    @routing.created_by = current_user
    
    # Auto-assign operation sequences if not provided
    assign_operation_sequences
    
    if @routing.save
      redirect_to routing_path(@routing), 
                  notice: "Routing '#{@routing.code}' created successfully!"
    else
      load_dropdowns
      render :new, status: :unprocessable_entity
    end
  end
  
  # ========================================
  # EDIT - Form for editing
  # ========================================
  def edit
    # Load existing operations or add blank one
    if @routing.routing_operations.empty?
      @routing.routing_operations.build(operation_sequence: 10)
    end
  end
  
  # ========================================
  # UPDATE - Save changes
  # ========================================
  def update
    # Auto-assign sequences for new operations
    assign_operation_sequences
    
    if @routing.update(routing_params)
      redirect_to routing_path(@routing), 
                  notice: "Routing '#{@routing.code}' updated successfully!"
    else
      load_dropdowns
      render :edit, status: :unprocessable_entity
    end
  end
  
  # ========================================
  # DESTROY - Soft delete
  # ========================================
  def destroy
    if @routing.destroy!
      redirect_to routings_path, 
                  notice: "Routing '#{@routing.code}' deleted successfully!"
    else
      redirect_to routing_path(@routing), 
                  alert: @routing.errors.full_messages.join(", ")
    end
  end
  
  # ========================================
  # TOGGLE_STATUS - Activate/Deactivate
  # ========================================
  def toggle_status
    new_status = case @routing.status
                 when "ACTIVE" then "INACTIVE"
                 when "INACTIVE" then "ACTIVE"
                 else "ACTIVE"
                 end
    
    if @routing.update(status: new_status)
      redirect_to routing_path(@routing), 
                  notice: "Routing status changed to #{new_status}!"
    else
      redirect_to routing_path(@routing), 
                  alert: "Failed to update status: #{@routing.errors.full_messages.join(', ')}"
    end
  end
  
  # ========================================
  # DUPLICATE - Create a copy
  # ========================================
  def duplicate
    new_routing = @routing.dup
    new_routing.code = Routing.generate_next_code
    new_routing.name = "Copy of #{@routing.name}"
    new_routing.status = "DRAFT"
    new_routing.is_default = false
    new_routing.created_by = current_user
    
    # Duplicate operations
    @routing.routing_operations.where(deleted: false).each do |op|
      new_op = op.dup
      new_routing.routing_operations << new_op
    end
    
    if new_routing.save
      redirect_to edit_routing_path(new_routing), 
                  notice: "Routing duplicated! Please review and update as needed."
    else
      redirect_to routing_path(@routing), 
                  alert: "Failed to duplicate routing: #{new_routing.errors.full_messages.join(', ')}"
    end
  end
  
  # ========================================
  # GENERATE_CODE - AJAX endpoint
  # ========================================
  def generate_code
    render json: { code: Routing.generate_next_code }
  end
  
  private
  
  # ========================================
  # BEFORE ACTIONS
  # ========================================
  def set_routing
    @routing = Routing.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to routings_path, alert: "Routing not found."
  end
  
  def load_dropdowns
    @products = Product.where(deleted: false)
                       .where(product_type: ["Finished Goods", "Semi-Finished Goods"])
                       .order(:name)
    
    @work_centers = WorkCenter.where(deleted: false, is_active: true)
                              .order(:code)
    
    @statuses = Routing::STATUS_CHOICES
  end
  
  # ========================================
  # HELPER METHODS
  # ========================================
  def assign_operation_sequences
    # Auto-assign sequences to new operations that don't have one
    operations = routing_params[:routing_operations_attributes]
    return if operations.blank?
    operations.to_h.each_with_index do |(key, op_attrs)|
      next if op_attrs[:operation_sequence].present?
      next if op_attrs[:_destroy] == "1"
      
      # Find next available sequence
      last_seq = @routing.routing_operations.maximum(:operation_sequence) || 0
      operations[key][:operation_sequence] = last_seq + 10
    end
  end
  
  # ========================================
  # STRONG PARAMETERS
  # ========================================
  def routing_params
    params.require(:routing).permit(
      :code,
      :name,
      :description,
      :product_id,
      :revision,
      :status,
      :is_default,
      :effective_from,
      :effective_to,
      :notes,
      routing_operations_attributes: [
        :id,
        :operation_sequence,
        :operation_name,
        :description,
        :work_center_id,
        :setup_time_minutes,
        :run_time_per_unit_minutes,
        :wait_time_minutes,
        :move_time_minutes,
        :labor_hours_per_unit,
        :is_quality_check_required,
        :quality_check_instructions,
        :notes,
        :_destroy
      ]
    )
  end
end

============================================================================
# FILE: stock_issues_controller.rb
# PATH: stock_issues_controller.rb
============================================================================

class StockIssuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stock_issue, only: %i[ show edit update destroy ]

  # GET /stock_issues or /stock_issues.json
  def index
    @stock_issues = StockIssue.all
  end

  # GET /stock_issues/1 or /stock_issues/1.json
  def show
  end

  # GET /stock_issues/new
  def new
    @stock_issue = StockIssue.new
  end

  # GET /stock_issues/1/edit
  def edit
  end

  # POST /stock_issues or /stock_issues.json
  def create
    @stock_issue = StockIssue.new(stock_issue_params)

    respond_to do |format|
      if @stock_issue.save
        format.html { redirect_to @stock_issue, notice: "Stock issue was successfully created." }
        format.json { render :show, status: :created, location: @stock_issue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @stock_issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stock_issues/1 or /stock_issues/1.json
  def update
    respond_to do |format|
      if @stock_issue.update(stock_issue_params)
        format.html { redirect_to @stock_issue, notice: "Stock issue was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @stock_issue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stock_issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stock_issues/1 or /stock_issues/1.json
  def destroy
    @stock_issue.destroy!

    respond_to do |format|
      format.html { redirect_to stock_issues_path, notice: "Stock issue was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stock_issue
      @stock_issue = StockIssue.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def stock_issue_params
      params.expect(stock_issue: [ :warehouse_id, :status, :reference_no, :created_by, :deleted ])
    end
end

============================================================================
# FILE: suppliers_controller.rb
# PATH: suppliers_controller.rb
============================================================================

class SuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier, only: %i[ show edit update destroy ]

  # GET /suppliers or /suppliers.json
  def index
    @suppliers = Supplier.all
  end

  # GET /suppliers/1 or /suppliers/1.json
  def show
  end

  # GET /suppliers/new
  def new
    @supplier = Supplier.new
  end

  # GET /suppliers/1/edit
  def edit
  end

  # POST /suppliers or /suppliers.json
  def create
    @supplier = Supplier.new(supplier_params)

    respond_to do |format|
      if @supplier.save
        format.html { redirect_to @supplier, notice: "Supplier was successfully created." }
        format.json { render :show, status: :created, location: @supplier }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /suppliers/1 or /suppliers/1.json
  def update
    respond_to do |format|
      if @supplier.update(supplier_params)
        format.html { redirect_to @supplier, notice: "Supplier was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @supplier }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /suppliers/1 or /suppliers/1.json
  def destroy
    @supplier.destroy!

    respond_to do |format|
      format.html { redirect_to suppliers_path, notice: "Supplier was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_supplier
      @supplier = Supplier.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def supplier_params
      params.expect(supplier: [ :code, :name, :email, :phone, :billing_address, :shipping_address, :lead_time_days, :on_time_delivery_rate, :is_active, :deleted, :created_by ])
    end
end

============================================================================
# FILE: tax_codes_controller.rb
# PATH: tax_codes_controller.rb
============================================================================

class TaxCodesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tax_code, only: %i[ show edit update destroy ]

  # GET /tax_codes or /tax_codes.json
  def index
    @tax_codes = TaxCode.non_deleted
  end

  # GET /tax_codes/1 or /tax_codes/1.json
  def show
  end

  # GET /tax_codes/new
  def new
    @tax_code = TaxCode.new
  end

  # GET /tax_codes/1/edit
  def edit
  end

  # POST /tax_codes or /tax_codes.json
  def create
    @tax_code = TaxCode.new(tax_code_params)

    respond_to do |format|
      if @tax_code.save
        format.html { redirect_to @tax_code, notice: "Tax code was successfully created." }
        format.json { render :show, status: :created, location: @tax_code }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tax_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tax_codes/1 or /tax_codes/1.json
  def update
    respond_to do |format|
      if @tax_code.update(tax_code_params)
        format.html { redirect_to @tax_code, notice: "Tax code was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tax_code }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tax_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tax_codes/1 or /tax_codes/1.json
  def destroy
    @tax_code.destroy!

    respond_to do |format|
      format.html { redirect_to tax_codes_path, notice: "Tax code was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tax_code
      @tax_code = TaxCode.non_deleted.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def tax_code_params
      params.expect(tax_code: [ :code, :name, :jurisdiction, :tax_type, :country, :state_province, :county, :city, :rate, :is_compound, :compounds_on, :effective_from, :effective_to, :tax_authority_id, :filing_frequency, :is_active, :deleted ])
    end
end

============================================================================
# FILE: unit_of_measures_controller.rb
# PATH: unit_of_measures_controller.rb
============================================================================

class UnitOfMeasuresController < ApplicationController
  before_action :authenticate_user!
  before_action :set_unit_of_measure, only: %i[ show edit update destroy ]

  # GET /unit_of_measures or /unit_of_measures.json
  def index
    @unit_of_measures = UnitOfMeasure.all
  end

  # GET /unit_of_measures/1 or /unit_of_measures/1.json
  def show
  end

  # GET /unit_of_measures/new
  def new
    @unit_of_measure = UnitOfMeasure.new
  end

  # GET /unit_of_measures/1/edit
  def edit
  end

  # POST /unit_of_measures or /unit_of_measures.json
  def create
    @unit_of_measure = UnitOfMeasure.new(unit_of_measure_params)

    respond_to do |format|
      if @unit_of_measure.save
        format.html { redirect_to @unit_of_measure, notice: "Unit of measure was successfully created." }
        format.json { render :show, status: :created, location: @unit_of_measure }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @unit_of_measure.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /unit_of_measures/1 or /unit_of_measures/1.json
  def update
    respond_to do |format|
      if @unit_of_measure.update(unit_of_measure_params)
        format.html { redirect_to @unit_of_measure, notice: "Unit of measure was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @unit_of_measure }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @unit_of_measure.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /unit_of_measures/1 or /unit_of_measures/1.json
  def destroy
    @unit_of_measure.destroy!

    respond_to do |format|
      format.html { redirect_to unit_of_measures_path, notice: "Unit of measure was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit_of_measure
      @unit_of_measure = UnitOfMeasure.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def unit_of_measure_params
      params.expect(unit_of_measure: [ :name, :symbol, :is_decimal ])
    end
end

============================================================================
# FILE: warehouses_controller.rb
# PATH: warehouses_controller.rb
============================================================================

class WarehousesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_warehouse, only: %i[ show edit update destroy ]

  # GET /warehouses or /warehouses.json
  def index
    @warehouses = Warehouse.all
  end

  # GET /warehouses/1 or /warehouses/1.json
  def show
  end

  # GET /warehouses/new
  def new
    @warehouse = Warehouse.new
  end

  # GET /warehouses/1/edit
  def edit
  end

  # POST /warehouses or /warehouses.json
  def create
    @warehouse = Warehouse.new(warehouse_params)

    respond_to do |format|
      if @warehouse.save
        format.html { redirect_to @warehouse, notice: "Warehouse was successfully created." }
        format.json { render :show, status: :created, location: @warehouse }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @warehouse.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /warehouses/1 or /warehouses/1.json
  def update
    respond_to do |format|
      if @warehouse.update(warehouse_params)
        format.html { redirect_to @warehouse, notice: "Warehouse was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @warehouse }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @warehouse.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /warehouses/1 or /warehouses/1.json
  def destroy
    @warehouse.destroy!

    respond_to do |format|
      format.html { redirect_to warehouses_path, notice: "Warehouse was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_warehouse
      @warehouse = Warehouse.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def warehouse_params
      params.expect(warehouse: [ :name, :code, :address, :is_active, :deleted ])
    end
end

============================================================================
# FILE: work_centers_controller.rb
# PATH: work_centers_controller.rb
============================================================================

# app/controllers/work_centers_controller.rb

class WorkCentersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_center, only: [:show, :edit, :update, :destroy, :toggle_status]
  before_action :load_dropdowns, only: [:new, :edit, :create, :update]
  
  # ========================================
  # INDEX - List all work centers
  # ========================================
  def index
    @work_centers = WorkCenter.where(deleted: false)
                              .includes(:warehouse, :location, :created_by)
                              .order(created_at: :desc)
    
    # Filters
    if params[:warehouse_id].present?
      @work_centers = @work_centers.where(warehouse_id: params[:warehouse_id])
    end
    
    if params[:work_center_type].present?
      @work_centers = @work_centers.where(work_center_type: params[:work_center_type])
    end
    
    if params[:status].present?
      @work_centers = @work_centers.where(is_active: params[:status] == 'active')
    end
    
    # Search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @work_centers = @work_centers.where(
        "code ILIKE ? OR name ILIKE ? OR description ILIKE ?", 
        search_term, search_term, search_term
      )
    end
    
    @work_centers = @work_centers.page(params[:page]).per(20)
  end
  
  # ========================================
  # SHOW - View single work center
  # ========================================
  def show
    # Future: Load routing operations that use this work center
    # @routing_operations = @work_center.routing_operations.includes(:routing)
  end
  
  # ========================================
  # NEW - Form for new work center
  # ========================================
  def new
    @work_center = WorkCenter.new
    @work_center.code = WorkCenter.generate_next_code
    @work_center.efficiency_percent = 100
    @work_center.is_active = true
  end
  
  # ========================================
  # CREATE - Save new work center
  # ========================================
  def create
    @work_center = WorkCenter.new(work_center_params)
    @work_center.created_by = current_user
    
    if @work_center.save
      redirect_to work_center_path(@work_center), 
                  notice: "Work Center '#{@work_center.code}' created successfully!"
    else
      load_dropdowns
      render :new, status: :unprocessable_entity
    end
  end
  
  # ========================================
  # EDIT - Form for editing
  # ========================================
  def edit
    # Loads @work_center via before_action
  end
  
  # ========================================
  # UPDATE - Save changes
  # ========================================
  def update
    if @work_center.update(work_center_params)
      redirect_to work_center_path(@work_center), 
                  notice: "Work Center '#{@work_center.code}' updated successfully!"
    else
      load_dropdowns
      render :edit, status: :unprocessable_entity
    end
  end
  
  # ========================================
  # DESTROY - Soft delete
  # ========================================
  def destroy
    if @work_center.destroy!
      redirect_to work_centers_path, 
                  notice: "Work Center '#{@work_center.code}' deleted successfully!"
    else
      redirect_to work_center_path(@work_center), 
                  alert: @work_center.errors.full_messages.join(", ")
    end
  end
  
  # ========================================
  # TOGGLE_STATUS - Activate/Deactivate
  # ========================================
  def toggle_status
    new_status = !@work_center.is_active
    
    if @work_center.update(is_active: new_status)
      status_text = new_status ? "activated" : "deactivated"
      redirect_to work_center_path(@work_center), 
                  notice: "Work Center '#{@work_center.code}' #{status_text}!"
    else
      redirect_to work_center_path(@work_center), 
                  alert: "Failed to update status."
    end
  end
  
  # ========================================
  # GENERATE_CODE - AJAX endpoint for auto code
  # ========================================
  def generate_code
    render json: { code: WorkCenter.generate_next_code }
  end
  
  private
  
  # ========================================
  # BEFORE ACTIONS
  # ========================================
  def set_work_center
    @work_center = WorkCenter.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to work_centers_path, alert: "Work Center not found."
  end
  
  def load_dropdowns
    @warehouses = Warehouse.where(deleted: false, is_active: true).order(:name)
    @locations = Location.where(deleted: false).order(:name)
    @work_center_types = WorkCenter::WORK_CENTER_TYPES.keys.map{|c| [c.titleize, c]}
  end
  
  # ========================================
  # STRONG PARAMETERS
  # ========================================
  def work_center_params
    params.require(:work_center).permit(
      :code,
      :name,
      :description,
      :work_center_type,
      :location_id,
      :warehouse_id,
      :capacity_per_hour,
      :efficiency_percent,
      :labor_cost_per_hour,
      :overhead_cost_per_hour,
      :setup_time_minutes,
      :queue_time_minutes,
      :is_active,
      :notes
    )
  end
end

============================================================================
# FILE: work_order_materials_controller.rb
# PATH: work_order_materials_controller.rb
============================================================================

# app/controllers/work_order_materials_controller.rb

class WorkOrderMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_order
  before_action :set_material, only: [:allocate, :issue, :record_consumption, :return_material]
  
  # ========================================
  # ALLOCATE - Allocate material from inventory
  # ========================================
  def allocate
    unless @material.status == 'REQUIRED'
      flash[:error] = "Material has already been allocated"
      redirect_to work_order_path(@work_order) and return
    end
    
    location = Location.find(params[:location_id])
    batch = params[:batch_id].present? ? StockBatch.find(params[:batch_id]) : nil
    qty = params[:quantity].to_d
    
    if @material.allocate_material!(location, batch, qty)
      flash[:success] = "Material '#{@material.display_name}' allocated successfully"
    else
      flash[:error] = "Failed to allocate material: #{@material.errors.full_messages.join(', ')}"
    end
    
    redirect_to work_order_path(@work_order)
  end
  
  # ========================================
  # ISSUE - Issue material to production
  # ========================================
  def issue
    unless @material.status == 'ALLOCATED'
      flash[:error] = "Material must be allocated before issuing"
      redirect_to work_order_path(@work_order) and return
    end
    
    qty = params[:quantity].to_d || @material.quantity_allocated
    
    if @material.issue_material!(current_user, qty)
      flash[:success] = "Material '#{@material.display_name}' issued to production successfully"
    else
      flash[:error] = "Failed to issue material: #{@material.errors.full_messages.join(', ')}"
    end
    
    redirect_to work_order_path(@work_order)
  end
  
  # ========================================
  # RECORD_CONSUMPTION - Record actual consumption
  # ========================================
  def record_consumption
    unless ['ISSUED', 'CONSUMED'].include?(@material.status)
      flash[:error] = "Material must be issued before recording consumption"
      redirect_to work_order_path(@work_order) and return
    end
    
    qty = params[:quantity_consumed].to_d
    
    if @material.record_consumption!(qty)
      flash[:success] = "Consumption recorded for material '#{@material.display_name}'"
    else
      flash[:error] = "Failed to record consumption: #{@material.errors.full_messages.join(', ')}"
    end
    
    redirect_to work_order_path(@work_order)
  end
  
  # ========================================
  # RETURN_MATERIAL - Return excess material
  # ========================================
  def return_material
    unless @material.status == 'CONSUMED'
      flash[:error] = "Can only return materials that have been consumed"
      redirect_to work_order_path(@work_order) and return
    end
    
    qty = params[:quantity_to_return].to_d
    
    if @material.return_material!(qty, current_user)
      flash[:success] = "Material '#{@material.display_name}' returned to inventory successfully"
    else
      flash[:error] = "Failed to return material: #{@material.errors.full_messages.join(', ')}"
    end
    
    redirect_to work_order_path(@work_order)
  end
  
  private
  
  def set_work_order
    @work_order = WorkOrder.non_deleted.find(params[:work_order_id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Work Order not found"
    redirect_to work_orders_path
  end
  
  def set_material
    @material = @work_order.work_order_materials.non_deleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Material not found"
    redirect_to work_order_path(@work_order)
  end
end

============================================================================
# FILE: work_order_operations_controller.rb
# PATH: work_order_operations_controller.rb
============================================================================

# app/controllers/work_order_operations_controller.rb

class WorkOrderOperationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_order
  before_action :set_operation, only: [:start, :complete, :update_time]
  
  # ========================================
  # START - Start an Operation
  # ========================================
  def start
    unless @operation.status == 'PENDING'
      flash[:error] = "Operation has already been started"
      redirect_to work_order_path(@work_order) and return
    end
    
    if @operation.start_operation!(current_user)
      flash[:success] = "Operation '#{@operation.operation_name}' started successfully"
    else
      flash[:error] = "Failed to start operation: #{@operation.errors.full_messages.join(', ')}"
    end
    
    redirect_to work_order_path(@work_order)
  end
  
  # ========================================
  # COMPLETE - Complete an Operation
  # ========================================
  def complete
    # Validate operation can be completed
    unless @operation.can_be_completed?
      if @operation.has_active_clock_in?
        flash[:error] = "Cannot complete operation while someone is clocked in. Please clock out first."
      else
        flash[:error] = "This operation cannot be completed at this time."
      end
      redirect_to work_order_path(@operation.work_order) and return
    end
    
    @operation.status = 'COMPLETED'
    @operation.completed_at = Time.current
    
    # IMPORTANT: Use labor time entries for actual time if available
    if @operation.labor_time_entries.any?
      # Calculate from labor entries
      total_minutes = @operation.total_labor_minutes
      
      # You can still allow manual setup time entry
      # or auto-split it
      setup_minutes = params[:actual_setup_minutes].to_f
      
      if setup_minutes > 0
        @operation.actual_setup_minutes = setup_minutes
        @operation.actual_run_minutes = [total_minutes - setup_minutes, 0].max
      else
        # Auto-split: assume planned setup ratio
        if @operation.planned_total_minutes > 0
          setup_ratio = @operation.planned_setup_minutes.to_f / @operation.planned_total_minutes
          @operation.actual_setup_minutes = (total_minutes * setup_ratio).round(2)
          @operation.actual_run_minutes = total_minutes - @operation.actual_setup_minutes
        else
          @operation.actual_setup_minutes = 0
          @operation.actual_run_minutes = total_minutes
        end
      end
      
      @operation.actual_total_minutes = total_minutes
    else
      # No labor entries, use manual entry (old behavior)
      @operation.actual_setup_minutes = params[:actual_setup_minutes].to_f
      @operation.actual_run_minutes = params[:actual_run_minutes].to_f
      @operation.actual_total_minutes = @operation.actual_setup_minutes + @operation.actual_run_minutes
    end
    
    # Quantity tracking
    @operation.quantity_completed = params[:quantity_completed].to_f
    @operation.quantity_scrapped = params[:quantity_scrapped].to_f
    
    # Calculate actual cost
    # @operation.calculate_actual_cost
    
    if @operation.save
      # Check if all operations are completed
      # @operation.work_order.check_and_update_progress
      
      flash[:success] = "Operation completed successfully!"
    else
      flash[:error] = "Failed to complete operation: #{@operation.errors.full_messages.join(', ')}"
    end
    
    redirect_to work_order_path(@operation.work_order)
  end
  
  # ========================================
  # UPDATE_TIME - Update time tracking for operation
  # ========================================
  def update_time
    @operation.actual_setup_minutes = params[:actual_setup_minutes].to_i
    @operation.actual_run_minutes = params[:actual_run_minutes].to_i
    @operation.actual_total_minutes = @operation.actual_setup_minutes + @operation.actual_run_minutes
    @operation.notes = params[:notes] if params[:notes].present?
    
    if @operation.save
      flash[:success] = "Time updated successfully for operation '#{@operation.operation_name}'"
    else
      flash[:error] = "Failed to update time: #{@operation.errors.full_messages.join(', ')}"
    end
    
    redirect_to work_order_path(@work_order)
  end
  
  private
  
  def set_work_order
    @work_order = WorkOrder.non_deleted.find(params[:work_order_id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Work Order not found"
    redirect_to work_orders_path
  end
  
  def set_operation
    @operation = @work_order.work_order_operations.non_deleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Operation not found"
    redirect_to work_order_path(@work_order)
  end
end

============================================================================
# FILE: work_order_reports_controller.rb
# PATH: work_order_reports_controller.rb
============================================================================

# app/controllers/reports/work_order_reports_controller.rb
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

============================================================================
# FILE: work_orders_controller.rb
# PATH: work_orders_controller.rb
============================================================================

class WorkOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_order, only: [:show, :edit, :update, :destroy, :release, :start_production, :complete, :cancel]
  
  # ========================================
  # INDEX - List all Work Orders
  # ========================================
  def index
    @work_orders = WorkOrder.non_deleted
                            .includes(:product, :warehouse, :created_by)
                            .order(created_at: :desc)
    
    # Filters
    @work_orders = @work_orders.by_status(params[:status]) if params[:status].present?
    @work_orders = @work_orders.by_priority(params[:priority]) if params[:priority].present?
    @work_orders = @work_orders.by_warehouse(params[:warehouse_id]) if params[:warehouse_id].present?
    @work_orders = @work_orders.by_product(params[:product_id]) if params[:product_id].present?
    
    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      @work_orders = @work_orders.scheduled_between(params[:start_date], params[:end_date])
    end
    
    # Search by WO number
    if params[:search].present?
      @work_orders = @work_orders.where("wo_number ILIKE ?", "%#{params[:search]}%")
    end
    
    # Pagination
    @work_orders = @work_orders.page(params[:page]).per(20)
    
    # For filters dropdowns
    @warehouses = Warehouse.non_deleted.where(is_active: true).order(:name)
    @products = Product.non_deleted.where(product_type: ['Finished Goods', 'Semi-Finished Goods']).order(:name)
    
    # Stats for dashboard cards
    @stats = {
      total: WorkOrder.non_deleted.count,
      not_started: WorkOrder.non_deleted.by_status('NOT_STARTED').count,
      released: WorkOrder.non_deleted.by_status('RELEASED').count,
      in_progress: WorkOrder.non_deleted.by_status('IN_PROGRESS').count,
      completed: WorkOrder.non_deleted.by_status('COMPLETED').count
    }
  end
  
  # ========================================
  # SHOW - Work Order Detail Page
  # ========================================
  def show
    @operations = @work_order.work_order_operations.includes(:work_center, :operator).order(:sequence_no)
    @materials = @work_order.work_order_materials.includes(:product, :uom, :location, :batch)
    
    # Calculate progress
    @operations_progress = @work_order.operations_progress_percentage
    @quantity_progress = @work_order.progress_percentage
    
    # Variance analysis
    @cost_variance = @work_order.cost_variance
    @cost_variance_percent = @work_order.cost_variance_percent
  end
  
  # ========================================
  # NEW - Form to create new Work Order
  # ========================================
  def new
    @work_order = WorkOrder.new
    @work_order.priority = 'NORMAL'
    @work_order.scheduled_start_date = Date.current
    @work_order.scheduled_end_date = Date.current + 7.days
    
    # For dropdowns
    load_form_data
  end
  
  # ========================================
  # CREATE - Save new Work Order
  # ========================================
  def create
    @work_order = WorkOrder.new(work_order_params)
    @work_order.created_by = current_user
    @work_order.status = 'NOT_STARTED'
    
    if @work_order.save
      flash[:success] = "Work Order #{@work_order.wo_number} created successfully!"
      redirect_to work_order_path(@work_order)
    else
      flash.now[:error] = "Failed to create Work Order: #{@work_order.errors.full_messages.join(', ')}"
      load_form_data
      render :new
    end
  end
  
  # ========================================
  # EDIT - Form to edit Work Order
  # ========================================
  def edit
    # Only allow editing if NOT_STARTED
    unless @work_order.status == 'NOT_STARTED'
      flash[:warning] = "Cannot edit Work Order that has been released or is in production"
      redirect_to work_order_path(@work_order) and return
    end
    
    load_form_data
  end
  
  # ========================================
  # UPDATE - Save changes to Work Order
  # ========================================
  def update
    # Only allow editing if NOT_STARTED
    unless @work_order.status == 'NOT_STARTED'
      flash[:warning] = "Cannot edit Work Order that has been released or is in production"
      redirect_to work_order_path(@work_order) and return
    end
    
    if @work_order.update(work_order_params)
      # Recalculate planned costs if quantity changed
      if @work_order.saved_change_to_quantity_to_produce?
        @work_order.calculate_planned_costs
        @work_order.save
      end
      
      flash[:success] = "Work Order updated successfully!"
      redirect_to work_order_path(@work_order)
    else
      flash.now[:error] = "Failed to update Work Order: #{@work_order.errors.full_messages.join(', ')}"
      load_form_data
      render :edit
    end
  end
  
  # ========================================
  # DESTROY - Soft delete Work Order
  # ========================================
  def destroy
    # Only allow deletion if NOT_STARTED
    unless @work_order.status == 'NOT_STARTED'
      flash[:error] = "Cannot delete Work Order that has been released or is in production"
      redirect_to work_order_path(@work_order) and return
    end
    
    if @work_order.destroy!
      flash[:success] = "Work Order deleted successfully!"
      redirect_to work_orders_path
    else
      flash[:error] = "Failed to delete Work Order"
      redirect_to work_order_path(@work_order)
    end
  end
  
  # ========================================
  # RELEASE - Release Work Order to Production
  # ========================================
  def release
    unless @work_order.can_be_released?
      flash[:error] = "Work Order cannot be released. Check if BOM and Routing are active."
      redirect_to work_order_path(@work_order) and return
    end
    
    # Check material availability (optional - can be a warning instead of blocking)
    shortage_details = check_material_availability_detailed
    
    if shortage_details.any?
      flash[:warning] = "Some materials may not be available in sufficient quantity. Please verify stock levels."
      WorkOrderNotificationJob.perform_later(
        'material_shortage', 
        @work_order.id, 
        current_user.email, 
        { shortage_details: shortage_details }
      )
      # Optionally: redirect and don't allow release
      # redirect_to work_order_path(@work_order) and return
    end
    
    @work_order.status = 'RELEASED'
    @work_order.released_by = current_user
    
    if @work_order.save
      flash[:success] = "Work Order #{@work_order.wo_number} released to production successfully! Operations and Materials have been created."
      redirect_to work_order_path(@work_order)
    else
      flash[:error] = "Failed to release Work Order: #{@work_order.errors.full_messages.join(', ')}"
      redirect_to work_order_path(@work_order)
    end
  end
  
  # ========================================
  # START_PRODUCTION - Mark WO as In Progress
  # ========================================
  def start_production
    unless @work_order.can_start_production?
      flash[:error] = "Work Order cannot be started. Status must be RELEASED."
      redirect_to work_order_path(@work_order) and return
    end
    
    @work_order.status = 'IN_PROGRESS'
    
    if @work_order.save
      flash[:success] = "Production started for Work Order #{@work_order.wo_number}"
      redirect_to work_order_path(@work_order)
    else
      flash[:error] = "Failed to start production: #{@work_order.errors.full_messages.join(', ')}"
      redirect_to work_order_path(@work_order)
    end
  end
  
  # ========================================
  # COMPLETE - Mark WO as Completed
  # ========================================
  def complete
    unless @work_order.can_be_completed?
      flash[:error] = "Work Order cannot be completed. All operations must be completed first."
      redirect_to work_order_path(@work_order) and return
    end
    
    # Get completion quantity from params (optional - allow partial completion)
    completion_qty = params[:quantity_completed] || @work_order.quantity_to_produce
    
    @work_order.quantity_completed = completion_qty
    @work_order.status = 'COMPLETED'
    @work_order.completed_at = Time.current
    @work_order.completed_by = current_user

    if @work_order.save
      flash[:success] = "Work Order #{@work_order.wo_number} completed successfully! Finished goods have been received to inventory."
      redirect_to work_order_path(@work_order)
    else
      flash[:error] = "Failed to complete Work Order: #{@work_order.errors.full_messages.join(', ')}"
      redirect_to work_order_path(@work_order)
    end
  end
  
  # ========================================
  # CANCEL - Cancel Work Order
  # ========================================
  def cancel

    unless @work_order.can_be_cancelled?
      flash[:error] = "Work Order cannot be cancelled at this stage."
      redirect_to work_order_path(@work_order) and return
    end
    
    @work_order.status = 'CANCELLED'
    if @work_order.save
      flash[:success] = "Work Order #{@work_order.wo_number} cancelled successfully. Materials returned to inventory."
      redirect_to work_order_path(@work_order)
    else
      flash[:error] = "Failed to cancel Work Order: #{@work_order.errors.full_messages.join(', ')}"
      redirect_to work_order_path(@work_order)
    end
  end

  def send_shortage_alert
    shortage_details = @work_order.check_material_shortages
    
    if shortage_details.any?
      # Send to current user
      WorkOrderNotificationJob.perform_later(
        'material_shortage', 
        @work_order.id, 
        current_user.email, 
        { shortage_details: shortage_details }
      )
      
      # Send to inventory manager if configured
      inventory_manager_email = ENV['INVENTORY_MANAGER_EMAIL']
      if inventory_manager_email.present?
        WorkOrderNotificationJob.perform_later(
          'material_shortage', 
          @work_order.id, 
          inventory_manager_email, 
          { shortage_details: shortage_details }
        )
      end
      
      flash[:success] = "Material shortage alert sent successfully!"
    else
      flash[:info] = "No material shortages detected for this work order."
    end
    
    redirect_to work_order_path(@work_order)
  end
  
  private
  
  # ========================================
  # PRIVATE METHODS
  # ========================================
  
  def set_work_order
    @work_order = WorkOrder.non_deleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Work Order not found"
    redirect_to work_orders_path
  end
  
  def work_order_params
    params.require(:work_order).permit(
      :product_id,
      :customer_id,
      :warehouse_id,
      :quantity_to_produce,
      :uom_id,
      :priority,
      :scheduled_start_date,
      :scheduled_end_date,
      :notes
    )
  end
  
  def load_form_data
    @products = Product.non_deleted
                      .where(product_type: ['Finished Goods', 'Semi-Finished Goods'])
                      .where(is_active: true)
                      .order(:name)
    
    @warehouses = Warehouse.non_deleted
                          .where(is_active: true)
                          .order(:name)
    
    @customers = Customer.non_deleted
                        .where(is_active: true)
                        .order(:full_name)
    
    @uoms = UnitOfMeasure.non_deleted.order(:name)
  end

  def check_material_availability_detailed
    return [] unless @work_order.bom.present?
    
    shortage_details = []
    
    @work_order.bom.bom_items.where(deleted: false).each do |bom_item|
      required_qty = bom_item.quantity * @work_order.quantity_to_produce
      
      # Consider scrap percentage
      if bom_item.scrap_percent.to_d > 0
        scrap_factor = 1 + (bom_item.scrap_percent.to_d / 100)
        required_qty = required_qty * scrap_factor
      end
      
      # Check available stock in warehouse
      available_qty = StockLevel.joins(:location)
                                .where(product_id: bom_item.component_id)
                                .where(locations: { warehouse_id: @work_order.warehouse_id })
                                .sum(:on_hand_qty)
      
      if available_qty < required_qty
        shortage_details << {
          material_code: bom_item.component.sku,
          material_name: bom_item.component.name,
          required_qty: required_qty.round(4),
          available_qty: available_qty.round(4),
          shortage_qty: (required_qty - available_qty).round(4),
          uom: bom_item.uom.symbol,
          product_type: bom_item.component.product_type
        }
        
        Rails.logger.warn "Material shortage for WO #{@work_order.wo_number}: " \
                         "#{bom_item.component.sku} - Required: #{required_qty}, Available: #{available_qty}"
      end
    end
    
    shortage_details
  end

  def check_material_availability
    return true unless @work_order.bom.present?
    
    all_available = true
    
    @work_order.bom.bom_items.each do |bom_item|
      required_qty = bom_item.quantity * @work_order.quantity_to_produce
      
      available_qty = StockLevel.where(
        product_id: bom_item.component_id,
        location: @work_order.warehouse.locations
      ).sum(:on_hand_qty)
      
      if available_qty < required_qty
        all_available = false
        Rails.logger.warn "Material #{bom_item.component.sku} - Required: #{required_qty}, Available: #{available_qty}"
      end
    end
    
    all_available
  end
end


# ============ NAMESPACE: Inventory ============

module Inventory

  ============================================================================
  # FILE: base_controller.rb
  # PATH: inventory/base_controller.rb
  ============================================================================

  # app/controllers/inventory/base_controller.rb
  
  module Inventory
    class BaseController < ApplicationController
      before_action :authenticate_user!
      # layout 'inventory'
      
      private
      
      # Common flash messages
      def set_success_message(message)
        flash[:success] = message
      end
      
      def set_error_message(message)
        flash[:error] = message
      end
      
      def set_warning_message(message)
        flash[:warning] = message
      end
      
      # Common redirects
      def redirect_back_or_to(default_path)
        redirect_to request.referer || default_path
      end
      
      # Pagination
      def per_page
        params[:per_page] || 25
      end
      
      # Common filters
      def apply_date_filters(relation)
        relation = relation.where('created_at >= ?', params[:from_date]) if params[:from_date].present?
        relation = relation.where('created_at <= ?', params[:to_date]) if params[:to_date].present?
        relation
      end
      
      # Check permissions (add your authorization logic)
      def authorize_inventory_access!
        # Example: unless current_user.can?(:access_inventory)
        #   redirect_to root_path, alert: "Access denied"
        # end
      end
    end
  end

  ============================================================================
  # FILE: cycle_counts_controller.rb
  # PATH: inventory/cycle_counts_controller.rb
  ============================================================================

  # app/controllers/inventory/cycle_counts_controller.rb
  
  module Inventory
    class CycleCountsController < BaseController
      before_action :set_cycle_count, only: [:show, :edit, :update, :destroy, :start_counting, :complete_count, :post_count, :print, :variance_report]
      
      def index
        @cycle_counts = CycleCount.active
                                   .includes(:warehouse, :scheduled_by, :counted_by)
                                   .order(scheduled_at: :desc)
        
        @cycle_counts = @cycle_counts.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
        @cycle_counts = @cycle_counts.where(status: params[:status]) if params[:status].present?
        
        @cycle_counts = @cycle_counts.page(params[:page]).per(per_page)
      end
      
      def upcoming
        @cycle_counts = CycleCount.upcoming.page(params[:page]).per(per_page)
        render :index
      end
      
      def overdue
        @cycle_counts = CycleCount.overdue.page(params[:page]).per(per_page)
        render :index
      end
      
      def show
        @lines = @cycle_count.lines.includes(:product, :location, :batch, :uom)
      end
      
      def new
        @cycle_count = CycleCount.new(
          scheduled_at: Time.current,
          status: CycleCount::STATUS_SCHEDULED
        )
        @cycle_count.lines.build
      end
      
      def edit
        unless @cycle_count.can_edit?
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      alert: "Cannot edit Count in #{@cycle_count.status} status"
          return
        end
        @cycle_count.lines.build if @cycle_count.lines.empty?
      end
      
      def create
        @cycle_count = CycleCount.new(cycle_count_params)
        @cycle_count.scheduled_by = current_user
        
        if @cycle_count.save
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      notice: "Cycle Count #{@cycle_count.reference_no} scheduled."
        else
          render :new, status: :unprocessable_entity
        end
      end
      
      def update
        unless @cycle_count.can_edit?
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      alert: "Cannot edit Count in #{@cycle_count.status} status"
          return
        end
        
        if @cycle_count.update(cycle_count_params)
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      notice: "Cycle Count updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end
      
      def destroy
        unless @cycle_count.can_edit?
          redirect_to inventory_cycle_counts_path, 
                      alert: "Cannot delete Count in #{@cycle_count.status} status"
          return
        end
        
        @cycle_count.update(deleted: true)
        redirect_to inventory_cycle_counts_path, notice: "Cycle Count deleted."
      end
      
      def start_counting
        if @cycle_count.start_counting!(user: current_user)
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      notice: "Counting started! System quantities captured."
        else
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      alert: "Failed to start: #{@cycle_count.errors.full_messages.join(', ')}"
        end
      end
      
      def complete_count
        if @cycle_count.complete!(user: current_user)
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      notice: "Count completed! Review variances before posting."
        else
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      alert: "Failed to complete: #{@cycle_count.errors.full_messages.join(', ')}"
        end
      end
      
      def post_count
        if @cycle_count.post!(user: current_user)
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      notice: "Count posted! Variances adjusted in stock."
        else
          redirect_to inventory_cycle_count_path(@cycle_count), 
                      alert: "Failed to post: #{@cycle_count.errors.full_messages.join(', ')}"
        end
      end
      
      def variance_report
        @lines_with_variance = @cycle_count.lines.where.not(variance: 0).order(variance: :desc)
        respond_to do |format|
          format.html
          format.pdf { render pdf: "Variance-#{@cycle_count.reference_no}" }
        end
      end
      
      def print
        respond_to do |format|
          format.pdf { render pdf: "COUNT-#{@cycle_count.reference_no}" }
          format.html { render :print, layout: 'print' }
        end
      end
      
      private
      
      def set_cycle_count
        @cycle_count = CycleCount.find(params[:id])
      end
      
      def cycle_count_params
        params.require(:cycle_count).permit(
          :warehouse_id,
          :scheduled_at,
          :count_type,
          :notes,
          lines_attributes: [
            :id, :product_id, :location_id, :batch_id, :uom_id,
            :counted_qty, :line_note, :_destroy
          ]
        )
      end
    end
  end

  ============================================================================
  # FILE: dashboard_controller.rb
  # PATH: inventory/dashboard_controller.rb
  ============================================================================

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

  ============================================================================
  # FILE: goods_receipts_controller.rb
  # PATH: inventory/goods_receipts_controller.rb
  ============================================================================

  # app/controllers/inventory/goods_receipts_controller.rb
  
  module Inventory
    class GoodsReceiptsController < BaseController
      before_action :set_goods_receipt, only: [:show, :edit, :update, :destroy, :post_receipt, :print]
      
      # GET /inventory/goods_receipts
      def index
        @goods_receipts = GoodsReceipt.active
                                      .includes(:warehouse, :supplier, :purchase_order, :created_by)
                                      .order(receipt_date: :desc)
        
        # Filters
        @goods_receipts = @goods_receipts.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
        @goods_receipts = @goods_receipts.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?
        @goods_receipts = @goods_receipts.where(status: params[:status]) if params[:status].present?
        @goods_receipts = apply_date_filters(@goods_receipts)
        
        # Search
        if params[:search].present?
          @goods_receipts = @goods_receipts.where(
            "reference_no ILIKE ? OR notes ILIKE ?", 
            "%#{params[:search]}%", 
            "%#{params[:search]}%"
          )
        end
        
        @goods_receipts = @goods_receipts.page(params[:page]).per(per_page)
      end
      
      # GET /inventory/goods_receipts/1
      def show
        @lines = @goods_receipt.lines.includes(:product, :location, :batch, :uom)
      end
      
      # GET /inventory/goods_receipts/new
      def new
        @goods_receipt = GoodsReceipt.new(
          receipt_date: Date.current,
          status: GoodsReceipt::STATUS_DRAFT
        )
        
        # Build initial line
        @goods_receipt.lines.build
      end
      
      # GET /inventory/goods_receipts/from_po?po_id=123
      def from_po
        @purchase_order = PurchaseOrder.find(params[:po_id])
        
        unless @purchase_order.can_receive?
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      alert: "This PO cannot be received. Status: #{@purchase_order.status}"
          return
        end
        
        @goods_receipt = GoodsReceipt.new(
          purchase_order: @purchase_order,
          warehouse: @purchase_order.warehouse,
          supplier: @purchase_order.supplier,
          receipt_date: Date.current,
          status: GoodsReceipt::STATUS_DRAFT
        )
        
        # Auto-populate lines from PO lines with outstanding qty
        @purchase_order.lines.where("received_qty < ordered_qty").each do |po_line|
          @goods_receipt.lines.build(
            product: po_line.product,
            uom: po_line.uom,
            qty: po_line.outstanding_qty,
            location: nil  # User will select
          )
        end
        
        render :new
      end
      
      # GET /inventory/goods_receipts/1/edit
      def edit
        unless @goods_receipt.can_edit?
          redirect_to inventory_goods_receipt_path(@goods_receipt), 
                      alert: "Cannot edit GRN in #{@goods_receipt.status} status"
          return
        end
        
        @goods_receipt.lines.build if @goods_receipt.lines.empty?
      end
      
      # POST /inventory/goods_receipts
      def create
        @goods_receipt = GoodsReceipt.new(goods_receipt_params)
        @goods_receipt.created_by = current_user
        
        if @goods_receipt.save
          redirect_to inventory_goods_receipt_path(@goods_receipt), 
                      notice: "Goods Receipt #{@goods_receipt.reference_no} created successfully."
        else
          render :new, status: :unprocessable_entity
        end
      end
      
      # PATCH /inventory/goods_receipts/1
      def update
        unless @goods_receipt.can_edit?
          redirect_to inventory_goods_receipt_path(@goods_receipt), 
                      alert: "Cannot edit GRN in #{@goods_receipt.status} status"
          return
        end
        
        if @goods_receipt.update(goods_receipt_params)
          redirect_to inventory_goods_receipt_path(@goods_receipt), 
                      notice: "Goods Receipt updated successfully."
        else
          render :edit, status: :unprocessable_entity
        end
      end
      
      # DELETE /inventory/goods_receipts/1
      def destroy
        unless @goods_receipt.can_edit?
          redirect_to inventory_goods_receipts_path, 
                      alert: "Cannot delete GRN in #{@goods_receipt.status} status"
          return
        end
        
        @goods_receipt.update(deleted: true)
        redirect_to inventory_goods_receipts_path, 
                    notice: "Goods Receipt deleted successfully."
      end
      
      # POST /inventory/goods_receipts/1/post_receipt
      def post_receipt
        if @goods_receipt.post!(user: current_user)
          redirect_to inventory_goods_receipt_path(@goods_receipt), 
                      notice: "Goods Receipt posted successfully! Stock levels updated."
        else
          redirect_to inventory_goods_receipt_path(@goods_receipt), 
                      alert: "Failed to post: #{@goods_receipt.errors.full_messages.join(', ')}"
        end
      end
      
      # GET /inventory/goods_receipts/1/print
      def print
        respond_to do |format|
          format.pdf do
            render pdf: "GRN-#{@goods_receipt.reference_no}",
                   template: 'inventory/goods_receipts/print',
                   layout: 'pdf'
          end
          format.html { render :print, layout: 'print' }
        end
      end
      
      private
      
      def set_goods_receipt
        @goods_receipt = GoodsReceipt.find(params[:id])
      end
      
      def goods_receipt_params
        params.require(:goods_receipt).permit(
          :warehouse_id,
          :supplier_id,
          :purchase_order_id,
          :receipt_date,
          :notes,
          lines_attributes: [
            :id,
            :product_id,
            :location_id,
            :batch_id,
            :uom_id,
            :qty,
            :unit_cost,
            :line_note,
            :_destroy
          ]
        )
      end
    end
  end

  ============================================================================
  # FILE: purchase_orders_controller.rb
  # PATH: inventory/purchase_orders_controller.rb
  ============================================================================

  # app/controllers/inventory/purchase_orders_controller.rb
  
  module Inventory
    class PurchaseOrdersController < BaseController
      before_action :set_purchase_order, only: [:show, :edit, :update, :destroy, :confirm, :cancel, :close, :print]
      
      # GET /inventory/purchase_orders
      def index
        @purchase_orders = PurchaseOrder.active
                                        .includes(:supplier, :warehouse, :created_by)
                                        .order(order_date: :desc)
        
        # Filters
        @purchase_orders = @purchase_orders.by_supplier(params[:supplier_id]) if params[:supplier_id].present?
        @purchase_orders = @purchase_orders.by_status(params[:status]) if params[:status].present?
        @purchase_orders = apply_date_filters(@purchase_orders)
        
        # Search
        if params[:search].present?
          @purchase_orders = @purchase_orders.where(
            "po_number ILIKE ? OR notes ILIKE ?", 
            "%#{params[:search]}%", 
            "%#{params[:search]}%"
          )
        end
        
        @purchase_orders = @purchase_orders.page(params[:page]).per(per_page)
      end
      
      # GET /inventory/purchase_orders/open_pos
      def open_pos
        @purchase_orders = PurchaseOrder.open_pos
                                        .includes(:supplier, :lines)
                                        .order(expected_date: :asc)
                                        .page(params[:page]).per(per_page)
        
        render :index
      end
      
      # GET /inventory/purchase_orders/overdue
      def overdue
        @purchase_orders = PurchaseOrder.active
                                        .where('expected_date < ?', Date.current)
                                        .where(status: [PurchaseOrder::STATUS_CONFIRMED, 
                                                       PurchaseOrder::STATUS_PARTIALLY_RECEIVED])
                                        .includes(:supplier)
                                        .order(expected_date: :asc)
                                        .page(params[:page]).per(per_page)
        
        render :index
      end
      
      # GET /inventory/purchase_orders/1
      def show
        @lines = @purchase_order.lines.includes(:product, :uom)
      end
      
      # GET /inventory/purchase_orders/new
      def new
        @purchase_order = PurchaseOrder.new(
          order_date: Date.current,
          currency: 'USD',
          status: PurchaseOrder::STATUS_DRAFT
        )
        
        # Build initial line
        @purchase_order.lines.build
      end
      
      # GET /inventory/purchase_orders/1/edit
      def edit
        unless @purchase_order.can_edit?
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      alert: "Cannot edit PO in #{@purchase_order.status} status"
          return
        end
        
        # Build one empty line for adding more items
        @purchase_order.lines.build if @purchase_order.lines.empty?
      end
      
      # POST /inventory/purchase_orders
      def create
        @purchase_order = PurchaseOrder.new(purchase_order_params)
        @purchase_order.created_by = current_user
        
        if @purchase_order.save
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      notice: "Purchase Order #{@purchase_order.po_number} created successfully."
        else
          render :new, status: :unprocessable_entity
        end
      end
      
      # PATCH /inventory/purchase_orders/1
      def update
        unless @purchase_order.can_edit?
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      alert: "Cannot edit PO in #{@purchase_order.status} status"
          return
        end
        
        if @purchase_order.update(purchase_order_params)
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      notice: "Purchase Order updated successfully."
        else
          render :edit, status: :unprocessable_entity
        end
      end
      
      # DELETE /inventory/purchase_orders/1
      def destroy
        unless @purchase_order.can_delete?
          redirect_to inventory_purchase_orders_path, 
                      alert: "Cannot delete PO in #{@purchase_order.status} status. Use Cancel instead."
          return
        end
        
        @purchase_order.update(deleted: true)
        redirect_to inventory_purchase_orders_path, 
                    notice: "Purchase Order deleted successfully."
      end
      
      # POST /inventory/purchase_orders/1/confirm
      def confirm
        if @purchase_order.confirm!(user: current_user)
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      notice: "Purchase Order confirmed successfully. PO is now official!"
        else
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      alert: "Failed to confirm: #{@purchase_order.errors.full_messages.join(', ')}"
        end
      end
      
      # POST /inventory/purchase_orders/1/cancel
      def cancel
        if @purchase_order.cancel!(user: current_user)
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      notice: "Purchase Order cancelled."
        else
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      alert: "Failed to cancel: #{@purchase_order.errors.full_messages.join(', ')}"
        end
      end
      
      # POST /inventory/purchase_orders/1/close
      def close
        if @purchase_order.close!(user: current_user)
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      notice: "Purchase Order closed successfully."
        else
          redirect_to inventory_purchase_order_path(@purchase_order), 
                      alert: "Failed to close: #{@purchase_order.errors.full_messages.join(', ')}"
        end
      end
      
      # GET /inventory/purchase_orders/1/print
      def print
        respond_to do |format|
          format.pdf do
            render pdf: "PO-#{@purchase_order.po_number}",
                   template: 'inventory/purchase_orders/print',
                   layout: 'pdf'
          end
          format.html { render :print, layout: 'print' }
        end
      end
      
      private
      
      def set_purchase_order
        @purchase_order = PurchaseOrder.find(params[:id])
      end
      
      def purchase_order_params
        params.require(:purchase_order).permit(
          :supplier_id,
          :warehouse_id,
          :order_date,
          :expected_date,
          :currency,
          :payment_terms,
          :shipping_method,
          :shipping_address,
          :shipping_cost,
          :notes,
          :internal_notes,
          lines_attributes: [
            :id,
            :product_id,
            :uom_id,
            :ordered_qty,
            :unit_price,
            :tax_code_id,
            :expected_delivery_date,
            :line_note,
            :_destroy
          ]
        )
      end
    end
  end

  ============================================================================
  # FILE: stock_adjustments_controller.rb
  # PATH: inventory/stock_adjustments_controller.rb
  ============================================================================

  # app/controllers/inventory/stock_adjustments_controller.rb
  
  module Inventory
    class StockAdjustmentsController < BaseController
      before_action :set_stock_adjustment, only: [:show, :edit, :update, :destroy, :post_adjustment, :print]
      
      def index
        @stock_adjustments = StockAdjustment.active
                                            .includes(:warehouse, :created_by)
                                            .order(adjustment_date: :desc)
        
        @stock_adjustments = @stock_adjustments.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
        @stock_adjustments = @stock_adjustments.where(status: params[:status]) if params[:status].present?
        @stock_adjustments = apply_date_filters(@stock_adjustments)
        
        if params[:search].present?
          @stock_adjustments = @stock_adjustments.where("reference_no ILIKE ? OR reason ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
        end
        
        @stock_adjustments = @stock_adjustments.page(params[:page]).per(per_page)
      end
      
      def show
        @lines = @stock_adjustment.lines.includes(:product, :location, :batch, :uom)
      end
      
      def new
        @stock_adjustment = StockAdjustment.new(
          adjustment_date: Date.current,
          status: StockAdjustment::STATUS_DRAFT
        )
        @stock_adjustment.lines.build
      end
      
      def edit
        unless @stock_adjustment.can_edit?
          redirect_to inventory_stock_adjustment_path(@stock_adjustment), 
                      alert: "Cannot edit Adjustment in #{@stock_adjustment.status} status"
          return
        end
        @stock_adjustment.lines.build if @stock_adjustment.lines.empty?
      end
      
      def create
        @stock_adjustment = StockAdjustment.new(stock_adjustment_params)
        @stock_adjustment.created_by = current_user
        
        if @stock_adjustment.save
          redirect_to inventory_stock_adjustment_path(@stock_adjustment), 
                      notice: "Stock Adjustment #{@stock_adjustment.reference_no} created."
        else
          render :new, status: :unprocessable_entity
        end
      end
      
      def update
        unless @stock_adjustment.can_edit?
          redirect_to inventory_stock_adjustment_path(@stock_adjustment), 
                      alert: "Cannot edit Adjustment in #{@stock_adjustment.status} status"
          return
        end
        
        if @stock_adjustment.update(stock_adjustment_params)
          redirect_to inventory_stock_adjustment_path(@stock_adjustment), 
                      notice: "Stock Adjustment updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end
      
      def destroy
        unless @stock_adjustment.can_edit?
          redirect_to inventory_stock_adjustments_path, 
                      alert: "Cannot delete Adjustment in #{@stock_adjustment.status} status"
          return
        end
        
        @stock_adjustment.update(deleted: true)
        redirect_to inventory_stock_adjustments_path, notice: "Adjustment deleted."
      end
      
      def post_adjustment
        if @stock_adjustment.post!(user: current_user)
          redirect_to inventory_stock_adjustment_path(@stock_adjustment), 
                      notice: "Adjustment posted! Stock levels updated."
        else
          redirect_to inventory_stock_adjustment_path(@stock_adjustment), 
                      alert: "Failed to post: #{@stock_adjustment.errors.full_messages.join(', ')}"
        end
      end
      
      def print
        respond_to do |format|
          format.pdf { render pdf: "ADJ-#{@stock_adjustment.reference_no}" }
          format.html { render :print, layout: 'print' }
        end
      end
      
      private
      
      def set_stock_adjustment
        @stock_adjustment = StockAdjustment.find(params[:id])
      end
      
      def stock_adjustment_params
        params.require(:stock_adjustment).permit(
          :warehouse_id,
          :adjustment_date,
          :reason,
          :notes,
          lines_attributes: [
            :id, :product_id, :location_id, :batch_id, :uom_id,
            :qty_delta, :system_qty_at_adjustment, :line_reason, :line_note, :_destroy
          ]
        )
      end
    end
  end

  ============================================================================
  # FILE: stock_batches_controller.rb
  # PATH: inventory/stock_batches_controller.rb
  ============================================================================

  # app/controllers/inventory/stock_batches_controller.rb
  
  module Inventory
    class StockBatchesController < ApplicationController
      before_action :set_stock_batch, only: [:show, :edit, :update, :destroy]
      before_action :set_products, only: [:new, :edit, :create, :update]
  
      # GET /inventory/stock_batches
      def index
        @stock_batches = StockBatch.includes(:product, :created_by)
                                    .where(deleted: false)
                                    .order(created_at: :desc)
                                    .page(params[:page])
                                    .per(25)
  
        # Filters
        if params[:product_id].present?
          @stock_batches = @stock_batches.where(product_id: params[:product_id])
        end
  
        if params[:batch_number].present?
          @stock_batches = @stock_batches.where("batch_number ILIKE ?", "%#{params[:batch_number]}%")
        end
  
        if params[:status].present?
          case params[:status]
          when 'active'
            @stock_batches = @stock_batches.where('expiry_date IS NULL OR expiry_date >= ?', Date.today)
          when 'expired'
            @stock_batches = @stock_batches.where('expiry_date < ?', Date.today)
          when 'expiring_soon'
            @stock_batches = @stock_batches.where('expiry_date BETWEEN ? AND ?', Date.today, Date.today + 30.days)
          end
        end
  
        # Calculate current stock for each batch
        @stock_batches.each do |batch|
          batch.current_stock = StockTransaction
            .where(product_id: batch.product_id, batch_id: batch.id)
            .sum(:quantity)
        end
      end
  
      # GET /inventory/stock_batches/:id
      def show
        # Current stock across all locations
        @current_stock = StockTransaction
          .where(product_id: @stock_batch.product_id, batch_id: @stock_batch.id)
          .sum(:quantity)
  
        # Stock by location
        @stock_by_location = StockTransaction
          .joins(:to_location)
          .where(product_id: @stock_batch.product_id, batch_id: @stock_batch.id)
          .group('locations.name')
          .select('locations.name as location_name, SUM(quantity) as total_qty')
          .having('SUM(quantity) > 0')
  
        # Recent transactions for this batch
        @recent_transactions = StockTransaction
          .where(product_id: @stock_batch.product_id, batch_id: @stock_batch.id)
          .order(created_at: :desc)
          .limit(20)
          .includes(:to_location, :created_by)
  
        # Check if batch is expired or expiring soon
        if @stock_batch.expiry_date.present?
          days_to_expire = (@stock_batch.expiry_date - Date.today).to_i
          
          if days_to_expire < 0
            @expiry_status = 'expired'
            @expiry_message = "Expired #{days_to_expire.abs} days ago"
          elsif days_to_expire <= 30
            @expiry_status = 'expiring_soon'
            @expiry_message = "Expires in #{days_to_expire} days"
          else
            @expiry_status = 'active'
            @expiry_message = "Expires on #{@stock_batch.expiry_date.strftime('%b %d, %Y')}"
          end
        end
      end
  
      # GET /inventory/stock_batches/new
      def new
        @stock_batch = StockBatch.new
        
        # Pre-fill product if coming from product page
        if params[:product_id].present?
          @stock_batch.product_id = params[:product_id]
        end
      end
  
      # GET /inventory/stock_batches/:id/edit
      def edit
      end
  
      # POST /inventory/stock_batches
      def create
        @stock_batch = StockBatch.new(stock_batch_params)
        @stock_batch.created_by = current_user
  
        if @stock_batch.save
          redirect_to inventory_stock_batch_path(@stock_batch), 
                      notice: "Batch #{@stock_batch.batch_number} created successfully."
        else
          render :new, status: :unprocessable_entity
        end
      end
  
      # PATCH/PUT /inventory/stock_batches/:id
      def update
        if @stock_batch.update(stock_batch_params)
          redirect_to inventory_stock_batch_path(@stock_batch), 
                      notice: "Batch #{@stock_batch.batch_number} updated successfully."
        else
          render :edit, status: :unprocessable_entity
        end
      end
  
      # DELETE /inventory/stock_batches/:id (Soft delete)
      def destroy
        # Check if batch has any stock
        current_stock = StockTransaction
          .where(product_id: @stock_batch.product_id, batch_id: @stock_batch.id)
          .sum(:quantity)
  
        if current_stock > 0
          redirect_to inventory_stock_batch_path(@stock_batch), 
                      alert: "Cannot delete batch with existing stock (Current: #{current_stock})"
          return
        end
  
        @stock_batch.update(deleted: true)
        redirect_to inventory_stock_batches_path, 
                    notice: "Batch #{@stock_batch.batch_number} deleted successfully."
      end
  
      # GET /inventory/stock_batches/search (AJAX endpoint)
      def search
        product_id = params[:product_id]
        warehouse_id = params[:warehouse_id]
  
        if product_id.blank?
          render json: []
          return
        end
  
        # Get batches with available stock
        batches = StockBatch
          .where(product_id: product_id, deleted: false)
          .order(batch_number: :asc)
  
        batch_data = batches.map do |batch|
          # Calculate available stock
          query = StockTransaction.where(product_id: batch.product_id, batch_id: batch.id)
          
          if warehouse_id.present?
            query = query.joins(:to_location).where(locations: { warehouse_id: warehouse_id })
          end
          
          available_qty = query.sum(:quantity)
  
          # Only include batches with stock
          if available_qty > 0
            {
              id: batch.id,
              batch_number: batch.batch_number,
              available_qty: available_qty,
              expiry_date: batch.expiry_date&.strftime('%Y-%m-%d'),
              manufacture_date: batch.manufacture_date&.strftime('%Y-%m-%d'),
              is_expired: batch.expiry_date.present? && batch.expiry_date < Date.today,
              display: "#{batch.batch_number} (Available: #{available_qty})"
            }
          end
        end.compact
  
        render json: batch_data
      end
  
      private
  
      def set_stock_batch
        @stock_batch = StockBatch.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to inventory_stock_batches_path, alert: "Batch not found"
      end
  
      def set_products
        # Only batch-tracked products
        @products = Product.where(is_batch_tracked: true, deleted: false)
                          .order(:name)
      end
  
      def stock_batch_params
        params.require(:stock_batch).permit(
          :product_id,
          :batch_number,
          :manufacture_date,
          :expiry_date,
          :supplier_batch_ref,
          :supplier_lot_number,
          :certificate_number,
          :quality_status,
          :notes
        )
      end
    end
  end

  ============================================================================
  # FILE: stock_issues_controller.rb
  # PATH: inventory/stock_issues_controller.rb
  ============================================================================

  # app/controllers/inventory/stock_issues_controller.rb
  
  module Inventory
    class StockIssuesController < BaseController
      before_action :set_stock_issue, only: [:show, :edit, :update, :destroy, :post_issue, :print]
      
      def index
        @stock_issues = StockIssue.non_deleted
                                   .includes(:warehouse, :created_by)
                                   .order(created_at: :desc)
        
        @stock_issues = @stock_issues.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
        @stock_issues = @stock_issues.where(status: params[:status]) if params[:status].present?
        @stock_issues = apply_date_filters(@stock_issues)
        
        if params[:search].present?
          @stock_issues = @stock_issues.where("reference_no ILIKE ?", "%#{params[:search]}%")
        end
        
        @stock_issues = @stock_issues.page(params[:page]).per(per_page)
      end
      
      def show
        @lines = @stock_issue.lines.includes(:product, :from_location, :stock_batch)
      end
      
      def new
        @stock_issue = StockIssue.new(status: StockIssue::STATUS_DRAFT)
        @stock_issue.lines.build
      end
      
      def edit
        unless @stock_issue.can_edit?
          redirect_to inventory_stock_issue_path(@stock_issue), 
                      alert: "Cannot edit Issue in #{@stock_issue.status} status"
          return
        end
        @stock_issue.lines.build if @stock_issue.lines.empty?
      end
      
      def create
        @stock_issue = StockIssue.new(stock_issue_params)
        @stock_issue.created_by = current_user
        
        if @stock_issue.save
          redirect_to inventory_stock_issue_path(@stock_issue), 
                      notice: "Stock Issue #{@stock_issue.reference_no} created successfully."
        else
          render :new, status: :unprocessable_entity
        end
      end
      
      def update
        unless @stock_issue.can_edit?
          redirect_to inventory_stock_issue_path(@stock_issue), 
                      alert: "Cannot edit Issue in #{@stock_issue.status} status"
          return
        end
        
        if @stock_issue.update(stock_issue_params)
          redirect_to inventory_stock_issue_path(@stock_issue), 
                      notice: "Stock Issue updated successfully."
        else
          render :edit, status: :unprocessable_entity
        end
      end
      
      def destroy
        unless @stock_issue.can_edit?
          redirect_to inventory_stock_issues_path, 
                      alert: "Cannot delete Issue in #{@stock_issue.status} status"
          return
        end
        
        @stock_issue.update(deleted: true)
        redirect_to inventory_stock_issues_path, notice: "Stock Issue deleted."
      end
      
      def post_issue
        unless @stock_issue.can_post?
          redirect_to inventory_stock_issues_path, 
                      alert: "Cannot post Issue in #{@stock_issue.status} status"
          return
        end
        StockIssue.transaction do
          @stock_issue.lines.where(deleted: false).each do |line|
            StockTransaction.create!(
              product: line.product,
              uom: line.product.unit_of_measure,
              txn_type: "ISSUE",
              quantity: line.quantity,
              from_location: line.from_location,
              to_location: nil,
              batch: line.stock_batch,
              reference_type: "STOCK_ISSUE",
              reference_id: @stock_issue.id.to_s,
              note: "Issue: #{@stock_issue.reference_no}",
              created_by: current_user
            )
          end
          
          @stock_issue.update!(status: StockIssue::STATUS_POSTED, posted_at: Time.current)
        end
        
        redirect_to inventory_stock_issue_path(@stock_issue), 
                    notice: "Stock Issue posted successfully! Stock levels updated."
      rescue => e
        redirect_to inventory_stock_issue_path(@stock_issue), 
                    alert: "Failed to post: #{e.message}"
      end
      
      def print
        respond_to do |format|
          format.pdf { render pdf: "ISSUE-#{@stock_issue.reference_no}" }
          format.html { render :print, layout: 'print' }
        end
      end
      
      private
      
      def set_stock_issue
        @stock_issue = StockIssue.non_deleted.find(params[:id])
      end
      
      def stock_issue_params
        params.require(:stock_issue).permit(
          :warehouse_id, :status,
          lines_attributes: [
            :id, :product_id, :from_location_id, :stock_batch_id, :quantity, :_destroy
          ]
        )
      end
    end
  end

  ============================================================================
  # FILE: stock_transfers_controller.rb
  # PATH: inventory/stock_transfers_controller.rb
  ============================================================================

  # app/controllers/inventory/stock_transfers_controller.rb
  
  module Inventory
    class StockTransfersController < BaseController
      before_action :set_stock_transfer, only: [:show, :edit, :update, :destroy, :post_transfer, :print]
      
      def index
        @stock_transfers = StockTransfer.non_deleted
                                        .includes(:from_warehouse, :to_warehouse, :created_by)
                                        .order(created_at: :desc)
        
        @stock_transfers = @stock_transfers.where(status: params[:status]) if params[:status].present?
        @stock_transfers = apply_date_filters(@stock_transfers)
        
        if params[:search].present?
          @stock_transfers = @stock_transfers.where("transfer_number ILIKE ?", "%#{params[:search]}%")
        end
        
        @stock_transfers = @stock_transfers.page(params[:page]).per(per_page)
      end
      
      def show
        @lines = @stock_transfer.lines.includes(:product, :from_location, :to_location, :batch, :uom)
      end
      
      def new
        @stock_transfer = StockTransfer.new(status: StockTransfer::STATUS_DRAFT)
        @stock_transfer.lines.build
      end
      
      def edit
        unless @stock_transfer.can_post?
          redirect_to inventory_stock_transfer_path(@stock_transfer), 
                      alert: "Cannot edit Transfer in #{@stock_transfer.status} status"
          return
        end
        @stock_transfer.lines.build if @stock_transfer.lines.empty?
      end
      
      def create
        @stock_transfer = StockTransfer.new(stock_transfer_params)
        @stock_transfer.created_by = current_user
        
        if @stock_transfer.save
          redirect_to inventory_stock_transfer_path(@stock_transfer), 
                      notice: "Stock Transfer #{@stock_transfer.transfer_number} created."
        else
          render :new, status: :unprocessable_entity
        end
      end
      
      def update
        unless @stock_transfer.can_post?
          redirect_to inventory_stock_transfer_path(@stock_transfer), 
                      alert: "Cannot edit Transfer in #{@stock_transfer.status} status"
          return
        end
        
        if @stock_transfer.update(stock_transfer_params)
          redirect_to inventory_stock_transfer_path(@stock_transfer), 
                      notice: "Stock Transfer updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end
      
      def destroy
        unless @stock_transfer.can_post?
          redirect_to inventory_stock_transfers_path, 
                      alert: "Cannot delete Transfer in #{@stock_transfer.status} status"
          return
        end
        
        @stock_transfer.update(deleted: true)
        redirect_to inventory_stock_transfers_path, notice: "Transfer deleted."
      end
      
      def post_transfer
        if @stock_transfer.post!(user: current_user)
          redirect_to inventory_stock_transfer_path(@stock_transfer), 
                      notice: "Transfer posted! Stock moved successfully."
        else
          redirect_to inventory_stock_transfer_path(@stock_transfer), 
                      alert: "Failed to post: #{@stock_transfer.errors.full_messages.join(', ')}"
        end
      end
      
      def print
        respond_to do |format|
          format.pdf { render pdf: "TRANSFER-#{@stock_transfer.transfer_number}" }
          format.html { render :print, layout: 'print' }
        end
      end
      
      private
      
      def set_stock_transfer
        @stock_transfer = StockTransfer.non_deleted.find(params[:id])
      end
      
      def stock_transfer_params
        params.require(:stock_transfer).permit(
          :from_warehouse_id,
          :to_warehouse_id,
          :note,
          :status,
          lines_attributes: [
            :id, :product_id, :from_location_id, :to_location_id, 
            :batch_id, :uom_id, :qty, :line_note, :_destroy
          ]
        )
      end
    end
  end


end


# ============ END OF COMBINED CONTROLLERS FILE ============
