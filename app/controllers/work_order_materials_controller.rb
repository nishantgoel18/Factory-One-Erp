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
