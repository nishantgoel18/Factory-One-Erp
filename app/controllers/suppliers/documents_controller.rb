module Suppliers
  class DocumentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_supplier
    before_action :set_document, only: [:show, :edit, :update, :destroy, :download, :preview]
    
    # GET /suppliers/:supplier_id/documents
    def index
      @documents = @supplier.documents
                           .order(created_at: :desc)
      
      # Filter by document type
      if params[:document_type].present?
        @documents = @documents.where(document_type: params[:document_type])
      end
      
      # Filter by active/expired
      if params[:status] == 'expired'
        @documents = @documents.where('expiry_date < ?', Date.current)
      elsif params[:status] == 'expiring_soon'
        @documents = @documents.where('expiry_date <= ?', 30.days.from_now)
                              .where('expiry_date >= ?', Date.current)
      elsif params[:status] == 'active'
        @documents = @documents.where(is_active: true)
      end
      
      respond_to do |format|
        format.html
        format.json { render json: @documents }
      end
    end

    # GET /suppliers/:supplier_id/documents/new
    def new
      @supplier_document = @supplier.documents.build(
        effective_date: Date.current,
        is_active: true,
        renewal_reminder_days: 30
      )
    end
    
    # POST /suppliers/:supplier_id/documents
    def create
      @supplier_document = @supplier.documents.build(document_params)
      @supplier_document.created_by = current_user
      
      respond_to do |format|
        if @supplier_document.save
          format.html { redirect_to @supplier, notice: "Document was successfully created." }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end
    
    # GET /suppliers/:supplier_id/documents/:id
    def show
      respond_to do |format|
        format.html { render partial: 'suppliers/documents/show', 
                             locals: { supplier: @supplier, document: @supplier_document }, 
                             layout: false }
        format.json { render json: @supplier_document }
      end
    end
    
    # GET /suppliers/:supplier_id/documents/:id/edit
    def edit
    end
    
    # PATCH/PUT /suppliers/:supplier_id/documents/:id
    def update
      @supplier_document.uploaded_by = current_user
      if @supplier_document.update(document_params)
        redirect_to @supplier, notice: "Document was successfully updated." 
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    # DELETE /suppliers/:supplier_id/documents/:id
    def destroy
      @supplier_document.destroy!
      
      render json: { 
        success: true, 
        message: 'Document deleted successfully' 
      }
    end
    
    # GET /suppliers/:supplier_id/documents/:id/download
    def download
      if @supplier_document.document.attached?
        redirect_to rails_blob_path(@supplier_document.document, disposition: "attachment")
      else
        render json: { 
          success: false, 
          message: 'Document file not found' 
        }, status: :not_found
      end
    end
    
    # GET /suppliers/:supplier_id/documents/:id/preview
    def preview
      if @supplier_document.document.attached?
        redirect_to rails_blob_path(@supplier_document.document, disposition: "inline")
      else
        render json: { 
          success: false, 
          message: 'Document file not found' 
        }, status: :not_found
      end
    end
    
    private
    
    def set_supplier
      @supplier = Supplier.non_deleted.find(params[:supplier_id])
    end
    
    def set_document
      @supplier_document = @supplier.documents.find(params[:id])
    end
    
    def document_params
      params.require(:supplier_document).permit(
        :document,
        :document_title,
        :document_type,
        :document_category,
        :document_number,
        :version,
        :effective_date,
        :expiry_date,
        :renewal_date,
        :renewal_reminder_days,
        :is_active,
        :requires_renewal,
        :is_confidential,
        :issuing_authority,
        :description,
        :notes,
        :file,
        :document_number,
        :renewal_date,
        :issuing_authority,
      )
    end
  end
end