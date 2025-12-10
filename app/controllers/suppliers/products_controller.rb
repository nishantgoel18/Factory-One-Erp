module Suppliers
  class ProductsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_supplier
    before_action :set_product_supplier, only: [:edit, :update, :destroy, :update_price]
    
    def index
      @product_suppliers = @supplier.product_catalog.includes(:product)
      respond_to do |format|
        format.html
        format.json { render json: @product_suppliers }
      end
    end
    
    def new
      @product_supplier = @supplier.product_suppliers.build
      @available_products = Product.where.not(id: @supplier.products.pluck(:id))
      respond_to do |format|
        format.html { render partial: 'suppliers/products/form', locals: { supplier: @supplier, product_supplier: @product_supplier, available_products: @available_products }, layout: false }
      end
    end
    
    def create
      @product_supplier = @supplier.product_suppliers.build(product_supplier_params)
      @product_supplier.created_by = current_user
      @product_supplier.first_purchase_date = Date.current
      
      if @product_supplier.save
        render json: { success: true, message: 'Product added to catalog' }
      else
        render json: { success: false, errors: @product_supplier.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def edit
      respond_to do |format|
        format.html { render partial: 'suppliers/products/form', locals: { supplier: @supplier, product_supplier: @product_supplier }, layout: false }
      end
    end
    
    def update
      if @product_supplier.update(product_supplier_params)
        render json: { success: true, message: 'Product catalog updated' }
      else
        render json: { success: false, errors: @product_supplier.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def destroy
      @product_supplier.destroy!
      render json: { success: true, message: 'Product removed from catalog' }
    end
    
    def update_price
      new_price = params[:new_price].to_f
      effective_date = params[:effective_date]&.to_date || Date.current
      
      @product_supplier.update_price!(new_price, effective_date)
      render json: { success: true, message: 'Price updated successfully' }
    end
    
    private
    
    def set_supplier
      @supplier = Supplier.non_deleted.find(params[:supplier_id])
    end
    
    def set_product_supplier
      @product_supplier = @supplier.product_suppliers.find(params[:id])
    end
    
    def product_supplier_params
      params.require(:product_supplier).permit(
        :product_id, :supplier_item_code, :supplier_item_description,
        :manufacturer_part_number, :current_unit_price, :price_uom,
        :price_effective_date, :price_expiry_date, :lead_time_days,
        :minimum_order_quantity, :maximum_order_quantity, :order_multiple,
        :packaging_type, :units_per_package, :available_for_order,
        :quality_rating, :is_preferred_supplier, :supplier_rank,
        :is_approved_supplier, :is_sole_source, :is_strategic_item,
        :sourcing_strategy, :requires_quality_cert, :requires_coc,
        :requires_msds, :buyer_notes, :quality_notes, :engineering_notes,
        :contract_reference, :contract_expiry_date, :is_active,
        :price_break_1_qty, :price_break_1_price,
        :price_break_2_qty, :price_break_2_price,
        :price_break_3_qty, :price_break_3_price
      )
    end
  end
end