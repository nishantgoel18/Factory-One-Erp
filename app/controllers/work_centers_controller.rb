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