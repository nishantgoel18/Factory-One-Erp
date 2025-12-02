# app/controllers/inventory/stock_batches_controller.rb

module Inventory
  class StockBatchesController < ApplicationController
    before_action :set_stock_batch, only: [:show, :edit, :update, :destroy]
    before_action :set_products, only: [:new, :edit, :create, :update]

    # GET /inventory/stock_batches
    def index
      @stock_batches = StockBatch.includes(:product, :created_by)
                                  .where(deleted: false)
                                  .order(created_at: :desc)
                                  .page(params[:page])
                                  .per(25)

      # Filters
      if params[:product_id].present?
        @stock_batches = @stock_batches.where(product_id: params[:product_id])
      end

      if params[:batch_number].present?
        @stock_batches = @stock_batches.where("batch_number ILIKE ?", "%#{params[:batch_number]}%")
      end

      if params[:status].present?
        case params[:status]
        when 'active'
          @stock_batches = @stock_batches.where('expiry_date IS NULL OR expiry_date >= ?', Date.today)
        when 'expired'
          @stock_batches = @stock_batches.where('expiry_date < ?', Date.today)
        when 'expiring_soon'
          @stock_batches = @stock_batches.where('expiry_date BETWEEN ? AND ?', Date.today, Date.today + 30.days)
        end
      end

      # Calculate current stock for each batch
      @stock_batches.each do |batch|
        batch.current_stock = StockTransaction
          .where(product_id: batch.product_id, batch_id: batch.id)
          .sum(:quantity)
      end
    end

    # GET /inventory/stock_batches/:id
    def show
      # Current stock across all locations
      @current_stock = StockTransaction
        .where(product_id: @stock_batch.product_id, batch_id: @stock_batch.id)
        .sum(:quantity)

      # Stock by location
      @stock_by_location = StockTransaction
        .joins(:to_location)
        .where(product_id: @stock_batch.product_id, batch_id: @stock_batch.id)
        .group('locations.name')
        .select('locations.name as location_name, SUM(quantity) as total_qty')
        .having('SUM(quantity) > 0')

      # Recent transactions for this batch
      @recent_transactions = StockTransaction
        .where(product_id: @stock_batch.product_id, batch_id: @stock_batch.id)
        .order(created_at: :desc)
        .limit(20)
        .includes(:to_location, :created_by)

      # Check if batch is expired or expiring soon
      if @stock_batch.expiry_date.present?
        days_to_expire = (@stock_batch.expiry_date - Date.today).to_i
        
        if days_to_expire < 0
          @expiry_status = 'expired'
          @expiry_message = "Expired #{days_to_expire.abs} days ago"
        elsif days_to_expire <= 30
          @expiry_status = 'expiring_soon'
          @expiry_message = "Expires in #{days_to_expire} days"
        else
          @expiry_status = 'active'
          @expiry_message = "Expires on #{@stock_batch.expiry_date.strftime('%b %d, %Y')}"
        end
      end
    end

    # GET /inventory/stock_batches/new
    def new
      @stock_batch = StockBatch.new
      
      # Pre-fill product if coming from product page
      if params[:product_id].present?
        @stock_batch.product_id = params[:product_id]
      end
    end

    # GET /inventory/stock_batches/:id/edit
    def edit
    end

    # POST /inventory/stock_batches
    def create
      @stock_batch = StockBatch.new(stock_batch_params)
      @stock_batch.created_by = current_user

      if @stock_batch.save
        redirect_to inventory_stock_batch_path(@stock_batch), 
                    notice: "Batch #{@stock_batch.batch_number} created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /inventory/stock_batches/:id
    def update
      if @stock_batch.update(stock_batch_params)
        redirect_to inventory_stock_batch_path(@stock_batch), 
                    notice: "Batch #{@stock_batch.batch_number} updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /inventory/stock_batches/:id (Soft delete)
    def destroy
      # Check if batch has any stock
      current_stock = StockTransaction
        .where(product_id: @stock_batch.product_id, batch_id: @stock_batch.id)
        .sum(:quantity)

      if current_stock > 0
        redirect_to inventory_stock_batch_path(@stock_batch), 
                    alert: "Cannot delete batch with existing stock (Current: #{current_stock})"
        return
      end

      @stock_batch.update(deleted: true)
      redirect_to inventory_stock_batches_path, 
                  notice: "Batch #{@stock_batch.batch_number} deleted successfully."
    end

    # GET /inventory/stock_batches/search (AJAX endpoint)
    def search
      product_id = params[:product_id]
      warehouse_id = params[:warehouse_id]

      if product_id.blank?
        render json: []
        return
      end

      # Get batches with available stock
      batches = StockBatch
        .where(product_id: product_id, deleted: false)
        .order(batch_number: :asc)

      batch_data = batches.map do |batch|
        # Calculate available stock
        query = StockTransaction.where(product_id: batch.product_id, batch_id: batch.id)
        
        if warehouse_id.present?
          query = query.joins(:to_location).where(locations: { warehouse_id: warehouse_id })
        end
        
        available_qty = query.sum(:quantity)

        # Only include batches with stock
        if available_qty > 0
          {
            id: batch.id,
            batch_number: batch.batch_number,
            available_qty: available_qty,
            expiry_date: batch.expiry_date&.strftime('%Y-%m-%d'),
            manufacture_date: batch.manufacture_date&.strftime('%Y-%m-%d'),
            is_expired: batch.expiry_date.present? && batch.expiry_date < Date.today,
            display: "#{batch.batch_number} (Available: #{available_qty})"
          }
        end
      end.compact

      render json: batch_data
    end

    private

    def set_stock_batch
      @stock_batch = StockBatch.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to inventory_stock_batches_path, alert: "Batch not found"
    end

    def set_products
      # Only batch-tracked products
      @products = Product.where(is_batch_tracked: true, deleted: false)
                        .order(:name)
    end

    def stock_batch_params
      params.require(:stock_batch).permit(
        :product_id,
        :batch_number,
        :manufacture_date,
        :expiry_date,
        :supplier_batch_ref,
        :supplier_lot_number,
        :certificate_number,
        :quality_status,
        :notes
      )
    end
  end
end