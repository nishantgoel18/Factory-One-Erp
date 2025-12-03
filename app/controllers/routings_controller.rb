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