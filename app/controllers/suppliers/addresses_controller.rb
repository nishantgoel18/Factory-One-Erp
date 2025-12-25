module Suppliers
  class AddressesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_supplier
    before_action :set_address, only: [:edit, :update, :destroy, :make_default]
    
    def new
      @address = @supplier.addresses.build(is_active: true)
    end
    
    def create
      @address = @supplier.addresses.build(address_params)
      @address.created_by = current_user
      
      respond_to do |format|
        if @address.save
          format.html { redirect_to @supplier, notice: "Address was successfully created." }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end
    
    def edit
      
    end
    
    def update
      respond_to do |format|
        if @address.update(address_params)
          format.html { redirect_to @supplier, notice: "Address was successfully updated." }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end
    
    def destroy
      @address.destroy!
      render json: { success: true, message: 'Address deleted successfully' }
    end

    def make_default
      @address.make_default!
      render json: { success: true, message: 'Address marked as default successfully' }
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