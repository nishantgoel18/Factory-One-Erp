class EnhanceCustomerModel < ActiveRecord::Migration[8.1]
  def change
    # ========================================
    # CUSTOMER CLASSIFICATION & STATUS
    # ========================================
    add_column :customers, :customer_since, :date
    add_column :customers, :customer_category, :string, limit: 20  # A/B/C classification
    add_column :customers, :industry_type, :string, limit: 50
    add_column :customers, :annual_revenue_potential, :decimal, precision: 15, scale: 2
    add_column :customers, :company_logo_url, :string
    
    # ========================================
    # EXTENDED CONTACT INFORMATION
    # ========================================
    # Already have: email, phone_number, mobile, website, fax
    add_column :customers, :linkedin_url, :string
    add_column :customers, :facebook_url, :string
    add_column :customers, :twitter_url, :string
    
    # ========================================
    # FINANCIAL ENHANCEMENTS
    # ========================================
    # Already have: credit_limit, current_balance, payment_terms
    add_column :customers, :available_credit, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :customers, :credit_hold, :boolean, default: false
    add_column :customers, :credit_hold_reason, :text
    add_column :customers, :credit_hold_date, :date
    add_column :customers, :discount_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :customers, :early_payment_discount, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :customers, :late_fee_applicable, :boolean, default: true
    add_column :customers, :bank_name, :string
    add_column :customers, :bank_account_number, :string
    add_column :customers, :bank_routing_number, :string
    
    # ========================================
    # SALES & TERRITORY
    # ========================================
    # Already have: default_sales_rep_id
    add_column :customers, :sales_territory, :string, limit: 50
    add_column :customers, :customer_acquisition_source, :string, limit: 50  # Referral, Marketing, Cold Call, etc.
    add_column :customers, :expected_order_frequency, :string, limit: 30  # Weekly, Monthly, Quarterly
    
    # ========================================
    # PREFERENCES & SETTINGS
    # ========================================
    # Already have: shipping_method, delivery_instructions, allow_backorders
    add_column :customers, :preferred_delivery_method, :string, limit: 50
    add_column :customers, :special_handling_requirements, :text
    add_column :customers, :preferred_communication_method, :string, limit: 20  # Email, Phone, Both
    add_column :customers, :marketing_emails_allowed, :boolean, default: true
    add_column :customers, :auto_invoice_email, :boolean, default: true
    add_column :customers, :require_po_number, :boolean, default: false
    
    # ========================================
    # PERFORMANCE METRICS (Calculated/Updated)
    # ========================================
    add_column :customers, :total_orders_count, :integer, default: 0
    add_column :customers, :total_revenue_all_time, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :customers, :total_revenue_ytd, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :customers, :total_revenue_mtd, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :customers, :average_order_value, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :customers, :last_order_date, :date
    add_column :customers, :last_order_amount, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :customers, :orders_per_month, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :customers, :on_time_payment_rate, :decimal, precision: 5, scale: 2, default: 100.0
    add_column :customers, :average_days_to_pay, :integer, default: 0
    add_column :customers, :returns_count, :integer, default: 0
    add_column :customers, :returns_rate, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :customers, :customer_lifetime_value, :decimal, precision: 15, scale: 2, default: 0.0
    
    # ========================================
    # ADDITIONAL ADDRESSES (Keep existing for backward compatibility)
    # ========================================
    # Note: Existing billing_* and shipping_* fields remain
    # New CustomerAddress model will handle multiple addresses
    add_column :customers, :mailing_address_same_as_billing, :boolean, default: true
    
    # ========================================
    # AUDIT & METADATA
    # ========================================
    # Already have: created_at, updated_at, created_by_id, deleted
    add_column :customers, :last_activity_date, :datetime
    add_column :customers, :last_modified_by_id, :integer
    add_column :customers, :approved_by_id, :integer
    add_column :customers, :approved_at, :datetime
    
    # ========================================
    # INDEXES for Performance
    # ========================================
    add_index :customers, :customer_category
    add_index :customers, :customer_since
    add_index :customers, :industry_type
    add_index :customers, :sales_territory
    add_index :customers, :credit_hold
    add_index :customers, :last_order_date
    add_index :customers, :total_revenue_all_time
    add_index :customers, :on_time_payment_rate
    add_index :customers, [:is_active, :deleted]
    add_index :customers, :last_modified_by_id
    add_index :customers, :approved_by_id
    
    # ========================================
    # FOREIGN KEYS
    # ========================================
    add_foreign_key :customers, :users, column: :last_modified_by_id, on_delete: :nullify
    add_foreign_key :customers, :users, column: :approved_by_id, on_delete: :nullify
  end
end
