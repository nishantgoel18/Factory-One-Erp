# app/controllers/inventory/stock_issues_controller.rb

module Inventory
  class StockIssuesController < BaseController
    before_action :set_stock_issue, only: [:show, :edit, :update, :destroy, :post_issue, :print]
    
    def index
      @stock_issues = StockIssue.non_deleted
                                 .includes(:warehouse, :created_by)
                                 .order(created_at: :desc)
      
      @stock_issues = @stock_issues.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
      @stock_issues = @stock_issues.where(status: params[:status]) if params[:status].present?
      @stock_issues = apply_date_filters(@stock_issues)
      
      if params[:search].present?
        @stock_issues = @stock_issues.where("reference_no ILIKE ?", "%#{params[:search]}%")
      end
      
      @stock_issues = @stock_issues.page(params[:page]).per(per_page)
    end
    
    def show
      @lines = @stock_issue.lines.includes(:product, :from_location, :stock_batch)
    end
    
    def new
      @stock_issue = StockIssue.new(status: StockIssue::STATUS_DRAFT)
      @stock_issue.lines.build
    end
    
    def edit
      unless @stock_issue.can_edit?
        redirect_to inventory_stock_issue_path(@stock_issue), 
                    alert: "Cannot edit Issue in #{@stock_issue.status} status"
        return
      end
      @stock_issue.lines.build if @stock_issue.lines.empty?
    end
    
    def create
      @stock_issue = StockIssue.new(stock_issue_params)
      @stock_issue.created_by = current_user
      
      if @stock_issue.save
        redirect_to inventory_stock_issue_path(@stock_issue), 
                    notice: "Stock Issue #{@stock_issue.reference_no} created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def update
      unless @stock_issue.can_edit?
        redirect_to inventory_stock_issue_path(@stock_issue), 
                    alert: "Cannot edit Issue in #{@stock_issue.status} status"
        return
      end
      
      if @stock_issue.update(stock_issue_params)
        redirect_to inventory_stock_issue_path(@stock_issue), 
                    notice: "Stock Issue updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      unless @stock_issue.can_edit?
        redirect_to inventory_stock_issues_path, 
                    alert: "Cannot delete Issue in #{@stock_issue.status} status"
        return
      end
      
      @stock_issue.update(deleted: true)
      redirect_to inventory_stock_issues_path, notice: "Stock Issue deleted."
    end
    
    def post_issue
      unless @stock_issue.can_post?
        redirect_to inventory_stock_issues_path, 
                    alert: "Cannot post Issue in #{@stock_issue.status} status"
        return
      end
      StockIssue.transaction do
        @stock_issue.lines.where(deleted: false).each do |line|
          StockTransaction.create!(
            product: line.product,
            uom: line.product.unit_of_measure,
            txn_type: "ISSUE",
            quantity: line.quantity,
            from_location: line.from_location,
            to_location: nil,
            batch: line.stock_batch,
            reference_type: "STOCK_ISSUE",
            reference_id: @stock_issue.id.to_s,
            note: "Issue: #{@stock_issue.reference_no}",
            created_by: current_user
          )
        end
        
        @stock_issue.update!(status: StockIssue::STATUS_POSTED, posted_at: Time.current)
      end
      
      redirect_to inventory_stock_issue_path(@stock_issue), 
                  notice: "Stock Issue posted successfully! Stock levels updated."
    rescue => e
      redirect_to inventory_stock_issue_path(@stock_issue), 
                  alert: "Failed to post: #{e.message}"
    end
    
    def print
      respond_to do |format|
        format.pdf { render pdf: "ISSUE-#{@stock_issue.reference_no}" }
        format.html { render :print, layout: 'print' }
      end
    end
    
    private
    
    def set_stock_issue
      @stock_issue = StockIssue.non_deleted.find(params[:id])
    end
    
    def stock_issue_params
      params.require(:stock_issue).permit(
        :warehouse_id, :status,
        lines_attributes: [
          :id, :product_id, :from_location_id, :stock_batch_id, :quantity, :_destroy
        ]
      )
    end
  end
end