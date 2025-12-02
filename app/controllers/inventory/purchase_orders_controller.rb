# app/controllers/inventory/purchase_orders_controller.rb

module Inventory
  class PurchaseOrdersController < BaseController
    before_action :set_purchase_order, only: [:show, :edit, :update, :destroy, :confirm, :cancel, :close, :print]
    
    # GET /inventory/purchase_orders
    def index
      @purchase_orders = PurchaseOrder.active
                                      .includes(:supplier, :warehouse, :created_by)
                                      .order(order_date: :desc)
      
      # Filters
      @purchase_orders = @purchase_orders.by_supplier(params[:supplier_id]) if params[:supplier_id].present?
      @purchase_orders = @purchase_orders.by_status(params[:status]) if params[:status].present?
      @purchase_orders = apply_date_filters(@purchase_orders)
      
      # Search
      if params[:search].present?
        @purchase_orders = @purchase_orders.where(
          "po_number ILIKE ? OR notes ILIKE ?", 
          "%#{params[:search]}%", 
          "%#{params[:search]}%"
        )
      end
      
      @purchase_orders = @purchase_orders.page(params[:page]).per(per_page)
    end
    
    # GET /inventory/purchase_orders/open_pos
    def open_pos
      @purchase_orders = PurchaseOrder.open_pos
                                      .includes(:supplier, :lines)
                                      .order(expected_date: :asc)
                                      .page(params[:page]).per(per_page)
      
      render :index
    end
    
    # GET /inventory/purchase_orders/overdue
    def overdue
      @purchase_orders = PurchaseOrder.active
                                      .where('expected_date < ?', Date.current)
                                      .where(status: [PurchaseOrder::STATUS_CONFIRMED, 
                                                     PurchaseOrder::STATUS_PARTIALLY_RECEIVED])
                                      .includes(:supplier)
                                      .order(expected_date: :asc)
                                      .page(params[:page]).per(per_page)
      
      render :index
    end
    
    # GET /inventory/purchase_orders/1
    def show
      @lines = @purchase_order.lines.includes(:product, :uom)
    end
    
    # GET /inventory/purchase_orders/new
    def new
      @purchase_order = PurchaseOrder.new(
        order_date: Date.current,
        currency: 'USD',
        status: PurchaseOrder::STATUS_DRAFT
      )
      
      # Build initial line
      @purchase_order.lines.build
    end
    
    # GET /inventory/purchase_orders/1/edit
    def edit
      unless @purchase_order.can_edit?
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    alert: "Cannot edit PO in #{@purchase_order.status} status"
        return
      end
      
      # Build one empty line for adding more items
      @purchase_order.lines.build if @purchase_order.lines.empty?
    end
    
    # POST /inventory/purchase_orders
    def create
      @purchase_order = PurchaseOrder.new(purchase_order_params)
      @purchase_order.created_by = current_user
      
      if @purchase_order.save
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    notice: "Purchase Order #{@purchase_order.po_number} created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    # PATCH /inventory/purchase_orders/1
    def update
      unless @purchase_order.can_edit?
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    alert: "Cannot edit PO in #{@purchase_order.status} status"
        return
      end
      
      if @purchase_order.update(purchase_order_params)
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    notice: "Purchase Order updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    # DELETE /inventory/purchase_orders/1
    def destroy
      unless @purchase_order.can_delete?
        redirect_to inventory_purchase_orders_path, 
                    alert: "Cannot delete PO in #{@purchase_order.status} status. Use Cancel instead."
        return
      end
      
      @purchase_order.update(deleted: true)
      redirect_to inventory_purchase_orders_path, 
                  notice: "Purchase Order deleted successfully."
    end
    
    # POST /inventory/purchase_orders/1/confirm
    def confirm
      if @purchase_order.confirm!(user: current_user)
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    notice: "Purchase Order confirmed successfully. PO is now official!"
      else
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    alert: "Failed to confirm: #{@purchase_order.errors.full_messages.join(', ')}"
      end
    end
    
    # POST /inventory/purchase_orders/1/cancel
    def cancel
      if @purchase_order.cancel!(user: current_user)
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    notice: "Purchase Order cancelled."
      else
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    alert: "Failed to cancel: #{@purchase_order.errors.full_messages.join(', ')}"
      end
    end
    
    # POST /inventory/purchase_orders/1/close
    def close
      if @purchase_order.close!(user: current_user)
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    notice: "Purchase Order closed successfully."
      else
        redirect_to inventory_purchase_order_path(@purchase_order), 
                    alert: "Failed to close: #{@purchase_order.errors.full_messages.join(', ')}"
      end
    end
    
    # GET /inventory/purchase_orders/1/print
    def print
      respond_to do |format|
        format.pdf do
          render pdf: "PO-#{@purchase_order.po_number}",
                 template: 'inventory/purchase_orders/print',
                 layout: 'pdf'
        end
        format.html { render :print, layout: 'print' }
      end
    end
    
    private
    
    def set_purchase_order
      @purchase_order = PurchaseOrder.find(params[:id])
    end
    
    def purchase_order_params
      params.require(:purchase_order).permit(
        :supplier_id,
        :warehouse_id,
        :order_date,
        :expected_date,
        :currency,
        :payment_terms,
        :shipping_method,
        :shipping_address,
        :shipping_cost,
        :notes,
        :internal_notes,
        lines_attributes: [
          :id,
          :product_id,
          :uom_id,
          :ordered_qty,
          :unit_price,
          :tax_code_id,
          :expected_delivery_date,
          :line_note,
          :_destroy
        ]
      )
    end
  end
end
