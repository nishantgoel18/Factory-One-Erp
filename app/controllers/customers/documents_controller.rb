module Customers
  class DocumentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer
    before_action :set_document, only: [:edit, :update, :destroy, :download]
    
    # GET /customers/:customer_id/documents
    def index
      @documents = @customer.documents.order(created_at: :desc)
      render partial: "customers/documents/list", locals: { documents: @documents }
    end
    
    # GET /customers/:customer_id/documents/new
    def new
      @document = @customer.documents.build
      render partial: "customers/documents/form", locals: { customer: @customer, document: @document }
    end
    
    # POST /customers/:customer_id/documents
    def create
      @document = @customer.documents.build(document_params)
      @document.uploaded_by = current_user
      
      if @document.save
        render json: { success: true, message: "Document uploaded successfully", document: @document }
      else
        render json: { success: false, errors: @document.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # GET /customers/:customer_id/documents/:id/edit
    def edit
      render partial: "customers/documents/form", locals: { customer: @customer, document: @document }
    end
    
    # PATCH /customers/:customer_id/documents/:id
    def update
      if @document.update(document_params)
        render json: { success: true, message: "Document updated successfully" }
      else
        render json: { success: false, errors: @document.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # DELETE /customers/:customer_id/documents/:id
    def destroy
      @document.destroy!
      render json: { success: true, message: "Document deleted successfully" }
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