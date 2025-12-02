# app/controllers/inventory/goods_receipts_controller.rb

module Inventory
  class GoodsReceiptsController < BaseController
    before_action :set_goods_receipt, only: [:show, :edit, :update, :destroy, :post_receipt, :print]
    
    # GET /inventory/goods_receipts
    def index
      @goods_receipts = GoodsReceipt.active
                                    .includes(:warehouse, :supplier, :purchase_order, :created_by)
                                    .order(receipt_date: :desc)
      
      # Filters
      @goods_receipts = @goods_receipts.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
      @goods_receipts = @goods_receipts.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?
      @goods_receipts = @goods_receipts.where(status: params[:status]) if params[:status].present?
      @goods_receipts = apply_date_filters(@goods_receipts)
      
      # Search
      if params[:search].present?
        @goods_receipts = @goods_receipts.where(
          "reference_no ILIKE ? OR notes ILIKE ?", 
          "%#{params[:search]}%", 
          "%#{params[:search]}%"
        )
      end
      
      @goods_receipts = @goods_receipts.page(params[:page]).per(per_page)
    end
    
    # GET /inventory/goods_receipts/1
    def show
      @lines = @goods_receipt.lines.includes(:product, :location, :batch, :uom)
    end
    
    # GET /inventory/goods_receipts/new
    def new
      @goods_receipt = GoodsReceipt.new(
        receipt_date: Date.current,
        status: GoodsReceipt::STATUS_DRAFT
      )
      
      # Build initial line
      @goods_receipt.lines.build
    end
    
    # GET /inventory/goods_receipts/from_po?po_id=123
    def from_po
      @purchase_order = PurchaseOrder.find(params[:po_id])
      
      unless @purchase_order.can_receive?
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    alert: "This PO cannot be received. Status: #{@purchase_order.status}"
        return
      end
      
      @goods_receipt = GoodsReceipt.new(
        purchase_order: @purchase_order,
        warehouse: @purchase_order.warehouse,
        supplier: @purchase_order.supplier,
        receipt_date: Date.current,
        status: GoodsReceipt::STATUS_DRAFT
      )
      
      # Auto-populate lines from PO lines with outstanding qty
      @purchase_order.lines.where("received_qty < ordered_qty").each do |po_line|
        @goods_receipt.lines.build(
          product: po_line.product,
          uom: po_line.uom,
          qty: po_line.outstanding_qty,
          location: nil  # User will select
        )
      end
      
      render :new
    end
    
    # GET /inventory/goods_receipts/1/edit
    def edit
      unless @goods_receipt.can_edit?
        redirect_to inventory_goods_receipt_path(@goods_receipt), 
                    alert: "Cannot edit GRN in #{@goods_receipt.status} status"
        return
      end
      
      @goods_receipt.lines.build if @goods_receipt.lines.empty?
    end
    
    # POST /inventory/goods_receipts
    def create
      @goods_receipt = GoodsReceipt.new(goods_receipt_params)
      @goods_receipt.created_by = current_user
      
      if @goods_receipt.save
        redirect_to inventory_goods_receipt_path(@goods_receipt), 
                    notice: "Goods Receipt #{@goods_receipt.reference_no} created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    # PATCH /inventory/goods_receipts/1
    def update
      unless @goods_receipt.can_edit?
        redirect_to inventory_goods_receipt_path(@goods_receipt), 
                    alert: "Cannot edit GRN in #{@goods_receipt.status} status"
        return
      end
      
      if @goods_receipt.update(goods_receipt_params)
        redirect_to inventory_goods_receipt_path(@goods_receipt), 
                    notice: "Goods Receipt updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    # DELETE /inventory/goods_receipts/1
    def destroy
      unless @goods_receipt.can_edit?
        redirect_to inventory_goods_receipts_path, 
                    alert: "Cannot delete GRN in #{@goods_receipt.status} status"
        return
      end
      
      @goods_receipt.update(deleted: true)
      redirect_to inventory_goods_receipts_path, 
                  notice: "Goods Receipt deleted successfully."
    end
    
    # POST /inventory/goods_receipts/1/post_receipt
    def post_receipt
      if @goods_receipt.post!(user: current_user)
        redirect_to inventory_goods_receipt_path(@goods_receipt), 
                    notice: "Goods Receipt posted successfully! Stock levels updated."
      else
        redirect_to inventory_goods_receipt_path(@goods_receipt), 
                    alert: "Failed to post: #{@goods_receipt.errors.full_messages.join(', ')}"
      end
    end
    
    # GET /inventory/goods_receipts/1/print
    def print
      respond_to do |format|
        format.pdf do
          render pdf: "GRN-#{@goods_receipt.reference_no}",
                 template: 'inventory/goods_receipts/print',
                 layout: 'pdf'
        end
        format.html { render :print, layout: 'print' }
      end
    end
    
    private
    
    def set_goods_receipt
      @goods_receipt = GoodsReceipt.find(params[:id])
    end
    
    def goods_receipt_params
      params.require(:goods_receipt).permit(
        :warehouse_id,
        :supplier_id,
        :purchase_order_id,
        :receipt_date,
        :notes,
        lines_attributes: [
          :id,
          :product_id,
          :location_id,
          :batch_id,
          :uom_id,
          :qty,
          :unit_cost,
          :line_note,
          :_destroy
        ]
      )
    end
  end
end
