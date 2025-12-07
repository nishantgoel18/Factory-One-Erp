class StockIssuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stock_issue, only: %i[ show edit update destroy ]

  # GET /stock_issues or /stock_issues.json
  def index
    @stock_issues = StockIssue.all
  end

  # GET /stock_issues/1 or /stock_issues/1.json
  def show
  end

  # GET /stock_issues/new
  def new
    @stock_issue = StockIssue.new
  end

  # GET /stock_issues/1/edit
  def edit
  end

  # POST /stock_issues or /stock_issues.json
  def create
    @stock_issue = StockIssue.new(stock_issue_params)

    respond_to do |format|
      if @stock_issue.save
        format.html { redirect_to @stock_issue, notice: "Stock issue was successfully created." }
        format.json { render :show, status: :created, location: @stock_issue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @stock_issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stock_issues/1 or /stock_issues/1.json
  def update
    respond_to do |format|
      if @stock_issue.update(stock_issue_params)
        format.html { redirect_to @stock_issue, notice: "Stock issue was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @stock_issue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stock_issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stock_issues/1 or /stock_issues/1.json
  def destroy
    @stock_issue.destroy!

    respond_to do |format|
      format.html { redirect_to stock_issues_path, notice: "Stock issue was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stock_issue
      @stock_issue = StockIssue.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def stock_issue_params
      params.expect(stock_issue: [ :warehouse_id, :status, :reference_no, :created_by, :deleted ])
    end
end
