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