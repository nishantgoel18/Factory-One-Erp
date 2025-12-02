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