module Customers
  class AddressesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer
    before_action :set_address, only: [:edit, :update, :destroy, :make_default]
    
    # GET /customers/:customer_id/addresses/new
    def new
      @address = @customer.addresses.build(is_active: true)
      
      respond_to do |format|
        format.html { render partial: "customers/addresses/form", locals: { customer: @customer, address: @address }, layout: false }
      end
    end
    
    # POST /customers/:customer_id/addresses
    def create
      @address = @customer.addresses.build(address_params)
      @address.created_by = current_user
      
      respond_to do |format|
        if @address.save
          format.html { redirect_to @customer, notice: "Address added successfully." }
        else
          format.html {  }
        end
      end
    end
    
    # GET /customers/:customer_id/addresses/:id/edit
    def edit
      respond_to do |format|
        format.html { render partial: "customers/addresses/form", locals: { customer: @customer, address: @address }, layout: false }
      end
    end
    
    # PATCH /customers/:customer_id/addresses/:id
    def update
      respond_to do |format|
        if @address.update(address_params)
          format.html { redirect_to @customer, notice: "Address updated successfully." }
        else
          format.html {  }
        end
      end
    end
    
    # DELETE /customers/:customer_id/addresses/:id
    def destroy
      @address.destroy!
      
      respond_to do |format|
        format.html { redirect_to @customer, notice: "Address deleted successfully." }
      end
    end
    
    # POST /customers/:customer_id/addresses/:id/make_default
    def make_default
      @address.make_default!
      
      respond_to do |format|
        format.html { redirect_to @customer, notice: "Set as default address." }
      end
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