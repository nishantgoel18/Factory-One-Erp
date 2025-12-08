module Customers
  class AddressesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer
    before_action :set_address, only: [:edit, :update, :destroy, :make_default]
    
    # GET /customers/:customer_id/addresses/new
    def new
      @address = @customer.addresses.build
      render partial: "customers/addresses/form", locals: { customer: @customer, address: @address }
    end
    
    # POST /customers/:customer_id/addresses
    def create
      @address = @customer.addresses.build(address_params)
      @address.created_by = current_user
      
      if @address.save
        render json: { success: true, message: "Address added successfully", address: @address }
      else
        render json: { success: false, errors: @address.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # GET /customers/:customer_id/addresses/:id/edit
    def edit
      render partial: "customers/addresses/form", locals: { customer: @customer, address: @address }
    end
    
    # PATCH /customers/:customer_id/addresses/:id
    def update
      if @address.update(address_params)
        render json: { success: true, message: "Address updated successfully", address: @address }
      else
        render json: { success: false, errors: @address.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # DELETE /customers/:customer_id/addresses/:id
    def destroy
      @address.destroy!
      render json: { success: true, message: "Address deleted successfully" }
    end
    
    # POST /customers/:customer_id/addresses/:id/make_default
    def make_default
      @address.make_default!
      render json: { success: true, message: "Set as default address" }
    end
    
    private
    
    def set_customer
      @customer = Customer.non_deleted.find(params[:customer_id])
    end
    
    def set_address
      @address = @customer.addresses.find(params[:id])
    end
    
    def address_params
      params.require(:customer_address).permit(
        :address_type, :address_label, :is_default, :is_active,
        :attention_to, :contact_phone, :contact_email,
        :street_address_1, :street_address_2, :city, :state_province,
        :postal_code, :country, :delivery_instructions, :dock_gate_info,
        :delivery_hours, :residential_address, :requires_appointment, :access_code
      )
    end
  end
end
