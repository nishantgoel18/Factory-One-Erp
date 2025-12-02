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
