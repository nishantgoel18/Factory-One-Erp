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
