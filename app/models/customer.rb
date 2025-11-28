class Customer < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :default_tax_code, class_name: "TaxCode", optional: true
  belongs_to :default_ar_account, class_name: "Account", optional: true
  belongs_to :default_sales_rep, class_name: "User", optional: true
  belongs_to :default_warehouse, class_name: "Warehouse", optional: true

  CUSTOMER_TYPES = {
    "INDIVIDUAL" => "Individual",
    "BUSINESS"   => "Business",
    "GOVERNMENT" => "Government",
    "NON_PROFIT" => "Non-profit"
  }.freeze

  PAYMENT_TERMS = {
    "DUE_ON_RECEIPT" => "Due on Receipt",
    "NET_15"         => "Net 15",
    "NET_30"         => "Net 30",
    "NET_45"         => "Net 45",
    "NET_60"         => "Net 60",
    "PREPAID"        => "Prepaid"
  }.freeze

  FREIGHT_TERMS = {
    "PREPAID"     => "Prepaid",
    "COLLECT"     => "Collect",
    "THIRD_PARTY" => "Third Party"
  }.freeze

  CURRENCIES = {
    "USD" => "US Dollar",
    "CAD" => "Canadian Dollar"
  }.freeze

  # BASIC VALIDATIONS
  validates :code, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :full_name, presence: true, length: { maximum: 255 }

  validates :email, :primary_contact_email, :secondary_contact_email,
            allow_blank: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :phone_number, :mobile, :primary_contact_phone, :secondary_contact_phone,
            allow_blank: true,
            length: { maximum: 20 }

  validates :customer_type, inclusion: { in: CUSTOMER_TYPES.keys }, allow_blank: true
  validates :payment_terms, inclusion: { in: PAYMENT_TERMS.keys }, allow_blank: true
  validates :freight_terms, inclusion: { in: FREIGHT_TERMS.keys }, allow_blank: true
  validates :default_currency, inclusion: { in: CURRENCIES.keys }

  validates :credit_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :current_balance, numericality: true

  scope :active,      -> { where(is_active: true, deleted: false) }

  def display_name
    legal_name.presence || full_name
  end
end