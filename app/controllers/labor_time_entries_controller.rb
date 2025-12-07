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
