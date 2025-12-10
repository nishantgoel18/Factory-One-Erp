class AddFieldsToSuppliers < ActiveRecord::Migration[8.1]
  def change
    # BASIC INFORMATION

    add_column :suppliers, :legal_name, :string
    add_column :suppliers, :trade_name, :string
    add_column :suppliers, :display_name, :string
    add_index  :suppliers, :legal_name

    # TAX & LEGAL
    add_column :suppliers, :tax_id, :string
    add_column :suppliers, :vat_number, :string
    add_column :suppliers, :gst_number, :string
    add_column :suppliers, :business_registration_number, :string
    add_column :suppliers, :is_1099_vendor, :boolean, default: false

    # CLASSIFICATION
    add_column :suppliers, :supplier_type, :string
    add_index  :suppliers, :supplier_type

    add_column :suppliers, :supplier_category, :string
    add_index  :suppliers, :supplier_category

    add_column :suppliers, :supplier_status, :string, default: "PENDING"
    add_index  :suppliers, :supplier_status

    add_column :suppliers, :status_reason, :string
    add_column :suppliers, :status_effective_date, :date
    add_column :suppliers, :approved_date, :date
    add_reference :suppliers, :approved_by, foreign_key: { to_table: :users }
    add_column :suppliers, :supplier_since, :date

    # CONTACT INFORMATION
    add_column :suppliers, :primary_email, :string
    add_column :suppliers, :primary_phone, :string
    add_column :suppliers, :primary_fax, :string
    add_column :suppliers, :website, :string
    add_column :suppliers, :linkedin_url, :string
    add_column :suppliers, :facebook_url, :string
    add_column :suppliers, :company_profile, :text

    # FINANCIAL TERMS
    add_column :suppliers, :default_payment_terms, :string, default: "NET_30"
    add_column :suppliers, :payment_method, :string
    add_column :suppliers, :currency, :string, default: "USD"
    add_column :suppliers, :credit_limit_extended, :decimal, precision: 15, scale: 2, default: 0
    add_column :suppliers, :current_payable_balance, :decimal, precision: 15, scale: 2, default: 0
    add_column :suppliers, :requires_advance_payment, :boolean, default: false
    add_column :suppliers, :advance_payment_percentage, :decimal, precision: 5, scale: 2
    add_column :suppliers, :early_payment_discount_percentage, :decimal, precision: 5, scale: 2
    add_column :suppliers, :early_payment_discount_days, :integer
    add_column :suppliers, :requires_tax_withholding, :boolean, default: false
    add_column :suppliers, :tax_withholding_percentage, :decimal, precision: 5, scale: 2

    # BANKING DETAILS
    add_column :suppliers, :bank_name, :string
    add_column :suppliers, :bank_account_number, :string
    add_column :suppliers, :bank_routing_number, :string
    add_column :suppliers, :bank_swift_code, :string
    add_column :suppliers, :bank_iban, :string
    add_column :suppliers, :bank_branch, :string

    # MANUFACTURING CAPABILITIES
    add_column :suppliers, :default_lead_time_days, :integer, default: 30
    add_column :suppliers, :minimum_order_quantity, :integer, default: 1
    add_column :suppliers, :maximum_order_quantity, :integer
    add_column :suppliers, :order_multiple, :integer
    add_column :suppliers, :production_capacity_monthly, :integer
    add_column :suppliers, :manufacturing_processes, :text
    add_column :suppliers, :quality_control_capabilities, :text
    add_column :suppliers, :testing_capabilities, :text
    add_column :suppliers, :materials_specialization, :text
    add_column :suppliers, :geographic_coverage, :text
    add_column :suppliers, :factory_locations, :text

    # CERTIFICATIONS
    add_column :suppliers, :certifications, :text
    add_column :suppliers, :iso_9001_certified, :boolean, default: false
    add_column :suppliers, :iso_14001_certified, :boolean, default: false
    add_column :suppliers, :iso_45001_certified, :boolean, default: false
    add_column :suppliers, :iso_9001_expiry, :date
    add_column :suppliers, :iso_14001_expiry, :date
    add_column :suppliers, :iso_45001_expiry, :date

    # PERFORMANCE METRICS
    add_column :suppliers, :late_deliveries_count, :integer, default: 0
    add_column :suppliers, :average_delay_days, :decimal, precision: 8, scale: 2, default: 0

    add_column :suppliers, :quality_acceptance_rate, :decimal, precision: 5, scale: 2, default: 100
    add_column :suppliers, :quality_rejection_rate, :decimal, precision: 5, scale: 2, default: 0
    add_column :suppliers, :quality_issues_count, :integer, default: 0

    add_column :suppliers, :actual_vs_promised_lead_time_ratio, :decimal, precision: 5, scale: 2, default: 1.0

    add_column :suppliers, :total_po_count, :integer, default: 0
    add_column :suppliers, :po_count_ytd, :integer, default: 0
    add_column :suppliers, :po_count_mtd, :integer, default: 0
    add_column :suppliers, :total_purchase_value, :decimal, precision: 15, scale: 2, default: 0
    add_column :suppliers, :purchase_value_ytd, :decimal, precision: 15, scale: 2, default: 0
    add_column :suppliers, :purchase_value_mtd, :decimal, precision: 15, scale: 2, default: 0
    add_column :suppliers, :average_po_value, :decimal, precision: 15, scale: 2, default: 0
    add_column :suppliers, :last_po_date, :date
    add_column :suppliers, :order_frequency_days, :decimal, precision: 8, scale: 2

    # VENDOR RATING
    add_column :suppliers, :overall_rating, :decimal, precision: 5, scale: 2, default: 0
    add_column :suppliers, :quality_score, :decimal, precision: 5, scale: 2, default: 0
    add_column :suppliers, :delivery_score, :decimal, precision: 5, scale: 2, default: 0
    add_column :suppliers, :price_score, :decimal, precision: 5, scale: 2, default: 0
    add_column :suppliers, :service_score, :decimal, precision: 5, scale: 2, default: 0
    add_column :suppliers, :rating_last_calculated_at, :date
    add_column :suppliers, :rating_label, :string
    add_column :suppliers, :is_preferred_supplier, :boolean, default: false
    add_index  :suppliers, :overall_rating
    add_index  :suppliers, :is_preferred_supplier

    # INTERNAL
    add_column :suppliers, :internal_notes, :text
    add_column :suppliers, :purchasing_notes, :text
    add_column :suppliers, :risk_level, :integer, default: 1
    add_column :suppliers, :risk_factors, :text
    add_column :suppliers, :last_audit_date, :date
    add_column :suppliers, :next_audit_due_date, :date
    add_reference :suppliers, :default_buyer, foreign_key: { to_table: :users }
    add_column :suppliers, :supplier_territory, :string

    # STATUS FLAGS
    add_column :suppliers, :can_receive_pos, :boolean, default: true
    add_column :suppliers, :can_receive_rfqs, :boolean, default: true
    add_column :suppliers, :is_strategic_supplier, :boolean, default: false
    add_column :suppliers, :is_minority_owned, :boolean, default: false
    add_column :suppliers, :is_woman_owned, :boolean, default: false
    add_column :suppliers, :is_veteran_owned, :boolean, default: false
    add_column :suppliers, :is_local_supplier, :boolean, default: false

    # SOFT DELETE
    add_column :suppliers, :is_deleted, :boolean, default: false
    add_column :suppliers, :deleted_at, :datetime
    add_reference :suppliers, :deleted_by, foreign_key: { to_table: :users }

    # AUDIT
    add_reference :suppliers, :created_by, foreign_key: { to_table: :users }
    add_reference :suppliers, :updated_by, foreign_key: { to_table: :users }
  end
end
