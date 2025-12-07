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