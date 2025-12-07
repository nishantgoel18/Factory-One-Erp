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
