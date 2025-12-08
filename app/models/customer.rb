# frozen_string_literal: true

# ============================================================================
# MODEL: Customer (Enhanced Enterprise Version)
# ============================================================================
# Complete customer management with addresses, contacts, documents, activities
# Includes performance metrics, credit management, and CRM features
# ============================================================================

class Customer < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  
  # User relationships
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :last_modified_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :default_sales_rep, class_name: "User", optional: true
  
  # System relationships
  belongs_to :default_tax_code, class_name: "TaxCode", optional: true
  belongs_to :default_ar_account, class_name: "Account", optional: true
  belongs_to :default_warehouse, class_name: "Warehouse", optional: true
  
  # Customer-specific relationships
  has_many :addresses, 
           -> { where(deleted: false).order(is_default: :desc, created_at: :desc) },
           class_name: "CustomerAddress",
           dependent: :destroy,
           inverse_of: :customer
           
  has_many :contacts,
           -> { where(deleted: false).order(is_primary_contact: :desc, created_at: :desc) },
           class_name: "CustomerContact",
           dependent: :destroy,
           inverse_of: :customer
           
  has_many :documents,
           -> { where(deleted: false).order(created_at: :desc) },
           class_name: "CustomerDocument",
           dependent: :destroy,
           inverse_of: :customer
           
  has_many :activities,
           -> { where(deleted: false).order(activity_date: :desc) },
           class_name: "CustomerActivity",
           dependent: :destroy,
           inverse_of: :customer
  
  # Future integrations (uncomment when ready)
  # has_many :sales_orders, dependent: :restrict_with_error
  # has_many :invoices, dependent: :restrict_with_error
  # has_many :quotes, dependent: :restrict_with_error
  
  # Nested attributes for inline management
  accepts_nested_attributes_for :addresses, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :contacts, allow_destroy: true, reject_if: :all_blank
  
  # ========================================
  # CONSTANTS & ENUMS
  # ========================================
  
  CUSTOMER_TYPES = {
    "INDIVIDUAL" => "Individual",
    "BUSINESS"   => "Business",
    "GOVERNMENT" => "Government",
    "NON_PROFIT" => "Non-profit"
  }.freeze
  
  CUSTOMER_CATEGORIES = {
    "A" => "A - High Value",
    "B" => "B - Medium Value",
    "C" => "C - Low Value",
    "NEW" => "New Customer",
    "INACTIVE" => "Inactive"
  }.freeze

  PAYMENT_TERMS = {
    "DUE_ON_RECEIPT" => "Due on Receipt",
    "NET_15"         => "Net 15",
    "NET_30"         => "Net 30",
    "NET_45"         => "Net 45",
    "NET_60"         => "Net 60",
    "NET_90"         => "Net 90",
    "PREPAID"        => "Prepaid",
    "COD"            => "Cash on Delivery"
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
  
  ACQUISITION_SOURCES = {
    "REFERRAL"    => "Referral",
    "MARKETING"   => "Marketing Campaign",
    "COLD_CALL"   => "Cold Call",
    "TRADE_SHOW"  => "Trade Show",
    "WEBSITE"     => "Website Inquiry",
    "PARTNER"     => "Partner Referral",
    "OTHER"       => "Other"
  }.freeze
  
  ORDER_FREQUENCIES = {
    "DAILY"      => "Daily",
    "WEEKLY"     => "Weekly",
    "BI_WEEKLY"  => "Bi-Weekly",
    "MONTHLY"    => "Monthly",
    "QUARTERLY"  => "Quarterly",
    "ANNUALLY"   => "Annually",
    "AS_NEEDED"  => "As Needed"
  }.freeze
  
  COMMUNICATION_METHODS = {
    "EMAIL" => "Email",
    "PHONE" => "Phone",
    "BOTH"  => "Both"
  }.freeze

  # ========================================
  # VALIDATIONS
  # ========================================
  
  # Basic required fields
  validates :code, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 20 }
  validates :full_name, presence: true, length: { maximum: 255 }
  
  # Email validations
  validates :email, :primary_contact_email, :secondary_contact_email,
            allow_blank: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            length: { maximum: 255 }
  
  # Phone validations
  validates :phone_number, :mobile, :fax,
            :primary_contact_phone, :secondary_contact_phone,
            allow_blank: true,
            length: { maximum: 20 }
  
  # Enum validations
  validates :customer_type, inclusion: { in: CUSTOMER_TYPES.keys }, allow_blank: true
  validates :customer_category, inclusion: { in: CUSTOMER_CATEGORIES.keys }, allow_blank: true
  validates :payment_terms, inclusion: { in: PAYMENT_TERMS.keys }, allow_blank: true
  validates :freight_terms, inclusion: { in: FREIGHT_TERMS.keys }, allow_blank: true
  validates :default_currency, inclusion: { in: CURRENCIES.keys }
  validates :customer_acquisition_source, inclusion: { in: ACQUISITION_SOURCES.keys }, allow_blank: true
  validates :expected_order_frequency, inclusion: { in: ORDER_FREQUENCIES.keys }, allow_blank: true
  validates :preferred_communication_method, inclusion: { in: COMMUNICATION_METHODS.keys }, allow_blank: true
  
  # Numeric validations
  validates :credit_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :current_balance, numericality: true
  validates :available_credit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :early_payment_discount, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :annual_revenue_potential, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :on_time_payment_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :average_days_to_pay, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :returns_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  
  # String length validations
  validates :legal_name, :website, :industry_type, length: { maximum: 255 }, allow_blank: true
  validates :sales_territory, length: { maximum: 50 }, allow_blank: true
  
  # ========================================
  # CALLBACKS
  # ========================================
  
  before_validation :generate_code, on: :create
  before_validation :normalize_data
  before_save :calculate_available_credit
  before_save :set_customer_since
  before_save :update_last_modified
  
  after_initialize :set_defaults, if: :new_record?
  
  # ========================================
  # SCOPES
  # ========================================
  
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :inactive, -> { where(is_active: false, deleted: false) }
  scope :credit_hold, -> { where(credit_hold: true, deleted: false) }
  scope :no_credit_hold, -> { where(credit_hold: false, deleted: false) }
  
  scope :by_category, ->(category) { where(customer_category: category, deleted: false) }
  scope :by_territory, ->(territory) { where(sales_territory: territory, deleted: false) }
  scope :by_sales_rep, ->(rep_id) { where(default_sales_rep_id: rep_id, deleted: false) }
  scope :by_type, ->(type) { where(customer_type: type, deleted: false) }
  
  scope :high_value, -> { where("total_revenue_all_time > ?", 100000).order(total_revenue_all_time: :desc) }
  scope :recent_orders, -> { where("last_order_date >= ?", 90.days.ago) }
  scope :no_recent_orders, -> { where("last_order_date < ? OR last_order_date IS NULL", 90.days.ago) }
  
  scope :search, ->(query) {
    where("code ILIKE ? OR full_name ILIKE ? OR legal_name ILIKE ? OR email ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
  }
  
  # ========================================
  # CLASS METHODS
  # ========================================
  
  def self.generate_next_code
    last_customer = Customer.unscoped.order(created_at: :desc).first
    if last_customer && last_customer.code =~ /^CUST-(\d+)$/
      next_number = $1.to_i + 1
    else
      next_number = 1001
    end
    "CUST-#{next_number.to_s.rjust(5, '0')}"
  end
  
  # ========================================
  # INSTANCE METHODS - Display
  # ========================================
  
  def display_name
    legal_name.presence || full_name
  end
  
  def full_display_name
    "#{code} - #{display_name}"
  end
  
  def status_label
    return "Credit Hold" if credit_hold?
    return "Inactive" if !is_active?
    "Active"
  end
  
  def status_badge_class
    return "danger" if credit_hold?
    return "secondary" if !is_active?
    "success"
  end
  
  def category_badge_class
    case customer_category
    when "A" then "success"
    when "B" then "primary"
    when "C" then "warning"
    when "NEW" then "info"
    when "INACTIVE" then "secondary"
    else "secondary"
    end
  end
  
  # ========================================
  # INSTANCE METHODS - Financial
  # ========================================
  
  def over_credit_limit?
    return false if credit_limit.nil? || credit_limit.zero?
    current_balance.to_d > credit_limit.to_d
  end
  
  def credit_utilization_percentage
    return 0 if credit_limit.nil? || credit_limit.zero?
    ((current_balance.to_d / credit_limit.to_d) * 100).round(2)
  end
  
  def can_place_order?(order_amount)
    return true if credit_limit.nil? || credit_limit.zero?  # No credit limit set
    return false if credit_hold?
    (current_balance.to_d + order_amount.to_d) <= credit_limit.to_d
  end
  
  def place_on_credit_hold!(reason)
    update!(
      credit_hold: true,
      credit_hold_reason: reason,
      credit_hold_date: Date.current
    )
  end
  
  def remove_credit_hold!
    update!(
      credit_hold: false,
      credit_hold_reason: nil,
      credit_hold_date: nil
    )
  end
  
  # ========================================
  # INSTANCE METHODS - Performance
  # ========================================
  
  def payment_performance_label
    rate = on_time_payment_rate.to_f
    case rate
    when 95..100 then "Excellent"
    when 85...95 then "Good"
    when 70...85 then "Fair"
    else "Poor"
    end
  end
  
  def customer_health_score
    # Calculate 0-100 score based on multiple factors
    score = 0
    
    # On-time payment (40 points)
    score += (on_time_payment_rate.to_f * 0.4).round
    
    # Recent activity (30 points)
    if last_order_date.present?
      days_since_order = (Date.current - last_order_date).to_i
      if days_since_order < 30
        score += 30
      elsif days_since_order < 90
        score += 20
      elsif days_since_order < 180
        score += 10
      end
    end
    
    # Revenue contribution (30 points)
    if total_revenue_ytd.to_d > 100000
      score += 30
    elsif total_revenue_ytd.to_d > 50000
      score += 20
    elsif total_revenue_ytd.to_d > 10000
      score += 10
    end
    
    score
  end
  
  def customer_health_label
    score = customer_health_score
    case score
    when 80..100 then "Excellent"
    when 60...80 then "Good"
    when 40...60 then "Fair"
    when 20...40 then "At Risk"
    else "Critical"
    end
  end
  
  # ========================================
  # INSTANCE METHODS - Relationships
  # ========================================
  
  def primary_contact
    contacts.find_by(is_primary_contact: true) || contacts.first
  end
  
  def primary_address
    addresses.find_by(is_default: true, address_type: ["BILLING", "BOTH"]) || addresses.first
  end
  
  def billing_address_object
    addresses.find_by(address_type: ["BILLING", "BOTH"], is_default: true) ||
    addresses.find_by(address_type: ["BILLING", "BOTH"])
  end
  
  def shipping_address_object
    addresses.find_by(address_type: ["SHIPPING", "BOTH"], is_default: true) ||
    addresses.find_by(address_type: ["SHIPPING", "BOTH"])
  end
  
  def recent_activities(limit = 10)
    activities.order(activity_date: :desc).limit(limit)
  end
  
  def pending_followups
    activities.where(followup_required: true, activity_status: "SCHEDULED")
              .where("followup_date <= ?", Date.current)
              .order(followup_date: :asc)
  end
  
  def active_documents
    documents.where(is_active: true)
  end
  
  def expiring_documents(days = 30)
    documents.where(is_active: true, requires_renewal: true)
             .where("expiry_date BETWEEN ? AND ?", Date.current, Date.current + days.days)
             .order(expiry_date: :asc)
  end
  
  # ========================================
  # INSTANCE METHODS - Activity Logging
  # ========================================
  
  def log_activity!(activity_params)
    activities.create!(activity_params.merge(
      created_by: activity_params[:created_by] || activity_params[:related_user]
    ))
    touch(:last_activity_date)
  end
  
  # ========================================
  # SOFT DELETE
  # ========================================
  
  def destroy!
    update_attribute(:deleted, true)
  end
  
  def restore!
    update_attribute(:deleted, false)
  end
  
  private
  
  # ========================================
  # PRIVATE METHODS - Callbacks
  # ========================================
  
  def generate_code
    self.code = self.class.generate_next_code if code.blank?
  end
  
  def normalize_data
    self.code = code.upcase.strip if code.present?
    self.email = email.downcase.strip if email.present?
    self.primary_contact_email = primary_contact_email.downcase.strip if primary_contact_email.present?
    self.secondary_contact_email = secondary_contact_email.downcase.strip if secondary_contact_email.present?
  end
  
  def calculate_available_credit
    if credit_limit.present? && current_balance.present?
      self.available_credit = [credit_limit.to_d - current_balance.to_d, 0].max
    end
  end
  
  def set_customer_since
    self.customer_since ||= Date.current if new_record?
  end
  
  def update_last_modified
    self.last_modified_by = Current.user if defined?(Current) && Current.respond_to?(:user)
  end
  
  def set_defaults
    self.is_active = true if is_active.nil?
    self.default_currency ||= "USD"
    self.customer_category ||= "NEW"
    self.credit_limit ||= 0
    self.current_balance ||= 0
    self.on_time_payment_rate ||= 100.0
    self.marketing_emails_allowed = true if marketing_emails_allowed.nil?
    self.auto_invoice_email = true if auto_invoice_email.nil?
    self.late_fee_applicable = true if late_fee_applicable.nil?
    self.allow_backorders = true if allow_backorders.nil?
  end
end
