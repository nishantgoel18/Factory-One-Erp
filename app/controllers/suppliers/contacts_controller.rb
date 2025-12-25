module Suppliers
  class ContactsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_supplier
    before_action :set_contact, only: [:edit, :update, :destroy, :make_primary]
    
    def new
      @contact = @supplier.contacts.build(is_active: true)
    end
    
    def create
      @contact = @supplier.contacts.build(contact_params)
      @contact.created_by = current_user
      
      respond_to do |format|
        if @contact.save
          format.html { redirect_to @supplier, notice: "Contact was successfully created." }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end
    
    def edit
      
    end
    
    def update
      respond_to do |format|
        if @contact.update(contact_params)
          format.html { redirect_to @supplier, notice: "Contact was successfully updated." }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end
    
    def destroy
      @contact.destroy!
      render json: { success: true, message: 'Contact deleted successfully' }
    end
    
    def make_primary
      @contact.make_primary!
      redirect_to @supplier, notice: 'Set as primary contact'
    end
    
    private
    
    def set_supplier
      @supplier = Supplier.non_deleted.find(params[:supplier_id])
    end
    
    def set_contact
      @contact = @supplier.contacts.find(params[:id])
    end
    
    def contact_params
      params.require(:supplier_contact).permit(
        :first_name, :last_name, :title, :department, :contact_role,
        :is_primary_contact, :is_decision_maker, :is_escalation_contact,
        :is_after_hours_contact, :is_active, :email, :phone, :mobile,
        :fax, :extension, :direct_line, :skype_id, :linkedin_url,
        :wechat_id, :whatsapp_number, :preferred_contact_method,
        :receive_pos, :receive_rfqs, :receive_quality_alerts,
        :receive_payment_confirmations, :receive_general_updates,
        :communication_notes, :working_hours, :timezone,
        :birthday, :anniversary, :personal_notes, :professional_notes,
        languages_spoken: []
      )
    end
  end
end