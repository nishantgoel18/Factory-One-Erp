class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: %i[ show edit update destroy ]

  # GET /customers or /customers.json
  def index
    @customers = Customer.non_deleted
  end

  # GET /customers/1 or /customers/1.json
  def show
  end

  # GET /customers/new
  def new
    @customer = Customer.new
  end

  # GET /customers/1/edit
  def edit
  end

  # POST /customers or /customers.json
  def create
    @customer = Customer.new(customer_params)

    respond_to do |format|
      if @customer.save
        format.html { redirect_to @customer, notice: "Customer was successfully created." }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customers/1 or /customers/1.json
  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: "Customer was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customers/1 or /customers/1.json
  def destroy
    @customer.destroy!

    respond_to do |format|
      format.html { redirect_to customers_path, notice: "Customer was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Customer.non_deleted.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def customer_params
      params.require(:customer).permit(
        :code, :full_name, :legal_name, :customer_type, :dba_name,
        :email, :phone, :mobile, :website, :fax,
        :billing_street, :billing_city, :billing_state,
        :billing_postal_code, :billing_country,
        :shipping_street, :shipping_city, :shipping_state,
        :shipping_postal_code, :shipping_country,
        :tax_exempt, :tax_exempt_number, :customer_tax_region,
        :default_tax_code_id, :ein_number, :business_number,
        :credit_limit, :payment_terms, :default_ar_account_id,
        :allow_backorders, :default_price_list_id,
        :default_currency, :default_sales_rep_id,
        :default_warehouse_id,
        :primary_contact_name, :primary_contact_email, :primary_contact_phone,
        :secondary_contact_name, :secondary_contact_email, :secondary_contact_phone,
        :freight_terms, :shipping_method, :delivery_instructions,
        :internal_notes, :is_active
      )
    end
end
