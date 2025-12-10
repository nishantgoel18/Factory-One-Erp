module Suppliers
  class AddressesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_supplier
    before_action :set_address, only: [:edit, :update, :destroy, :make_default]
    
    def new
      @address = @supplier.addresses.build(is_active: true)
      respond_to do |format|
        format.html { render partial: 'suppliers/addresses/form', locals: { supplier: @supplier, address: @address }, layout: false }
      end
    end
    
    def create
      @address = @supplier.addresses.build(address_params)
      @address.created_by = current_user
      
      if @address.save
        render json: { success: true, message: 'Address added successfully' }
      else
        render json: { success: false, errors: @address.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def edit
      respond_to do |format|
        format.html { render partial: 'suppliers/addresses/form', locals: { supplier: @supplier, address: @address }, layout: false }
      end
    end
    
    def update
      if @address.update(address_params)
        render json: { success: true, message: 'Address updated successfully' }
      else
        render json: { success: false, errors: @address.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def destroy
      @address.destroy!
      render json: { success: true, message: 'Address deleted successfully' }
    end
    
    def make_default
      @address.make_default!
      render json: { success: true, message: 'Set as default address' }
    end
    
    private
    
    def set_supplier
      @supplier = Supplier.non_deleted.find(params[:supplier_id])
    end
    
    def set_address
      @address = @supplier.addresses.find(params[:id])
    end
    
    def address_params
      params.require(:supplier_address).permit(
        :address_type, :address_label, :is_default, :is_active,
        :attention_to, :street_address_1, :street_address_2,
        :city, :state_province, :postal_code, :country,
        :contact_phone, :contact_email, :contact_fax,
        :operating_hours, :receiving_hours, :shipping_instructions,
        :special_instructions, :dock_gate_info, :requires_appointment,
        :access_code, :facility_size_sqft, :warehouse_capacity_pallets,
        equipment_available: [], certifications_at_location: []
      )
    end
  end
end