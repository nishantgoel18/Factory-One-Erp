class TaxCodesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tax_code, only: %i[ show edit update destroy ]

  # GET /tax_codes or /tax_codes.json
  def index
    @tax_codes = TaxCode.non_deleted
  end

  # GET /tax_codes/1 or /tax_codes/1.json
  def show
  end

  # GET /tax_codes/new
  def new
    @tax_code = TaxCode.new
  end

  # GET /tax_codes/1/edit
  def edit
  end

  # POST /tax_codes or /tax_codes.json
  def create
    @tax_code = TaxCode.new(tax_code_params)

    respond_to do |format|
      if @tax_code.save
        format.html { redirect_to @tax_code, notice: "Tax code was successfully created." }
        format.json { render :show, status: :created, location: @tax_code }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tax_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tax_codes/1 or /tax_codes/1.json
  def update
    respond_to do |format|
      if @tax_code.update(tax_code_params)
        format.html { redirect_to @tax_code, notice: "Tax code was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tax_code }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tax_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tax_codes/1 or /tax_codes/1.json
  def destroy
    @tax_code.destroy!

    respond_to do |format|
      format.html { redirect_to tax_codes_path, notice: "Tax code was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tax_code
      @tax_code = TaxCode.non_deleted.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def tax_code_params
      params.expect(tax_code: [ :code, :name, :jurisdiction, :tax_type, :country, :state_province, :county, :city, :rate, :is_compound, :compounds_on, :effective_from, :effective_to, :tax_authority_id, :filing_frequency, :is_active, :deleted ])
    end
end
