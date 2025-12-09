module Customers
  class DocumentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer
    before_action :set_document, only: [:edit, :update, :destroy, :download]
    
    def new
      @document = @customer.documents.build(is_active: true)
      respond_to do |format|
        format.html { render partial: "customers/documents/form", locals: { customer: @customer, document: @document }, layout: false }
      end
    end
    
    # POST /customers/:customer_id/documents
    def create
      @document = @customer.documents.build(document_params)
      @document.created_by = current_user
      
      respond_to do |format|
        if @document.save
          format.html { redirect_to @customer, notice: "Document added successfully." }
        else
          format.html {  }
        end
      end
    end
    
    # GET /customers/:customer_id/documents/:id/edit
    def edit
      respond_to do |format|
        format.html { render partial: "customers/documents/form", locals: { customer: @customer, document: @document }, layout: false }
      end
    end
    
    # PATCH /customers/:customer_id/documents/:id
    def update
      respond_to do |format|
        if @document.update(document_params)
          format.html { redirect_to @customer, notice: "Document updated successfully." }
        else
          format.html {  }
        end
      end
    end
    
    # DELETE /customers/:customer_id/documents/:id
    def destroy
      @document.destroy!
      
      respond_to do |format|
        format.html { redirect_to @customer, notice: "Document deleted successfully." }
      end
    end

    # GET /customers/:customer_id/documents/:id/download
    def download
      if @document.file.attached?
        redirect_to rails_blob_path(@document.file, disposition: "attachment")
      else
        redirect_to customer_path(@customer), alert: "File not found"
      end
    end
    
    private
    
    def set_customer
      @customer = Customer.non_deleted.find(params[:customer_id])
    end
    
    def set_document
      @document = @customer.documents.find(params[:id])
    end
    
    def document_params
      params.require(:customer_document).permit(
        :document_type, :document_category, :document_title, :description,
        :effective_date, :expiry_date, :requires_renewal, :renewal_reminder_days,
        :version, :is_confidential, :customer_can_view, :notes, :file
      )
    end
  end
end