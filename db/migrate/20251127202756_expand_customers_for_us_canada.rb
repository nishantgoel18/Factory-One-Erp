class ExpandCustomersForUsCanada < ActiveRecord::Migration[8.1]
  def change
    change_column :customers, :code, :string, limit: 20
    change_column :customers, :full_name, :string, limit: 255

    # Core business info
    add_column :customers, :legal_name, :string
    add_column :customers, :customer_type, :string, limit: 20      # INDIVIDUAL / BUSINESS / GOV / NON_PROFIT
    add_column :customers, :dba_name, :string                      # Doing Business As

    # Structured billing address
    add_column :customers, :billing_street, :string
    add_column :customers, :billing_city, :string
    add_column :customers, :billing_state, :string
    add_column :customers, :billing_postal_code, :string
    add_column :customers, :billing_country, :string, default: "US"

    # Structured shipping address
    add_column :customers, :shipping_street, :string
    add_column :customers, :shipping_city, :string
    add_column :customers, :shipping_state, :string
    add_column :customers, :shipping_postal_code, :string
    add_column :customers, :shipping_country, :string, default: "US"

    # Contact details
    add_column :customers, :mobile, :string, limit: 20
    add_column :customers, :website, :string
    add_column :customers, :fax, :string, limit: 20

    # Tax & compliance
    add_column :customers, :tax_exempt, :boolean, default: false
    add_column :customers, :tax_exempt_number, :string
    add_column :customers, :customer_tax_region, :string
    add_column :customers, :default_tax_code_id, :integer
    add_column :customers, :ein_number, :string        # US
    add_column :customers, :business_number, :string   # Canada

    # Finance & credit
    add_column :customers, :credit_limit, :decimal, precision: 15, scale: 2, default: 0
    add_column :customers, :current_balance, :decimal, precision: 15, scale: 2, default: 0
    add_column :customers, :payment_terms, :string, limit: 20
    add_column :customers, :default_ar_account_id, :integer
    add_column :customers, :allow_backorders, :boolean, default: true

    # Sales / defaults
    add_column :customers, :default_price_list_id, :integer
    add_column :customers, :default_currency, :string, limit: 3, default: "USD"
    add_column :customers, :default_sales_rep_id, :integer
    add_column :customers, :default_warehouse_id, :integer

    # Contacts
    add_column :customers, :primary_contact_name, :string
    add_column :customers, :primary_contact_email, :string
    add_column :customers, :primary_contact_phone, :string, limit: 20
    add_column :customers, :secondary_contact_name, :string
    add_column :customers, :secondary_contact_email, :string
    add_column :customers, :secondary_contact_phone, :string, limit: 20

    # Logistics
    add_column :customers, :freight_terms, :string, limit: 20
    add_column :customers, :shipping_method, :string
    add_column :customers, :delivery_instructions, :text

    # Notes
    add_column :customers, :internal_notes, :text

    add_index :customers, :default_tax_code_id
    add_index :customers, :default_ar_account_id
  end
end
