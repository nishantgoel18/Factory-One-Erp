module Suppliers
  class QualityIssuesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_supplier
    before_action :set_quality_issue, only: [:edit, :update, :resolve, :close]
    
    def index
      @quality_issues = @supplier.quality_issues.order(issue_date: :desc).page(params[:page])
    end
    
    def new
      @quality_issue = @supplier.quality_issues.build(
        issue_date: Date.current,
        severity: 'MAJOR',
        status: 'OPEN'
      )
    end
    
    def create
      @quality_issue = @supplier.quality_issues.build(quality_issue_params)
      @quality_issue.reported_by = current_user
      @quality_issue.created_by = current_user
      
      respond_to do |format|
        if @quality_issue.save
          format.html { redirect_to @supplier, notice: "Quality issue logged." }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end
    
    def edit
      
    end
    
    def update
      respond_to do |format|
        if @quality_issue.update(quality_issue_params)
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

    def resolve
      @quality_issue.mark_resolved!(params[:resolution_notes], current_user)
      render json: { success: true, message: 'Quality issue marked as resolved' }
    end
    
    def close
      @quality_issue.close!(current_user)
      render json: { success: true, message: 'Quality issue closed' }
    end
    
    private
    
    def set_supplier
      @supplier = Supplier.non_deleted.find(params[:supplier_id])
    end
    
    def set_quality_issue
      @quality_issue = @supplier.quality_issues.find(params[:id])
    end
    
    def quality_issue_params
      params.require(:supplier_quality_issue).permit(
        :product_id, :issue_title, :issue_description, :issue_type,
        :severity, :issue_date, :detected_date, :quantity_affected,
        :quantity_rejected, :quantity_reworked, :quantity_returned,
        :financial_impact, :credit_requested, :credit_amount,
        :status, :root_cause_analysis, :corrective_action_taken,
        :preventive_action_taken, :supplier_response, :is_repeat_issue,
        :related_issue_id, :requires_audit, :quality_team_notes,
        :purchasing_team_notes, :related_po_number, :lot_batch_number, 
        :root_cause_category, :expected_resolution_date, :supplier_notified
      )
    end
  end
end
