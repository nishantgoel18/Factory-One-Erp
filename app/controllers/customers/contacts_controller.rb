module Customers
  class ContactsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer
    before_action :set_contact, only: [:edit, :update, :destroy, :make_primary]
    
    # GET /customers/:customer_id/contacts/new
    def new
      @contact = @customer.contacts.build
      render partial: "customers/contacts/form", locals: { customer: @customer, contact: @contact }
    end
    
    # POST /customers/:customer_id/contacts
    def create
      @contact = @customer.contacts.build(contact_params)
      @contact.created_by = current_user
      
      if @contact.save
        render json: { success: true, message: "Contact added successfully", contact: @contact }
      else
        render json: { success: false, errors: @contact.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # GET /customers/:customer_id/contacts/:id/edit
    def edit
      render partial: "customers/contacts/form", locals: { customer: @customer, contact: @contact }
    end
    
    # PATCH /customers/:customer_id/contacts/:id
    def update
      if @contact.update(contact_params)
        render json: { success: true, message: "Contact updated successfully", contact: @contact }
      else
        render json: { success: false, errors: @contact.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # DELETE /customers/:customer_id/contacts/:id
    def destroy
      @contact.destroy!
      render json: { success: true, message: "Contact deleted successfully" }
    end
    
    # POST /customers/:customer_id/contacts/:id/make_primary
    def make_primary
      @contact.make_primary!
      render json: { success: true, message: "Set as primary contact" }
    end
    
    private
    
    def set_customer
      @customer = Customer.non_deleted.find(params[:customer_id])
    end
    
    def set_contact
      @contact = @customer.contacts.find(params[:id])
    end
    
    def contact_params
      params.require(:customer_contact).permit(
        :first_name, :last_name, :title, :department, :contact_role,
        :is_primary_contact, :is_decision_maker, :is_active,
        :email, :phone, :mobile, :fax, :extension,
        :linkedin_url, :skype_id, :preferred_contact_method,
        :contact_notes, :receive_order_confirmations, :receive_shipping_notifications,
        :receive_invoice_copies, :receive_marketing_emails,
        :birthday, :anniversary, :personal_notes
      )
    end
  end
end