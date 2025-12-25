# ==========================================
# All Rails Models - Merged for AI Context
# Generated: 2025-12-24 16:14:19 +0530
# Total Models: 52
# ==========================================


# ============================================================
# Model 1: account
# File: app/models/account.rb
# ============================================================

class Account < ApplicationRecord
    attr_accessor :current_balance
    ACCOUNT_TYPE_CHOICES = {
        "INCOME"   => "Income",
        "EXPENSE"  => "Expense",
        "ASSET"    => "Asset",
        "LIABILITY"=> "Liability",
        "EQUITY"   => "Equity",
        "COGS"     => "Cost of Goods Sold",
        "INVENTORY" => "Inventory",
        "GRIR"     => "GR/IR"
    }

    SUB_TYPE_CHOICES = {
        "MATERIAL_COST" => "Material Cost",
        "LABOR_COST"    => "Labor Cost",
        "OVERHEAD_COST" => "Overhead",
        "SALES_REVENUE" => "Sales Revenue",
        "OTHER"         => "Other"
    }

    validates :code, presence: true, uniqueness: true
    validates :name, presence: true
    validates :account_type, presence: true
    validates :sub_type, presence: true

    def self.debit_increase_account_types
        ['ASSET', 'EXPENSE', 'COGS', 'INVENTORY']
    end

    def self.debit_increase_account_types
        ['LIABILITY', 'EQUITY', 'INCOME', 'GRIR']
    end
end

# ============================================================
# Model 2: application_record
# File: app/models/application_record.rb
# ============================================================

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :non_deleted, -> {where(deleted: [nil, false])}

  def destroy!
    update_attribute(:deleted, true)
  end
end

# ============================================================
# Model 3: bill_of_material
# File: app/models/bill_of_material.rb
# ============================================================

class BillOfMaterial < ApplicationRecord
    belongs_to :product
    # belongs_to :created_by, class_name: "User", optional: true

    has_many :bom_items, -> { where(deleted: false) }, dependent: :destroy

    accepts_nested_attributes_for :bom_items, allow_destroy: true

    STATUS_CHOICES = %w[DRAFT ACTIVE INACTIVE ARCHIVED]

    validates :code, presence: true, uniqueness: true
    validates :name, presence: true
    validates :revision, length: { maximum: 16 }
    validates :status, inclusion: { in: STATUS_CHOICES }
    validates :effective_from, presence: true

    validates :product_id, uniqueness: { scope: :revision, message: "must be unique for this product" }

    validate :product_must_allow_bom
    validate :date_range_must_be_valid
    validate :only_one_default_per_product
    validate :default_bom_must_be_active
    validate :no_overlapping_active_ranges
    validate :active_bom_must_have_items
    validate :archived_cannot_be_default

    before_save :handle_active_status
    before_save :ensure_single_default

    after_save :recompute_product_cost

    def can_be_activated?
        self.status != 'ACTIVE'
    end

    def product_must_allow_bom
        allowed_types = ["Finished Goods", "Semi-Finished Goods"]

        unless allowed_types.include?(self.product.product_type)
            errors.add(:product_id, "can only have a BOM if it is a Finished or Semi-Finished product")
        end
    end

    def date_range_must_be_valid
        if self.effective_to.present? && self.effective_to < self.effective_from
            errors.add(:base, "Effective To date cannot be earlier than Effective From date.")
        end
    end

    def only_one_default_per_product
        return unless self.is_default?

        conflict = BillOfMaterial.non_deleted.where(product_id: self.product_id, is_default: true).where.not(id: self.id)
        if conflict.exists?
            errors.add(:is_default, "Only one default BOM is allowed per product.")
        end
    end

    def default_bom_must_be_active
        if self.is_default? && self.status != "ACTIVE"
            errors.add(:is_default, "Only an 'Active' BOM can be set as default.")
        end
    end

    def active_bom_must_have_items
        return unless self.status == "ACTIVE"

        # only one ACTIVE bom allowed
        if BillOfMaterial.non_deleted.where(product_id: self.product_id, status: "ACTIVE").where.not(id: self.id).exists?
            errors.add(:status, "Only one ACTIVE BOM per product")
        end

        if bom_items.empty?
            errors.add(:base, "An Active BOM must contain at least one component line.")
        end
    end

    def archived_cannot_be_default
        if status == "ARCHIVED" && self.is_default?
            errors.add(:is_default, "ARCHIVED BOM cannot be marked as default.")
        end
    end

    def no_overlapping_active_ranges
        return unless status == "ACTIVE"

        from = effective_from
        to   = effective_to || effective_from

        overlap_exists = BillOfMaterial.non_deleted
            .where(product_id: product_id, status: "ACTIVE")
            .where.not(id: id)
            .where("effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)", to, from)
            .exists?

        if overlap_exists
            errors.add(:base, "Another ACTIVE BOM exists for this product within the same effective date range.")
        end
    end

    def handle_active_status
        return unless status == "ACTIVE"

        # Archive other active BOMs
        BillOfMaterial.non_deleted.where(product_id: product_id, status: "ACTIVE").where.not(id: id).update_all(status: "ARCHIVED", is_default: false)

        # Auto-set default if not already
        self.is_default = true unless is_default?
    end

    def ensure_single_default
        return unless self.is_default?

        BillOfMaterial.non_deleted.where(product_id: self.product_id)
           .where.not(id: self.id)
           .update_all(is_default: false)
    end

    def recompute_product_cost
        return unless self.is_default? && self.status == "ACTIVE"
        
        total_cost = BigDecimal("0")

        self.bom_items.where(deleted: false).includes(:component).each do |item|
            component_cost = item.component.standard_cost.to_d || BigDecimal("0")
            qty = item.quantity.to_d

            total_cost += qty * component_cost
        end

        self.product.update_column(:standard_cost, total_cost)
    end
end

# ============================================================
# Model 4: bom_item
# File: app/models/bom_item.rb
# ============================================================

class BomItem < ApplicationRecord
    belongs_to :bom
    belongs_to :component, class_name: "Product"
    belongs_to :uom, class_name: "UnitOfMeasure"

    validates :quantity, numericality: { greater_than: 0 }
    validates :scrap_percent, numericality: { 
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 100 
    }

    validates :scrap_percent, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

    validates :component_id, uniqueness: { scope: :bom_id, message: "already exists in this BOM" }

    validate :allowed_component_types
    validate  :no_decimal_if_uom_disallows
    validate  :component_cannot_equal_parent_product

    def allowed_component_types
        allowed_types = ['Raw Material', 'Service', 'Consumable']

        unless allowed_types.include?(self.component.product_type)
            errors.add(:product_id, "can only have a BOM Item if it is a #{allowed_types.to_sentence} component")
        end
    end

    def no_decimal_if_uom_disallows
        return if quantity.blank?
        return if uom&.is_decimal?

        # If UOM does not allow decimals
        if quantity.to_d != quantity.to_i
            errors.add(:quantity, "Decimal quantity not allowed for this UoM")
        end
    end
    
    def component_cannot_equal_parent_product
        if component_id.present? && bom&.product_id == component_id
            errors.add(:component, "cannot be the same as the parent product")
        end
    end
end

# ============================================================
# Model 5: customer
# File: app/models/customer.rb
# ============================================================

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

# ============================================================
# Model 6: customer_activity
# File: app/models/customer_activity.rb
# ============================================================

class CustomerActivity < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :customer, inverse_of: :activities, touch: :last_activity_date
  belongs_to :customer_contact, optional: true
  belongs_to :related_user, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  
  # Polymorphic association for linking to orders, quotes, etc.
  belongs_to :related_entity, polymorphic: true, optional: true
  
  # ========================================
  # CONSTANTS
  # ========================================
  ACTIVITY_TYPES = {
    "CALL"      => "Phone Call",
    "EMAIL"     => "Email",
    "MEETING"   => "Meeting",
    "NOTE"      => "Note/Comment",
    "QUOTE"     => "Quote Sent",
    "ORDER"     => "Order Placed",
    "COMPLAINT" => "Complaint/Issue",
    "VISIT"     => "Site Visit",
    "FOLLOWUP"  => "Follow-up"
  }.freeze
  
  ACTIVITY_STATUSES = {
    "SCHEDULED" => "Scheduled",
    "COMPLETED" => "Completed",
    "CANCELLED" => "Cancelled",
    "OVERDUE"   => "Overdue"
  }.freeze
  
  OUTCOMES = {
    "SUCCESS"      => "Successful",
    "NO_ANSWER"    => "No Answer",
    "VOICEMAIL"    => "Left Voicemail",
    "RESCHEDULED"  => "Rescheduled",
    "NOT_INTERESTED" => "Not Interested",
    "PENDING"      => "Pending Response",
    "RESOLVED"     => "Resolved",
    "ESCALATED"    => "Escalated"
  }.freeze
  
  COMMUNICATION_METHODS = {
    "PHONE"      => "Phone",
    "EMAIL"      => "Email",
    "IN_PERSON"  => "In Person",
    "VIDEO_CALL" => "Video Call",
    "SMS"        => "SMS",
    "PORTAL"     => "Customer Portal"
  }.freeze
  
  DIRECTIONS = {
    "INBOUND"  => "Inbound",
    "OUTBOUND" => "Outbound"
  }.freeze
  
  SENTIMENTS = {
    "POSITIVE" => "Positive",
    "NEUTRAL"  => "Neutral",
    "NEGATIVE" => "Negative",
    "URGENT"   => "Urgent"
  }.freeze
  
  PRIORITIES = {
    "LOW"    => "Low",
    "NORMAL" => "Normal",
    "HIGH"   => "High",
    "URGENT" => "Urgent"
  }.freeze
  
  CATEGORIES = {
    "SALES"   => "Sales",
    "SUPPORT" => "Support",
    "BILLING" => "Billing",
    "GENERAL" => "General"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES.keys }
  validates :activity_status, inclusion: { in: ACTIVITY_STATUSES.keys }, allow_blank: true
  validates :subject, presence: true, length: { maximum: 255 }
  validates :activity_date, presence: true
  
  validates :outcome, inclusion: { in: OUTCOMES.keys }, allow_blank: true
  validates :communication_method, inclusion: { in: COMMUNICATION_METHODS.keys }, allow_blank: true
  validates :direction, inclusion: { in: DIRECTIONS.keys }, allow_blank: true
  validates :customer_sentiment, inclusion: { in: SENTIMENTS.keys }, allow_blank: true
  validates :priority, inclusion: { in: PRIORITIES.keys }, allow_blank: true
  validates :category, inclusion: { in: CATEGORIES.keys }, allow_blank: true
  
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_defaults, on: :create
  after_save :check_for_followup_reminder
  
  # ========================================
  # SCOPES
  # ========================================
  scope :completed, -> { where(activity_status: "COMPLETED", deleted: false) }
  scope :scheduled, -> { where(activity_status: "SCHEDULED", deleted: false) }
  scope :overdue, -> { where("followup_date < ? AND activity_status = ?", Date.current, "SCHEDULED").where(deleted: false) }
  scope :requires_followup, -> { where(followup_required: true, deleted: false) }
  
  scope :by_type, ->(type) { where(activity_type: type, deleted: false) }
  scope :by_user, ->(user_id) { where(related_user_id: user_id, deleted: false) }
  scope :by_date_range, ->(start_date, end_date) { where(activity_date: start_date..end_date, deleted: false) }
  scope :this_week, -> { where(activity_date: Date.current.beginning_of_week..Date.current.end_of_week, deleted: false) }
  scope :this_month, -> { where(activity_date: Date.current.beginning_of_month..Date.current.end_of_month, deleted: false) }
  
  scope :urgent, -> { where(priority: "URGENT", deleted: false) }
  scope :negative_sentiment, -> { where(customer_sentiment: "NEGATIVE", deleted: false) }
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  def is_overdue?
    activity_status == "SCHEDULED" && followup_date.present? && followup_date < Date.current
  end
  
  def mark_completed!(outcome_value = nil, notes = nil)
    update!(
      activity_status: "COMPLETED",
      outcome: outcome_value,
      description: [description, notes].compact.join("\n\n")
    )
  end
  
  def reschedule!(new_date)
    update!(
      followup_date: new_date,
      activity_status: "SCHEDULED",
      outcome: "RESCHEDULED"
    )
  end
  
  def contact_name
    customer_contact&.full_name || "General"
  end
  
  def user_name
    related_user&.email || created_by&.email || "System"
  end
  
  def status_badge_class
    case activity_status
    when "COMPLETED" then "success"
    when "SCHEDULED" then "primary"
    when "CANCELLED" then "secondary"
    when "OVERDUE" then "danger"
    else "secondary"
    end
  end
  
  def priority_badge_class
    case priority
    when "LOW" then "secondary"
    when "NORMAL" then "primary"
    when "HIGH" then "warning"
    when "URGENT" then "danger"
    else "secondary"
    end
  end
  
  def sentiment_badge_class
    case customer_sentiment
    when "POSITIVE" then "success"
    when "NEUTRAL" then "secondary"
    when "NEGATIVE" then "danger"
    when "URGENT" then "warning"
    else "secondary"
    end
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
  
  def set_defaults
    self.activity_status ||= "COMPLETED"
    self.priority ||= "NORMAL"
    self.category ||= "GENERAL"
    self.activity_date ||= Time.current
  end
  
  def check_for_followup_reminder
    return unless saved_change_to_followup_date? && followup_required? && !reminder_sent?
    
    # TODO: Schedule reminder
    # FollowupReminderJob.set(wait_until: followup_date).perform_later(self.id)
  end
end

# ============================================================
# Model 7: customer_address
# File: app/models/customer_address.rb
# ============================================================

# frozen_string_literal: true

# ============================================================================
# MODEL: CustomerAddress
# ============================================================================
# Manages multiple addresses per customer (billing, shipping, warehouse, etc.)
# ============================================================================

class CustomerAddress < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :customer, inverse_of: :addresses
  belongs_to :created_by, class_name: "User", optional: true
  
  # ========================================
  # CONSTANTS
  # ========================================
  ADDRESS_TYPES = {
    "BILLING"   => "Billing Only",
    "SHIPPING"  => "Shipping Only",
    "BOTH"      => "Billing & Shipping",
    "WAREHOUSE" => "Warehouse/Pickup",
    "OTHER"     => "Other"
  }.freeze
  
  COUNTRIES = {
    "US" => "United States",
    "CA" => "Canada"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :address_type, presence: true, inclusion: { in: ADDRESS_TYPES.keys }
  validates :street_address_1, presence: true, length: { maximum: 255 }
  validates :street_address_2, length: { maximum: 255 }, allow_blank: true
  validates :city, presence: true, length: { maximum: 100 }
  validates :state_province, length: { maximum: 100 }, allow_blank: true
  validates :postal_code, presence: true, length: { maximum: 20 }
  validates :country, presence: true, inclusion: { in: COUNTRIES.keys }
  
  validates :address_label, length: { maximum: 100 }, allow_blank: true
  validates :attention_to, length: { maximum: 100 }, allow_blank: true
  validates :contact_phone, length: { maximum: 20 }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  
  # Only one default address per type per customer
  validates :is_default, uniqueness: { scope: [:customer_id, :address_type, :deleted], 
                                      message: "only one default address allowed per type" },
                        if: -> { is_default? && deleted == false }
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :normalize_data
  after_save :ensure_single_default, if: :saved_change_to_is_default?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :billing, -> { where(address_type: ["BILLING", "BOTH"], deleted: false) }
  scope :shipping, -> { where(address_type: ["SHIPPING", "BOTH"], deleted: false) }
  scope :defaults, -> { where(is_default: true, deleted: false) }
  scope :by_type, ->(type) { where(address_type: type, deleted: false) }
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  def full_address
    parts = [street_address_1]
    parts << street_address_2 if street_address_2.present?
    parts << "#{city}, #{state_province} #{postal_code}"
    parts << COUNTRIES[country]
    parts.join("\n")
  end
  
  def single_line_address
    parts = [street_address_1]
    parts << street_address_2 if street_address_2.present?
    parts << city
    parts << state_province if state_province.present?
    parts << postal_code
    parts << country
    parts.join(", ")
  end
  
  def display_label
    address_label.presence || ADDRESS_TYPES[address_type]
  end
  
  def can_use_for_billing?
    address_type.in?(["BILLING", "BOTH"])
  end
  
  def can_use_for_shipping?
    address_type.in?(["SHIPPING", "BOTH"])
  end
  
  def make_default!
    transaction do
      # Remove default from other addresses of same type
      self.class.where(customer_id: customer_id, address_type: address_type, is_default: true)
                .where.not(id: id)
                .update_all(is_default: false)
      
      update!(is_default: true)
    end
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
  
  def normalize_data
    self.postal_code = postal_code.upcase.strip if postal_code.present?
    self.country = country.upcase if country.present?
    self.contact_email = contact_email.downcase.strip if contact_email.present?
  end
  
  def ensure_single_default
    return unless is_default?
    
    # Unset default from other addresses of same type for this customer
    self.class.where(customer_id: customer_id, address_type: address_type, deleted: false)
              .where.not(id: id)
              .update_all(is_default: false)
  end
end

# ============================================================
# Model 8: customer_contact
# File: app/models/customer_contact.rb
# ============================================================

# frozen_string_literal: true

# ============================================================================
# MODEL: CustomerContact
# ============================================================================
# Manages multiple contact persons per customer with roles and communication prefs
# ============================================================================

class CustomerContact < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :customer, inverse_of: :contacts
  belongs_to :created_by, class_name: "User", optional: true
  
  has_many :activities, 
           class_name: "CustomerActivity",
           foreign_key: :customer_contact_id,
           dependent: :nullify
  
  # ========================================
  # CONSTANTS
  # ========================================
  CONTACT_ROLES = {
    "PRIMARY"        => "Primary Contact",
    "PURCHASING"     => "Purchasing",
    "FINANCE"        => "Finance/Accounts Payable",
    "TECHNICAL"      => "Technical/Engineering",
    "SHIPPING"       => "Shipping/Receiving",
    "DECISION_MAKER" => "Decision Maker",
    "QUALITY"        => "Quality Assurance",
    "MANAGEMENT"     => "Management",
    "OTHER"          => "Other"
  }.freeze
  
  CONTACT_METHODS = {
    "EMAIL" => "Email",
    "PHONE" => "Phone",
    "BOTH"  => "Email & Phone",
    "SMS"   => "SMS"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :contact_role, presence: true, inclusion: { in: CONTACT_ROLES.keys }
  
  validates :title, :department, length: { maximum: 100 }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true, length: { maximum: 255 }
  validates :phone, :mobile, :fax, length: { maximum: 20 }, allow_blank: true
  validates :extension, length: { maximum: 10 }, allow_blank: true
  validates :skype_id, length: { maximum: 100 }, allow_blank: true
  
  validates :preferred_contact_method, inclusion: { in: CONTACT_METHODS.keys }, allow_blank: true
  
  # Only one primary contact per customer
  validates :is_primary_contact, uniqueness: { scope: [:customer_id, :deleted],
                                              message: "only one primary contact allowed" },
                                if: -> { is_primary_contact? && deleted == false }
  
  # At least email or phone must be present
  validate :must_have_contact_method
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :normalize_data
  after_save :ensure_single_primary, if: :saved_change_to_is_primary_contact?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :primary, -> { where(is_primary_contact: true, deleted: false) }
  scope :decision_makers, -> { where(is_decision_maker: true, deleted: false) }
  scope :by_role, ->(role) { where(contact_role: role, deleted: false) }
  scope :by_department, ->(dept) { where(department: dept, deleted: false) }
  
  scope :search, ->(query) {
    where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR title ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
  }
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def full_name_with_title
    parts = [full_name]
    parts << title if title.present?
    parts.join(" - ")
  end
  
  def display_name
    parts = [full_name]
    parts << "(#{title})" if title.present?
    parts << "[#{CONTACT_ROLES[contact_role]}]"
    parts.join(" ")
  end
  
  def primary_email
    email.presence || customer.email
  end
  
  def primary_phone
    phone.presence || mobile.presence || customer.phone_number
  end
  
  def can_receive_orders?
    contact_role.in?(["PRIMARY", "PURCHASING", "MANAGEMENT", "DECISION_MAKER"])
  end
  
  def can_receive_invoices?
    contact_role.in?(["PRIMARY", "FINANCE", "MANAGEMENT"]) || receive_invoice_copies?
  end
  
  def make_primary!
    transaction do
      # Remove primary from other contacts
      self.class.where(customer_id: customer_id, is_primary_contact: true, deleted: false)
                .where.not(id: id)
                .update_all(is_primary_contact: false)
      
      update!(is_primary_contact: true, is_active: true)
    end
  end
  
  def log_interaction!(notes:, method: "PHONE")
    update!(
      last_contacted_at: Time.current,
      last_contacted_by: Current.user&.email || "System",
      last_interaction_notes: notes
    )
  end
  
  def has_birthday_soon?(days = 7)
    return false if birthday.blank?
    
    today = Date.current
    this_year_birthday = Date.new(today.year, birthday.month, birthday.day)
    
    (this_year_birthday - today).to_i.between?(0, days)
  end
  
  # ========================================
  # SOFT DELETE
  # ========================================
  
  def destroy!
    # If deleting primary contact, make another contact primary
    if is_primary_contact?
      next_contact = customer.contacts.where.not(id: id).first
      next_contact&.make_primary!
    end
    
    update_attribute(:deleted, true)
  end
  
  def restore!
    update_attribute(:deleted, false)
  end
  
  private
  
  def normalize_data
    self.first_name = first_name.strip.titleize if first_name.present?
    self.last_name = last_name.strip.titleize if last_name.present?
    self.email = email.downcase.strip if email.present?
  end
  
  def must_have_contact_method
    if email.blank? && phone.blank? && mobile.blank?
      errors.add(:base, "Must provide at least email, phone, or mobile number")
    end
  end
  
  def ensure_single_primary
    return unless is_primary_contact?
    
    # Unset primary from other contacts for this customer
    self.class.where(customer_id: customer_id, deleted: false)
              .where.not(id: id)
              .update_all(is_primary_contact: false)
  end
end

# ============================================================
# Model 9: customer_document
# File: app/models/customer_document.rb
# ============================================================

# frozen_string_literal: true

# ============================================================================
# MODEL: CustomerDocument
# ============================================================================
# Manages document attachments with ActiveStorage integration
# ============================================================================

class CustomerDocument < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :customer, inverse_of: :documents
  belongs_to :uploaded_by, class_name: "User", optional: true
  belongs_to :superseded_by_document, class_name: "CustomerDocument", foreign_key: :superseded_by_id, optional: true
  
  # ActiveStorage for file uploads
  has_one_attached :file
  
  # ========================================
  # CONSTANTS
  # ========================================
  DOCUMENT_TYPES = {
    "CONTRACT"         => "Contract/Agreement",
    "TAX_CERT"         => "Tax Exemption Certificate",
    "NDA"              => "Non-Disclosure Agreement",
    "CREDIT_APP"       => "Credit Application",
    "QUALITY_AGREEMENT"=> "Quality Agreement",
    "INSURANCE_CERT"   => "Insurance Certificate",
    "BUSINESS_LICENSE" => "Business License",
    "W9_FORM"          => "W-9 Form",
    "OTHER"            => "Other Document"
  }.freeze
  
  DOCUMENT_CATEGORIES = {
    "LEGAL"      => "Legal",
    "FINANCIAL"  => "Financial",
    "QUALITY"    => "Quality",
    "COMPLIANCE" => "Compliance",
    "GENERAL"    => "General"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES.keys }
  validates :document_category, inclusion: { in: DOCUMENT_CATEGORIES.keys }, allow_blank: true
  validates :document_title, presence: true, length: { maximum: 255 }
  validates :version, length: { maximum: 20 }, allow_blank: true
  
  validate :expiry_date_must_be_future, if: :effective_date
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_file_metadata, if: -> { file.attached? }
  after_save :check_for_expiry_alert
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :expired, -> { where("expiry_date < ?", Date.current).where(deleted: false) }
  scope :expiring_soon, ->(days = 30) { 
    where("expiry_date BETWEEN ? AND ?", Date.current, Date.current + days.days)
    .where(deleted: false, requires_renewal: true)
  }
  scope :by_type, ->(type) { where(document_type: type, deleted: false) }
  scope :by_category, ->(cat) { where(document_category: cat, deleted: false) }
  scope :latest_versions, -> { where(is_latest_version: true, deleted: false) }
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  def expired?
    expiry_date.present? && expiry_date < Date.current
  end
  
  def expiring_soon?(days = 30)
    return false unless expiry_date.present? && requires_renewal?
    expiry_date.between?(Date.current, Date.current + days.days)
  end
  
  def days_until_expiry
    return nil unless expiry_date.present?
    (expiry_date - Date.current).to_i
  end
  
  def file_attached?
    file.attached?
  end
  
  def file_url_or_attachment
    file_url.presence || (file.attached? ? Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true) : nil)
  end
  
  def supersede_with!(new_document)
    transaction do
      update!(
        is_latest_version: false,
        superseded_by_id: new_document.id,
        is_active: false
      )
      new_document.update!(
        version: increment_version,
        is_latest_version: true
      )
    end
  end
  
  def increment_version
    return "1.0" if version.blank?
    major, minor = version.split('.').map(&:to_i)
    "#{major}.#{minor + 1}"
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
  
  def set_file_metadata
    return unless file.attached?
    
    self.file_name = file.filename.to_s
    self.file_type = file.content_type
    self.file_size = file.byte_size
  end
  
  def expiry_date_must_be_future
    if expiry_date.present? && effective_date.present? && expiry_date < effective_date
      errors.add(:expiry_date, "must be after effective date")
    end
  end
  
  def check_for_expiry_alert
    return unless saved_change_to_expiry_date? && expiring_soon?(renewal_reminder_days)
    
    # TODO: Trigger alert/notification
    # ExpiryAlertJob.perform_later(self.id)
  end
end

# ============================================================
# Model 10: cycle_count
# File: app/models/cycle_count.rb
# ============================================================

class CycleCount < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :warehouse
  belongs_to :scheduled_by, class_name: "User", optional: true
  belongs_to :counted_by, class_name: "User", optional: true
  belongs_to :posted_by, class_name: "User", optional: true
  
  has_many :lines,
           -> { where(deleted: false) },
           class_name: "CycleCountLine",
           foreign_key: "cycle_count_id",
           dependent: :destroy, :inverse_of  => :cycle_count
           
  accepts_nested_attributes_for :lines, allow_destroy: true
  
  # ===================================
  # CONSTANTS
  # ===================================
  STATUS_SCHEDULED   = 'SCHEDULED'
  STATUS_IN_PROGRESS = 'IN_PROGRESS'
  STATUS_COMPLETED   = 'COMPLETED'
  STATUS_POSTED      = 'POSTED'
  STATUS_CANCELLED   = 'CANCELLED'
  
  STATUSES = [
    STATUS_SCHEDULED,
    STATUS_IN_PROGRESS,
    STATUS_COMPLETED,
    STATUS_POSTED,
    STATUS_CANCELLED
  ].freeze
  
  COUNT_TYPES = {
    'FULL'       => 'Full Warehouse Count',
    'PARTIAL'    => 'Partial Count',
    'ABC_A'      => 'ABC Analysis - Class A',
    'ABC_B'      => 'ABC Analysis - Class B',
    'ABC_C'      => 'ABC Analysis - Class C',
    'SPOT_CHECK' => 'Random Spot Check',
    'LOCATION'   => 'Specific Location Count'
  }.freeze
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :reference_no, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :scheduled_at, presence: true
  validates :warehouse_id, presence: true
  validates :count_type, inclusion: { in: COUNT_TYPES.keys }, allow_blank: true
  
  validate :must_have_lines
  validate :all_lines_must_be_counted_before_completion
  
  # ===================================
  # SCOPES
  # ===================================
  scope :active, -> { where(deleted: false) }
  scope :scheduled, -> { where(status: STATUS_SCHEDULED, deleted: false) }
  scope :in_progress, -> { where(status: STATUS_IN_PROGRESS, deleted: false) }
  scope :completed, -> { where(status: STATUS_COMPLETED, deleted: false) }
  scope :cancelled, -> { where(status: STATUS_CANCELLED, deleted: false) }

  scope :posted, -> { where(status: STATUS_POSTED, deleted: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  scope :upcoming, -> { where('scheduled_at > ?', Time.current).order(:scheduled_at) }
  scope :overdue, -> { where('scheduled_at < ? AND status = ?', Time.current, STATUS_SCHEDULED) }
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :generate_reference_no, on: :create
  before_validation :capture_system_quantities, if: :status_changed_to_in_progress?
  after_save :update_summary_stats, if: :saved_change_to_status?
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def can_start_counting?
    status == STATUS_SCHEDULED
  end
  
  def can_complete?
    status == STATUS_IN_PROGRESS && all_lines_counted?
  end
  
  def can_post?
    status == STATUS_COMPLETED && has_variances?
  end
  
  def can_edit?
    [STATUS_SCHEDULED, STATUS_IN_PROGRESS].include?(status)
  end
  
  # Start the counting process
  def start_counting!(user:)
    raise "Cannot start - Count is not scheduled" unless can_start_counting?
    
    update!(
      status: STATUS_IN_PROGRESS,
      count_started_at: Time.current,
      counted_by: user
    )
  end
  
  # Mark as completed (all lines counted)
  def complete!(user:)
    raise "Cannot complete - Not all lines are counted" unless can_complete?
    
    CycleCount.transaction do
      # Calculate variances for all lines
      lines.each(&:calculate_variance!)
      
      update!(
        status: STATUS_COMPLETED,
        count_completed_at: Time.current
      )
    end
  end
  
  # Post count results - create adjustments for variances
  def post!(user:)
    raise "Cannot post - Count is not completed" unless can_post?
    
    CycleCount.transaction do
      lines.where(deleted: false).where.not(variance: 0).find_each do |line|
        # Create stock transaction for COUNT_CORRECTION
        txn_type = "COUNT_CORRECTION"
        
        # Determine from/to location based on variance
        if line.variance > 0
          # Positive variance = system mein kam tha, actual mein zyada hai
          # ADD stock to location
          from_loc = line.location  # ✅ Same location
          to_loc = line.location    # ✅ Same location
          qty = line.variance       # ✅ POSITIVE quantity (e.g., +20)
          
        else
          # Negative variance = system mein zyada tha, actual mein kam hai
          # REMOVE stock from location
          from_loc = line.location  # ✅ Same location
          to_loc = line.location    # ✅ Same location
          qty = line.variance       # ✅ NEGATIVE quantity (e.g., -15)
        end
        
        StockTransaction.create!(
          product: line.product,
          uom: line.uom,
          txn_type: txn_type,
          quantity: qty,
          from_location: from_loc,
          to_location: to_loc,
          batch: line.batch_if_applicable,
          reference_type: "CYCLE_COUNT",
          reference_id: id.to_s,
          note: "Cycle Count: #{reference_no} - Variance: #{line.variance}",
          created_by: user
        )
        
        # Mark line as adjusted
        line.update!(line_status: 'ADJUSTED')
      end
      
      # Update cycle count status
      update!(
        status: STATUS_POSTED,
        posted_at: Time.current,
        posted_by: user
      )
    end
    
    true
  rescue => e
    errors.add(:base, "Posting failed: #{e.message}")
    false
  end
  
  def all_lines_counted?
    lines.where(deleted: false).where("counted_qty IS NULL").empty?
  end
  
  def has_variances?
    lines.where(deleted: false).where.not(variance: 0).exists?
  end
  
  def total_variance_value
    lines.where(deleted: false).sum(:variance)
  end
  
  def accuracy_percentage
    return 100.0 if total_lines_count.zero?
    
    accurate_lines = total_lines_count - lines_with_variance_count
    (accurate_lines.to_f / total_lines_count * 100).round(2)
  end
  
  private
  
  def generate_reference_no
    return if reference_no.present?
    
    date_part = scheduled_at.strftime('%Y%m%d')
    random_part = SecureRandom.hex(3).upcase
    
    self.reference_no = "CC-#{date_part}-#{random_part}"
    
    # Ensure uniqueness
    counter = 1
    while CycleCount.where(reference_no: reference_no).exists?
      self.reference_no = "CC-#{date_part}-#{random_part}-#{counter}"
      counter += 1
    end
  end
  
  def status_changed_to_in_progress?
    status == STATUS_IN_PROGRESS && status_changed?
  end
  
  def capture_system_quantities
    lines.where(deleted: false).each do |line|
      line.capture_system_qty!
    end
  end
  
  def update_summary_stats
    self.total_lines_count = lines.where(deleted: false).count
    self.lines_with_variance_count = lines.where(deleted: false).where.not(variance: 0).count
    save if changed?
  end
  
  def must_have_lines
    if lines.where(deleted: false).empty? && !new_record?
      errors.add(:base, "Cycle count must have at least one line")
    end
  end
  
  def all_lines_must_be_counted_before_completion
    return unless status == STATUS_COMPLETED
    
    unless all_lines_counted?
      errors.add(:base, "All lines must be counted before marking as completed")
    end
  end
end

# ============================================================
# Model 11: cycle_count_line
# File: app/models/cycle_count_line.rb
# ============================================================

class CycleCountLine < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :cycle_count, inverse_of: :lines
  belongs_to :product
  belongs_to :location
  belongs_to :batch, class_name: "StockBatch", optional: true
  belongs_to :uom, class_name: "UnitOfMeasure"
  
  # ===================================
  # CONSTANTS
  # ===================================
  LINE_STATUS_PENDING  = 'PENDING'
  LINE_STATUS_COUNTED  = 'COUNTED'
  LINE_STATUS_ADJUSTED = 'ADJUSTED'
  
  LINE_STATUSES = [LINE_STATUS_PENDING, LINE_STATUS_COUNTED, LINE_STATUS_ADJUSTED].freeze
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :product_id, presence: true
  validates :location_id, presence: true
  validates :uom_id, presence: true
  validates :line_status, inclusion: { in: LINE_STATUSES }
  
  validates :counted_qty, numericality: { greater_than_or_equal_to: 0 }, 
            allow_nil: true
  
  validate :location_must_belong_to_count_warehouse
  validate :batch_rules
  validate :cannot_edit_if_posted
  validate :no_decimal_if_uom_disallows
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :set_default_uom, on: :create
  after_save :update_line_status, if: :saved_change_to_counted_qty?
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def batch_if_applicable
    product&.is_batch_tracked? ? batch : nil
  end
  
  def has_variance?
    variance.present? && variance != 0
  end
  
  def variance_percentage
    return 0.0 if system_qty.zero?
    (variance.to_d / system_qty * 100).round(2)
  end
  
  # Capture system quantity from StockLevel
  def capture_system_qty!
    stock_level = StockLevel.find_by(
      product: product,
      location: location,
      batch: batch_if_applicable
    )
    
    update_column(:system_qty, stock_level&.on_hand_qty || 0.to_d)
  end
  
  # Calculate variance after counting
  def calculate_variance!
    return if counted_qty.nil?
    
    variance_value = counted_qty.to_d - system_qty.to_d
    update_columns(variance: variance_value)
  end
  
  private
  
  def set_default_uom
    return if uom_id.present?
    self.uom_id = product&.unit_of_measure_id
  end
  
  def update_line_status
    if counted_qty.present? && line_status == LINE_STATUS_PENDING
      update_column(:line_status, LINE_STATUS_COUNTED)
      calculate_variance!
    end
  end
  
  def location_must_belong_to_count_warehouse
    return if location.nil? || cycle_count.nil?
    
    if location.warehouse_id != cycle_count.warehouse_id
      errors.add(:location, "must belong to the cycle count's warehouse")
    end
  end
  
  def batch_rules
    return if product.nil?
    
    # If product is batch-tracked, batch is required
    if product.is_batch_tracked?
      if batch.nil?
        errors.add(:batch, "is required for batch-tracked products")
      elsif batch.product_id != product_id
        errors.add(:batch, "must belong to the selected product")
      end
    else
      # If product is NOT batch-tracked, batch must be blank
      if batch.present?
        errors.add(:batch, "must be blank for non batch-tracked products")
      end
    end
  end
  
  def cannot_edit_if_posted
    return if cycle_count.nil?
    
    if cycle_count.status == CycleCount::STATUS_POSTED && 
       (counted_qty_changed? || product_id_changed? || location_id_changed?)
      errors.add(:base, "Cannot modify line after cycle count is posted")
    end
  end
  
  def no_decimal_if_uom_disallows
    return if counted_qty.blank? || uom.nil?
    return if uom.is_decimal?
    
    if counted_qty.to_d != counted_qty.to_i
      errors.add(:counted_qty, "Decimal quantity not allowed for this Unit of Measure")
    end
  end
end

# ============================================================
# Model 12: goods_receipt
# File: app/models/goods_receipt.rb
# ============================================================

class GoodsReceipt < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :warehouse
  belongs_to :supplier, optional: true
  belongs_to :purchase_order, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :posted_by, class_name: "User", optional: true
  
  has_many :lines, 
           -> { where(deleted: false) },
           class_name: "GoodsReceiptLine",
           foreign_key: "goods_receipt_id",
           dependent: :destroy,
           inverse_of: :goods_receipt
           
  accepts_nested_attributes_for :lines, allow_destroy: true
  
  # ===================================
  # CONSTANTS
  # ===================================
  STATUS_DRAFT  = 'DRAFT'
  STATUS_POSTED = 'POSTED'
  STATUSES = [STATUS_DRAFT, STATUS_POSTED].freeze
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :reference_no, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :receipt_date, presence: true
  validates :warehouse_id, presence: true
  
  validate :must_have_lines_before_posting
  validate :all_locations_must_be_receivable
  
  # ===================================
  # SCOPES
  # ===================================
  scope :active, -> { where(deleted: false) }
  scope :draft, -> { where(status: STATUS_DRAFT, deleted: false) }
  scope :posted, -> { where(status: STATUS_POSTED, deleted: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :generate_reference_no
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def can_post?
    status == STATUS_DRAFT && lines.exists?
  end
  
  def can_edit?
    status == STATUS_DRAFT
  end
  
  # Main posting method - creates stock transactions
  def post!(user:)
    raise "Cannot post - GRN is not in DRAFT status" unless can_post?
    
    GoodsReceipt.transaction do
      lines.where(deleted: false).find_each do |line|
        # Create RECEIPT transaction for each line
        StockTransaction.create!(
          product: line.product,
          uom: line.uom,
          txn_type: "RECEIPT",
          quantity: line.qty,
          from_location: nil,  # No source for receipts
          to_location: line.location,  # Receiving location
          batch: line.batch_if_applicable,
          reference_type: "GRN",
          reference_id: id.to_s,
          note: "GRN: #{reference_no} - #{line.line_note}",
          created_by: user
        )
      

        self.purchase_order.lines.find_by(product: line.product)&.update(:received_qty => line.qty)
      end
      # Update GRN status
      update!(
        status: STATUS_POSTED,
        posted_at: Time.current,
        posted_by: user
      )
    end
    
    true
  rescue => e
    errors.add(:base, "Posting failed: #{e.message}")
    false
  end
  
  def total_lines
    lines.count
  end
  
  def total_quantity
    lines.sum(:qty)
  end
  
  private
  
  def generate_reference_no
    return if reference_no.present?
    
    date_part = receipt_date.strftime('%Y%m%d')
    random_part = SecureRandom.hex(3).upcase
    
    self.reference_no = "GRN-#{date_part}-#{random_part}"
    
    # Ensure uniqueness
    counter = 1
    while GoodsReceipt.where(reference_no: reference_no).exists?
      self.reference_no = "GRN-#{date_part}-#{random_part}-#{counter}"
      counter += 1
    end
  end
  
  def must_have_lines_before_posting
    return unless status == STATUS_POSTED
    
    if lines.where(deleted: false).empty?
      errors.add(:base, "Cannot post GRN without any line items")
    end
  end
  
  def all_locations_must_be_receivable
    return if lines.empty?
    
    non_receivable = lines.where(deleted: false).includes(:location).select do |line|
      line.location && !line.location.is_receivable?
    end
    
    if non_receivable.any?
      errors.add(:base, "All receiving locations must be marked as 'receivable'")
    end
  end
end

# ============================================================
# Model 13: goods_receipt_line
# File: app/models/goods_receipt_line.rb
# ============================================================

class GoodsReceiptLine < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :goods_receipt, inverse_of: :lines
  belongs_to :product
  belongs_to :location
  belongs_to :batch, class_name: "StockBatch", optional: true
  belongs_to :uom, class_name: "UnitOfMeasure"
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :qty, presence: true, numericality: { greater_than: 0 }
  validates :product_id, presence: true
  validates :location_id, presence: true
  validates :uom_id, presence: true
  
  validate :location_must_be_receivable
  validate :location_must_belong_to_grn_warehouse
  validate :batch_rules
  validate :cannot_edit_if_posted
  validate :no_decimal_if_uom_disallows
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :set_default_uom, on: :create
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def batch_if_applicable
    product&.is_batch_tracked? ? batch : nil
  end
  
  def line_total
    return 0 if unit_cost.nil?
    qty.to_d * unit_cost.to_d
  end
  
  private
  
  def set_default_uom
    return if uom_id.present?
    self.uom_id = product&.unit_of_measure_id
  end
  
  def location_must_be_receivable
    return if location.nil?
    
    unless location.is_receivable?
      errors.add(:location, "must be a receivable location")
    end
  end
  
  def location_must_belong_to_grn_warehouse
    return if location.nil? || goods_receipt.nil?
    
    if location.warehouse_id != goods_receipt.warehouse_id
      errors.add(:location, "must belong to the GRN's warehouse")
    end
  end
  
  def batch_rules
    return if product.nil?
    
    # If product is batch-tracked, batch is required
    if product.is_batch_tracked?
      if batch.nil?
        errors.add(:batch, "is required for batch-tracked products")
      elsif batch.product_id != product_id
        errors.add(:batch, "must belong to the selected product")
      end
    else
      # If product is NOT batch-tracked, batch must be blank
      if batch.present?
        errors.add(:batch, "must be blank for non batch-tracked products")
      end
    end
  end
  
  def cannot_edit_if_posted
    return if goods_receipt.nil?
    
    if goods_receipt.status == GoodsReceipt::STATUS_POSTED && 
       (qty_changed? || product_id_changed? || location_id_changed?)
      errors.add(:base, "Cannot modify line after GRN is posted")
    end
  end
  
  def no_decimal_if_uom_disallows
    return if qty.blank? || uom.nil?
    return if uom.is_decimal?
    
    if qty.to_d != qty.to_i
      errors.add(:qty, "Decimal quantity not allowed for this Unit of Measure")
    end
  end
end

# ============================================================
# Model 14: journal_entry
# File: app/models/journal_entry.rb
# ============================================================

class JournalEntry < ApplicationRecord
	REF_TYPE_CHOICES = {
        'PO' => "Purchase Order",
        'GRN' => "Goods Receipt Note",
        'SO' => "Sales Order",
        'SHIPMENT' => "Shipment",
        'WO' => "Work Order",
        'ADJUSTMENT' => "Adjustment",
    }


	has_many :journal_lines, dependent: :destroy
	belongs_to :posted_by_user, class_name: "User", foreign_key: "posted_by", optional: true

	accepts_nested_attributes_for :journal_lines, allow_destroy: true

	validates :entry_date, presence: true
	# validates :entry_number, presence: true, uniqueness: true
	validates :reference_type, inclusion: { in: REF_TYPE_CHOICES.keys }, allow_nil: true, allow_blank: true

	validate :must_balance
  	validate :must_have_lines

  	before_create :generate_entry_number

  	def must_have_lines

    	if journal_lines.select{|je| !je.deleted? }.reject(&:marked_for_destruction?).size < 1
      		errors.add(:base, "At least one line is required.")
    	end
  	end

  	def must_balance
    	debits = journal_lines.select{|je| !je.deleted? }.sum(&:debit)
    	credits = journal_lines.select{|je| !je.deleted? }.sum(&:credit)

    	if debits != credits
      		errors.add(:base, "Debits and credits must be equal.")
    	end
  	end

  	def generate_entry_number
    	self.entry_number ||= "JE-#{Time.now.strftime("%Y%m%d")}-#{SecureRandom.hex(2).upcase}"
  	end

  	def post!(user)
    	return "Journal entry already posted." if posted_at.present?
    	if journal_lines.select{|je| !je.deleted? }.sum(&:debit) != journal_lines.select{|je| !je.deleted? }.sum(&:credit)
      		return "Journal entry must be balanced."
    	end

    	transaction do
      		update!(posted_at: Time.current, posted_by: user.id)

      		journal_lines.select{|je| !je.deleted? }.each do |line|
        		account = line.account
        		debit  = line.debit.to_d
        		credit = line.credit.to_d

        		if %w[ASSET EXPENSE COGS INVENTORY].include?(account.account_type)
          			new_balance = account.current_balance.to_d + (debit - credit)
        		else
          			new_balance = account.current_balance.to_d + (credit - debit)
        		end

        		account.update!(current_balance: new_balance)
      		end
    	end
    	return "Journal entry posted successfully."
  	end
end

# ============================================================
# Model 15: journal_line
# File: app/models/journal_line.rb
# ============================================================

class JournalLine < ApplicationRecord
  belongs_to :journal_entry
  belongs_to :account

  validates :account_id, presence: true
  validates :debit, numericality: { greater_than_or_equal_to: 0 }
  validates :credit, numericality: { greater_than_or_equal_to: 0 }

  validate :cannot_have_both_debit_and_credit

  def cannot_have_both_debit_and_credit
    if debit.to_d > 0 && credit.to_d > 0
      errors.add(:base, "A line cannot have both debit and credit.")
    end

    if debit.to_d == 0 && credit.to_d == 0
      errors.add(:base, "Either debit or credit must be entered.")
    end
  end
end

# ============================================================
# Model 16: labor_time_entry
# File: app/models/labor_time_entry.rb
# ============================================================

# app/models/labor_time_entry.rb

class LaborTimeEntry < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :work_order_operation
  belongs_to :operator, class_name: 'User', foreign_key: 'operator_id'
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :clock_in_at, presence: true
  validates :entry_type, presence: true, 
            inclusion: { in: %w[REGULAR BREAK OVERTIME] }
  
  validate :clock_out_after_clock_in, if: :clock_out_at?
  validate :no_overlapping_entries_for_operator
  
  # ========================================
  # SCOPES
  # ========================================
  scope :non_deleted, -> { where(deleted: false) }
  scope :active, -> { where(clock_out_at: nil) }
  scope :completed, -> { where.not(clock_out_at: nil) }
  scope :for_operator, ->(operator_id) { where(operator_id: operator_id) }
  scope :for_date, ->(date) { where('DATE(clock_in_at) = ?', date) }
  scope :regular, -> { where(entry_type: 'REGULAR') }
  scope :breaks, -> { where(entry_type: 'BREAK') }
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_save :calculate_hours_worked, if: :clock_out_at_changed?
  after_save :update_operation_actual_time, if: :saved_change_to_clock_out_at?
  
  # ========================================
  # CLASS METHODS
  # ========================================
  
  # Get current active clock-in for an operator
  def self.current_for_operator(operator_id)
    active.for_operator(operator_id).order(clock_in_at: :desc).first
  end
  
  # Check if operator is currently clocked in anywhere
  def self.operator_clocked_in?(operator_id)
    active.for_operator(operator_id).exists?
  end
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  # Clock out this entry
  def clock_out!(clock_out_time = Time.current)
    self.clock_out_at = clock_out_time
    calculate_hours_worked
    save!
  end
  
  # Calculate hours worked
  def calculate_hours_worked
    return unless clock_in_at.present? && clock_out_at.present?
    
    duration_seconds = clock_out_at - clock_in_at
    self.hours_worked = (duration_seconds / 3600.0).round(4)
  end
  
  # Get elapsed time in hours (for active entries)
  def elapsed_hours
    return hours_worked if clock_out_at.present?
    
    ((Time.current - clock_in_at) / 3600.0).round(2)
  end
  
  # Get elapsed time in minutes
  def elapsed_minutes
    (elapsed_hours * 60).round(0)
  end
  
  # Human readable elapsed time
  def elapsed_time_display
    total_minutes = elapsed_minutes
    hours = total_minutes / 60
    minutes = total_minutes % 60
    
    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end
  
  # Is this entry still active (not clocked out)?
  def active?
    clock_out_at.nil?
  end
  
  # Entry type labels
  def entry_type_label
    {
      'REGULAR' => 'Regular Work',
      'BREAK' => 'Break',
      'OVERTIME' => 'Overtime'
    }[entry_type] || entry_type
  end
  
  # Entry type badge class
  def entry_type_badge_class
    {
      'REGULAR' => 'primary',
      'BREAK' => 'warning',
      'OVERTIME' => 'info'
    }[entry_type] || 'secondary'
  end
  
  private
  
  def clock_out_after_clock_in
    if clock_out_at.present? && clock_out_at <= clock_in_at
      errors.add(:clock_out_at, "must be after clock in time")
    end
  end
  
  def no_overlapping_entries_for_operator
    return unless clock_in_at.present?
    
    overlapping = LaborTimeEntry.non_deleted
                                 .where(operator_id: operator_id)
                                 .where.not(id: id)
                                 .where('clock_in_at <= ? AND (clock_out_at IS NULL OR clock_out_at >= ?)', 
                                        clock_in_at, clock_in_at)
    
    if overlapping.exists?
      errors.add(:base, "Operator already has an active time entry during this period")
    end
  end
  
  def update_operation_actual_time
    work_order_operation.recalculate_actual_time_from_labor_entries
  end
end

# ============================================================
# Model 17: location
# File: app/models/location.rb
# ============================================================

class Location < ApplicationRecord
  LOCATION_TYPES = %w[RAW_MATERIALS WIP FINISHED_GOODS QUARANTINE SCRAP STAGING GENERAL].freeze

  belongs_to :warehouse
  has_many :stock_issue_lines, foreign_key: :from_location_id
  
  # Soft delete flag
  scope :active, -> { where(deleted: false) }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :code, presence: true, length: { minimum: 2, maximum: 20 }

  # Code must be unique inside each warehouse
  validates :code, uniqueness: {
    scope: :warehouse_id,
    message: "must be unique inside the warehouse"
  }

  validates :is_pickable, inclusion: { in: [true, false] }
  validates :is_receivable, inclusion: { in: [true, false] }

  validates :location_type, inclusion: { in: LOCATION_TYPES }

  scope :raw_materials, -> { where(location_type: 'RAW_MATERIALS') }
  scope :finished_goods, -> { where(location_type: 'FINISHED_GOODS') }
end

# ============================================================
# Model 18: product
# File: app/models/product.rb
# ============================================================

class Product < ApplicationRecord
  belongs_to :product_category
  belongs_to :unit_of_measure
  has_many :bill_of_materials
  has_many :stock_issue_lines

  has_many :routings, dependent: :restrict_with_error
  has_one :default_routing, -> { where(is_default: true, deleted: false, status: 'ACTIVE') }, 
          class_name: 'Routing'

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :reorder_point, numericality: {greater_than_or_equal_to: 0, message: "cannot be negative"}

  PRODUCT_TYPE_CHOICES = [
    'Raw Material',
    'Semi-Finished Goods',
    'Finished Goods',
    'Service',
    'Consumable'
  ]

  scope :bom_products, -> {where(product_type: ["Finished Goods", "Semi-Finished Goods"])}
  scope :bom_item_components, -> {where(product_type: ['Raw Material', 'Service', 'Consumable'])}


  validates :product_type, presence: true, inclusion: { in: PRODUCT_TYPE_CHOICES }
  # validate :validate_inventory_account
  validate :validate_batch_tracking
  validate :validate_serial_batch_conflict

  def name_with_sku
    "#{self.sku} - #{self.name}"
  end
  
  def validate_inventory_account
    if self.is_stocked && self.inventory_account.blank?
      errors.add(:inventory_account, "Stocked product must have an inventory account")
    end
  end

  def validate_batch_tracking
    if self.is_batch_tracked && !self.is_stocked
      errors.add(:is_batch_tracked, "Batch tracking allowed only for stocked products")
    end
  end

  def validate_serial_batch_conflict
    if self.is_serial_tracked && self.is_batch_tracked
      errors.add(:is_serial_tracked, "Enable either serial OR batch tracking, not both")
    end
  end

  def in_use_bill_of_material
    self.bill_of_materials.find_by(is_default: true, status: 'ACTIVE')
  end

  # show standard cost only for specific types
  def requires_standard_cost?
    ['Raw Material', 'Service', 'Consumable'].include?(self.product_type)
  end

  def can_have_bom?
    ['Finished Goods', 'Semi-Finished Goods'].include?(self.product_type)
  end

  # ========================================
  # NEW METHODS FOR ROUTING INTEGRATION
  # ========================================
  
  # Check if product has a routing
  def has_routing?
    routings.where(deleted: false).exists?
  end
  
  # Get active routings
  def active_routings
    routings.where(deleted: false, status: 'ACTIVE')
  end
  
  # Calculate total production cost (BOM + Routing)
  def total_production_cost
    material_cost = standard_cost.to_d  # From BOM
    routing_cost = default_routing&.total_cost_per_unit.to_d || 0
    
    material_cost + routing_cost
  end
  
  # Calculate production time for a quantity
  def calculate_production_time(quantity = 1)
    return 0 unless default_routing.present?
    
    default_routing.calculate_total_time_for_batch(quantity)
  end
  
  # Get production lead time in days
  def production_lead_time_days(quantity = 1)
    minutes = calculate_production_time(quantity)
    hours = minutes / 60.0
    
    # Assuming 8-hour workday
    (hours / 8.0).ceil
  end
  
  # Check if product is ready for production
  def ready_for_production?
    has_bom = bill_of_materials.where(deleted: false, status: 'ACTIVE').exists?
    has_routing = routings.where(deleted: false, status: 'ACTIVE').exists?
    
    has_bom && has_routing
  end
  
  # Get production readiness status
  def production_readiness
    {
      has_bom: bill_of_materials.where(deleted: false, status: 'ACTIVE').exists?,
      has_routing: routings.where(deleted: false, status: 'ACTIVE').exists?,
      has_default_bom: bill_of_materials.where(deleted: false, is_default: true).exists?,
      has_default_routing: routings.where(deleted: false, is_default: true).exists?,
      ready: ready_for_production?
    }
  end
end

# ============================================================
# Model 19: product_category
# File: app/models/product_category.rb
# ============================================================

class ProductCategory < ApplicationRecord

  belongs_to :parent, class_name: "ProductCategory", optional: true
  has_many :children, class_name: "ProductCategory", foreign_key: "parent_id", dependent: :nullify

  validates_presence_of :name

  validate :cannot_be_its_own_parent

  def cannot_be_its_own_parent
    if parent_id.present? && self.parent == self
      errors.add(:parent_id, "cannot be the same as the category itself")
    end
  end
end

# ============================================================
# Model 20: product_supplier
# File: app/models/product_supplier.rb
# ============================================================

class ProductSupplier < ApplicationRecord
  belongs_to :product
  belongs_to :supplier
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  
  validates :product_id, uniqueness: { scope: :supplier_id }
  validates :current_unit_price, presence: true, numericality: { greater_than: 0 }
  validates :lead_time_days, presence: true, numericality: { greater_than: 0 }
  validates :minimum_order_quantity, numericality: { greater_than_or_equal_to: 1 }
  
  scope :active, -> { where(is_active: true) }
  scope :approved, -> { where(is_approved_supplier: true) }
  scope :preferred, -> { where(is_preferred_supplier: true) }
  scope :available, -> { where(available_for_order: true) }
  scope :by_price, -> { order(:current_unit_price) }
  scope :by_lead_time, -> { order(:lead_time_days) }
  scope :by_quality, -> { order(quality_rating: :desc) }
  scope :by_rank, -> { order(:supplier_rank) }
  
  # ============================================================================
  # VENDOR SELECTION LOGIC (FOR MRP!)
  # ============================================================================
  def selection_score(criteria = {})
    urgency = criteria[:urgency] || 'normal'
    
    case urgency.to_s.downcase
    when 'critical', 'urgent'
      # Speed is priority
      lead_time_score = (100 - lead_time_days * 2).clamp(0, 100)
      quality_weight = 0.3
      speed_weight = 0.5
      price_weight = 0.2
    when 'cost_sensitive'
      # Price is priority
      price_score = calculate_price_competitiveness
      quality_weight = 0.2
      speed_weight = 0.2
      price_weight = 0.6
    else
      # Balanced
      quality_weight = 0.4
      speed_weight = 0.3
      price_weight = 0.3
    end
    
    lead_time_score ||= (100 - lead_time_days * 2).clamp(0, 100)
    price_score ||= calculate_price_competitiveness
    
    (quality_rating * quality_weight) + (lead_time_score * speed_weight) + (price_score * price_weight)
  end
  
  def calculate_price_competitiveness
    # Compare with other suppliers for same product
    all_prices = product.product_suppliers.active.pluck(:current_unit_price)
    return 100 if all_prices.size <= 1
    
    min_price = all_prices.min
    max_price = all_prices.max
    range = max_price - min_price
    return 100 if range.zero?
    
    # Lower price = higher score
    ((max_price - current_unit_price) / range * 100).round(2)
  end
  
  def update_price!(new_price, effective_date = Date.current)
    self.previous_unit_price = current_unit_price
    self.current_unit_price = new_price
    self.price_effective_date = effective_date
    
    if previous_unit_price.present?
      change = ((new_price - previous_unit_price) / previous_unit_price * 100).round(2)
      self.price_change_percentage = change
      self.price_trend = change > 2 ? 'INCREASING' : (change < -2 ? 'DECREASING' : 'STABLE')
    end
    
    save!
  end
  
  def get_price_for_quantity(qty)
    return current_unit_price if qty < (price_break_1_qty || Float::INFINITY)
    return price_break_1_price if price_break_1_qty && qty >= price_break_1_qty && qty < (price_break_2_qty || Float::INFINITY)
    return price_break_2_price if price_break_2_qty && qty >= price_break_2_qty && qty < (price_break_3_qty || Float::INFINITY)
    return price_break_3_price if price_break_3_qty && qty >= price_break_3_qty
    current_unit_price
  end
  
  def record_purchase!(quantity, price, order_date = Date.current)
    self.last_purchase_date = order_date
    self.last_purchase_price = price
    self.last_purchase_quantity = quantity
    self.total_orders_count += 1
    self.total_quantity_purchased = (total_quantity_purchased || 0) + quantity
    self.total_value_purchased = (total_value_purchased || 0) + (quantity * price)
    self.average_purchase_price = total_value_purchased / total_quantity_purchased
    self.days_since_last_order = 0
    self.first_purchase_date ||= order_date
    save!
  end
end

# ============================================================
# Model 21: purchase_order
# File: app/models/purchase_order.rb
# ============================================================

class PurchaseOrder < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :supplier
  belongs_to :warehouse, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :confirmed_by, class_name: "User", optional: true
  belongs_to :closed_by, class_name: "User", optional: true
  
  has_many :lines,
           -> { where(deleted: false) },
           class_name: "PurchaseOrderLine",
           foreign_key: "purchase_order_id",
           dependent: :destroy,
           inverse_of: :purchase_order
           
  has_many :goods_receipts, dependent: :nullify
  
  accepts_nested_attributes_for :lines, allow_destroy: true
  
  # ===================================
  # CONSTANTS
  # ===================================
  STATUS_DRAFT              = 'DRAFT'
  STATUS_CONFIRMED          = 'CONFIRMED'
  STATUS_PARTIALLY_RECEIVED = 'PARTIALLY_RECEIVED'
  STATUS_RECEIVED           = 'RECEIVED'
  STATUS_CLOSED             = 'CLOSED'
  STATUS_CANCELLED          = 'CANCELLED'
  
  STATUSES = [
    STATUS_DRAFT,
    STATUS_CONFIRMED,
    STATUS_PARTIALLY_RECEIVED,
    STATUS_RECEIVED,
    STATUS_CLOSED,
    STATUS_CANCELLED
  ].freeze
  
  CURRENCIES = {
    'USD' => 'US Dollar',
    'CAD' => 'Canadian Dollar'
  }.freeze
  
  PAYMENT_TERMS = {
    'DUE_ON_RECEIPT' => 'Due on Receipt',
    'NET_15'         => 'Net 15',
    'NET_30'         => 'Net 30',
    'NET_45'         => 'Net 45',
    'NET_60'         => 'Net 60',
    'PREPAID'        => 'Prepaid'
  }.freeze
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :po_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :order_date, presence: true
  validates :supplier_id, presence: true
  validates :currency, inclusion: { in: CURRENCIES.keys }
  validates :payment_terms, inclusion: { in: PAYMENT_TERMS.keys }, allow_blank: true
  
  validate :must_have_lines_before_confirmation
  validate :expected_date_after_order_date
  validate :cannot_edit_if_not_draft
  
  # ===================================
  # SCOPES
  # ===================================
  scope :active, -> { where(deleted: false) }
  scope :draft, -> { where(status: STATUS_DRAFT, deleted: false) }
  scope :confirmed, -> { where(status: STATUS_CONFIRMED, deleted: false) }
  scope :open_pos, -> { 
    where(status: [STATUS_CONFIRMED, STATUS_PARTIALLY_RECEIVED], deleted: false) 
  }
  scope :by_supplier, ->(supplier_id) { where(supplier_id: supplier_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(order_date: :desc, created_at: :desc) }
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :generate_po_number
  before_validation :calculate_expected_date, if: :should_calculate_expected_date?
  before_save :recalculate_totals
  after_save :update_line_statuses, if: :saved_change_to_status?
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def can_edit?
    status == STATUS_DRAFT
  end
  
  def can_confirm?
    status == STATUS_DRAFT && lines.exists?
  end
  
  def can_cancel?
    [STATUS_DRAFT, STATUS_CONFIRMED].include?(status)
  end
  
  def can_close?
    status == STATUS_RECEIVED
  end
  
  def can_delete?
    status == STATUS_DRAFT
  end
  
  def can_receive?
    [STATUS_CONFIRMED, STATUS_PARTIALLY_RECEIVED].include?(status)
  end
  
  # Confirm PO - makes it official
  def confirm!(user:)
    raise "Cannot confirm - PO is not in DRAFT status" unless can_confirm?
    
    PurchaseOrder.transaction do
      update!(
        status: STATUS_CONFIRMED,
        confirmed_at: Date.current,
        confirmed_by: user
      )
      
      # Update all lines to OPEN status
      lines.update_all(line_status: 'OPEN')
    end
    
    true
  rescue => e
    errors.add(:base, "Confirmation failed: #{e.message}")
    false
  end
  
  # Cancel PO
  def cancel!(user:)
    raise "Cannot cancel - PO status is #{status}" unless can_cancel?
    
    update!(status: STATUS_CANCELLED)
  end
  
  # Close PO (all items received or no longer needed)
  def close!(user:)
    raise "Cannot close - PO status is #{status}" unless can_close?
    
    update!(
      status: STATUS_CLOSED,
      closed_at: Date.current,
      closed_by: user
    )
  end
  
  # Check if fully received
  def fully_received?
    lines.all? { |line| line.fully_received? }
  end
  
  # Check if partially received
  def partially_received?
    lines.any? { |line| line.received_qty > 0 }
  end
  
  # Update PO status based on line received quantities
  def update_receiving_status!
    return if status == STATUS_CLOSED || status == STATUS_CANCELLED
    
    if fully_received?
      update!(status: STATUS_RECEIVED)
    elsif partially_received?
      update!(status: STATUS_PARTIALLY_RECEIVED) if status == STATUS_CONFIRMED
    end
  end
  
  # Total lines
  def total_lines
    lines.count
  end
  
  # Total ordered quantity across all lines
  def total_ordered_qty
    lines.sum(:ordered_qty)
  end
  
  # Total received quantity
  def total_received_qty
    lines.sum(:received_qty)
  end
  
  # Receiving percentage
  def receiving_percentage
    return 0.0 if total_ordered_qty.zero?
    (total_received_qty / total_ordered_qty * 100).round(2)
  end
  
  # Outstanding (not yet received)
  def outstanding_qty
    total_ordered_qty - total_received_qty
  end

  def recalculate_totals
    self.subtotal = lines.sum(&:line_total_computed)
    self.tax_amount = lines.sum(&:tax_amount_computed)
    self.total_amount = subtotal + tax_amount + (shipping_cost || 0)
  end
  
  private
  
  def generate_po_number
    return if po_number.present?
    
    # Format: PO-YYYY-NNNN
    year = order_date.year
    
    # Find last PO number for this year
    last_po = PurchaseOrder.where("po_number LIKE ?", "PO-#{year}-%")
                          .order(po_number: :desc)
                          .first
    
    if last_po && last_po.po_number =~ /PO-#{year}-(\d+)/
      sequence = $1.to_i + 1
    else
      sequence = 1
    end
    
    self.po_number = "PO-#{year}-#{sequence.to_s.rjust(4, '0')}"
  end
  
  def should_calculate_expected_date?
    return false if expected_date.present?
    return false unless supplier.present?
    return false unless order_date.present?
    
    status == STATUS_CONFIRMED && confirmed_at.present?
  end
  
  def calculate_expected_date
    return unless supplier.present? && order_date.present?
    
    lead_time = supplier.lead_time_days || 7
    self.expected_date = order_date + lead_time.days
  end
  
  def update_line_statuses
    if status == STATUS_CANCELLED
      lines.update_all(line_status: 'CANCELLED')
    end
  end
  
  def must_have_lines_before_confirmation
    return unless status == STATUS_CONFIRMED
    
    if lines.where(deleted: false).empty?
      errors.add(:base, "Cannot confirm PO without any line items")
    end
  end
  
  def expected_date_after_order_date
    return if expected_date.blank? || order_date.blank?
    
    if expected_date < order_date
      errors.add(:expected_date, "cannot be before order date")
    end
  end
  
  def cannot_edit_if_not_draft
    return if new_record?
    return if status == STATUS_DRAFT
    
    if changed? && !%w[status received_qty].any? { |attr| changes.key?(attr) }
      errors.add(:base, "Cannot edit PO after confirmation")
    end
  end
end

# ============================================================
# Model 22: purchase_order_line
# File: app/models/purchase_order_line.rb
# ============================================================

class PurchaseOrderLine < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :purchase_order, inverse_of: :lines
  belongs_to :product
  belongs_to :uom, class_name: "UnitOfMeasure"
  belongs_to :tax_code, optional: true
  
  # ===================================
  # CONSTANTS
  # ===================================
  LINE_STATUS_OPEN              = 'OPEN'
  LINE_STATUS_PARTIALLY_RECEIVED = 'PARTIALLY_RECEIVED'
  LINE_STATUS_FULLY_RECEIVED    = 'FULLY_RECEIVED'
  LINE_STATUS_CANCELLED         = 'CANCELLED'
  
  LINE_STATUSES = [
    LINE_STATUS_OPEN,
    LINE_STATUS_PARTIALLY_RECEIVED,
    LINE_STATUS_FULLY_RECEIVED,
    LINE_STATUS_CANCELLED
  ].freeze
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :ordered_qty, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :received_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, presence: true
  validates :uom_id, presence: true
  validates :line_status, inclusion: { in: LINE_STATUSES }
  
  validate :received_qty_cannot_exceed_ordered
  validate :cannot_edit_if_po_not_draft
  validate :no_decimal_if_uom_disallows
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :set_default_uom, on: :create
  before_save :calculate_line_total
  before_save :calculate_tax_amount
  after_save :update_line_status_based_on_received_qty
  after_save :update_po_totals
  after_save :update_po_receiving_status
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def fully_received?
    received_qty >= ordered_qty
  end
  
  def partially_received?
    received_qty > 0 && received_qty < ordered_qty
  end
  
  def outstanding_qty
    ordered_qty - received_qty
  end
  
  def receiving_percentage
    return 0.0 if ordered_qty.zero?
    (received_qty / ordered_qty * 100).round(2)
  end
  
  # Receive quantity against this line
  def receive_qty!(qty:)
    new_received = received_qty + qty.to_d
    
    if new_received > ordered_qty
      raise "Cannot receive #{qty}. Only #{outstanding_qty} outstanding."
    end
    
    update!(received_qty: new_received)
  end
  
  # Computed values (for recalculation)
  def line_total_computed
    (ordered_qty.to_d * unit_price.to_d).round(2)
  end
  
  def tax_amount_computed
    return 0.0 unless tax_code.present?
    
    tax_rate_value = tax_code.rate || 0.to_d
    (line_total_computed * tax_rate_value).round(2)
  end
  
  private
  
  def set_default_uom
    return if uom_id.present?
    self.uom_id = product&.unit_of_measure_id
  end
  
  def calculate_line_total
    self.line_total = line_total_computed
  end
  
  def calculate_tax_amount
    if tax_code.present?
      self.tax_rate = tax_code.rate || 0.to_d
      self.tax_amount = tax_amount_computed
    else
      self.tax_rate = 0.to_d
      self.tax_amount = 0.to_d
    end
  end
  
  def update_line_status_based_on_received_qty
    return unless saved_change_to_received_qty?
    
    new_status = if fully_received?
                   LINE_STATUS_FULLY_RECEIVED
                 elsif partially_received?
                   LINE_STATUS_PARTIALLY_RECEIVED
                 else
                   LINE_STATUS_OPEN
                 end
    
    update_column(:line_status, new_status) if line_status != new_status
  end
  
  def update_po_totals
    purchase_order.recalculate_totals
    purchase_order.save if purchase_order.changed?
  end
  
  def update_po_receiving_status
    return unless saved_change_to_received_qty?
    purchase_order.update_receiving_status!
  end
  
  def received_qty_cannot_exceed_ordered
    return if received_qty.nil? || ordered_qty.nil?
    
    if received_qty > ordered_qty
      errors.add(:received_qty, "cannot exceed ordered quantity (#{ordered_qty})")
    end
  end
  
  def cannot_edit_if_po_not_draft
    return if purchase_order.nil?
    return if purchase_order.can_edit?
    
    # Allow updating received_qty even after confirmation
    return if only_received_qty_changed?
    
    if changed? && !new_record?
      errors.add(:base, "Cannot edit line after PO is confirmed")
    end
  end
  
  def only_received_qty_changed?
    changed? && changes.keys == ['received_qty']
  end
  
  def no_decimal_if_uom_disallows
    return if ordered_qty.blank? || uom.nil?
    return if uom.is_decimal?
    
    if ordered_qty.to_d != ordered_qty.to_i
      errors.add(:ordered_qty, "Decimal quantity not allowed for this Unit of Measure")
    end
  end
end

# ============================================================
# Model 23: rfq
# File: app/models/rfq.rb
# ============================================================

# frozen_string_literal: true

# ============================================================================
# MODEL: Rfq (Request for Quote)
# Complete RFQ management with vendor selection algorithm
# ============================================================================
class Rfq < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  # Line Items
  has_many :rfq_items, dependent: :destroy
  has_many :products, through: :rfq_items
  
  # Supplier Invitations
  has_many :rfq_suppliers, dependent: :destroy
  has_many :suppliers, through: :rfq_suppliers
  
  # Quotes
  has_many :vendor_quotes, dependent: :destroy
  
  # Awarded/Selected
  belongs_to :awarded_supplier, class_name: 'Supplier', optional: true
  belongs_to :recommended_supplier, class_name: 'Supplier', optional: true
  
  # Users
  belongs_to :created_by, class_name: 'User'
  belongs_to :requester, class_name: 'User', optional: true
  belongs_to :buyer_assigned, class_name: 'User', optional: true
  belongs_to :approver, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true
  
  # Future: Purchase Order
  # belongs_to :purchase_order, optional: true
  
  # ============================================================================
  # NESTED ATTRIBUTES
  # ============================================================================
  accepts_nested_attributes_for :rfq_items, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :rfq_suppliers, allow_destroy: true
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :rfq_number, presence: true, uniqueness: { case_sensitive: false }
  validates :title, presence: true, length: { maximum: 255 }
  validates :rfq_date, :due_date, :response_deadline, presence: true
  validates :status, presence: true, inclusion: { 
    in: %w[DRAFT SENT RESPONSES_RECEIVED UNDER_REVIEW AWARDED CLOSED CANCELLED],
    message: "%{value} is not a valid status"
  }
  validate :due_date_after_rfq_date
  validate :response_deadline_valid
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :generate_rfq_number, on: :create
  before_validation :set_defaults
  after_create :initialize_scoring_weights
  before_save :calculate_totals
  after_update :update_supplier_counts, if: :saved_change_to_status?

  before_save :set_items_line_numbers
  before_create :set_supplier_invited_date_stamps

  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :non_deleted, -> { where(is_deleted: false) }
  scope :active, -> { non_deleted.where.not(status: ['CLOSED', 'CANCELLED']) }
  scope :draft, -> { where(status: 'DRAFT') }
  scope :sent, -> { where(status: 'SENT') }
  scope :with_responses, -> { where(status: 'RESPONSES_RECEIVED') }
  scope :under_review, -> { where(status: 'UNDER_REVIEW') }
  scope :awarded, -> { where(status: 'AWARDED') }
  scope :closed, -> { where(status: 'CLOSED') }
  scope :urgent, -> { where(is_urgent: true) }
  scope :overdue, -> { where('response_deadline < ? AND status NOT IN (?)', Date.current, ['CLOSED', 'CANCELLED']) }
  scope :recent, -> { order(rfq_date: :desc) }
  scope :by_number, -> { order(rfq_number: :desc) }
  
  # ============================================================================
  # SERIALIZATION
  # ============================================================================
  store_accessor :scoring_weights, :price_weight, :delivery_weight, :quality_weight, :service_weight


  # ============================================================================
  # CLASS METHODS
  # ============================================================================


  def self.generate_next_number
    last_rfq = where("rfq_number LIKE 'RFQ-%'").order(rfq_number: :desc).first
    if last_rfq && last_rfq.rfq_number =~ /RFQ-(\d+)/
      next_number = $1.to_i + 1
    else
      next_number = 1
    end
    "RFQ-#{Date.current.strftime('%Y')}-#{next_number.to_s.rjust(5, '0')}"
  end
  
  def self.statuses
    %w[DRAFT SENT RESPONSES_RECEIVED UNDER_REVIEW AWARDED CLOSED CANCELLED]
  end
  
  def self.comparison_bases
    %w[PRICE_ONLY DELIVERY_WEIGHTED QUALITY_WEIGHTED BALANCED]
  end
  
  # ============================================================================
  # DISPLAY METHODS
  # ============================================================================
  def display_name
    "#{rfq_number} - #{title}"
  end
  
  def to_s
    display_name
  end
  
  def status_badge_class
    case status
    when 'DRAFT' then 'secondary'
    when 'SENT' then 'primary'
    when 'RESPONSES_RECEIVED' then 'info'
    when 'UNDER_REVIEW' then 'warning'
    when 'AWARDED' then 'success'
    when 'CLOSED' then 'dark'
    when 'CANCELLED' then 'danger'
    else 'secondary'
    end
  end
  
  # ============================================================================
  # STATUS WORKFLOW METHODS
  # ============================================================================
  def send_to_suppliers!(user = nil)
    # Validation
    raise "Cannot send RFQ without items" if rfq_items.empty?
    raise "Cannot send RFQ without suppliers" if rfq_suppliers.empty?
    raise "Cannot send RFQ that is not in DRAFT status" unless draft?
    
    # Update status
    self.status = 'SENT'
    self.sent_at = Time.current
    self.requester = user
    
    # Mark all suppliers as invited
    rfq_suppliers.each do |rfq_supplier|
      rfq_supplier.update!(
        invitation_status: 'INVITED',
        invited_at: Time.current,
        invited_by: user
      )
      
      # Send email notification if auto_email_enabled
      if auto_email_enabled?
        begin
          supplier = rfq_supplier.supplier
          contact = rfq_supplier.supplier_contact || supplier.primary_contact
          
          if contact && contact.email.present?
            # Send email asynchronously
            RfqMailer.rfq_notification(self, supplier, contact).deliver_now
            
            # Update email tracking
            rfq_supplier.update!(
              email_sent_at: Time.current,
              contact_email_used: contact.email
            )
            
            Rails.logger.info "RFQ #{rfq_number}: Email sent to #{supplier.display_name} (#{contact.email})"
          else
            Rails.logger.warn "RFQ #{rfq_number}: No email for supplier #{supplier.display_name}"
          end
        rescue => e
          Rails.logger.error "RFQ #{rfq_number}: Failed to send email to #{supplier.display_name}: #{e.message}"
          # Don't raise - continue with other suppliers
        end
      end
    end
    
    save!
    
    Rails.logger.info "RFQ #{rfq_number} sent to #{rfq_suppliers.count} suppliers"
    true
  end

  def send_reminders!(user = nil)
    return unless sent?
    
    # Find suppliers who haven't responded yet
    non_responding_suppliers = rfq_suppliers.where(invitation_status: ['INVITED', 'VIEWED'])
    
    non_responding_suppliers.each do |rfq_supplier|
      supplier = rfq_supplier.supplier
      contact = rfq_supplier.supplier_contact || supplier.primary_contact
      
      if contact && contact.email.present?
        begin
          RfqMailer.rfq_reminder(self, supplier, contact).deliver_now
          
          # Track reminder
          self.increment!(:reminder_count)
          self.update!(last_reminder_sent_at: Time.current)
          
          Rails.logger.info "RFQ #{rfq_number}: Reminder sent to #{supplier.display_name}"
        rescue => e
          Rails.logger.error "RFQ #{rfq_number}: Failed to send reminder to #{supplier.display_name}: #{e.message}"
        end
      end
    end
    
    true
  end
  
  def mark_response_received!(updated_by_user)
    update!(
      status: 'RESPONSES_RECEIVED',
      updated_by: updated_by_user
    ) if sent? && quotes_received_count > 0
  end
  
  def mark_under_review!(updated_by_user)
    update!(
      status: 'UNDER_REVIEW',
      updated_by: updated_by_user
    )
  end
  
  def award_to_supplier!(supplier, awarded_by_user, reason: nil)
    transaction do
      update!(
        status: 'AWARDED',
        awarded_supplier: supplier,
        award_date: Date.current,
        award_reason: reason,
        updated_by: awarded_by_user
      )
      
      # Mark supplier as selected
      rfq_suppliers.find_by(supplier: supplier)&.update!(is_selected: true, selected_date: Date.current)
      
      # Calculate awarded amount
      calculate_awarded_amount!
    end
  end
  
  def close!(closed_by_user, reason: nil)
    update!(
      status: 'CLOSED',
      closed_at: Time.current,
      internal_notes: [internal_notes, "Closed: #{reason}"].compact.join("\n"),
      updated_by: closed_by_user
    )
  end
  
  def cancel!(cancelled_by_user, reason: nil)
    update!(
      status: 'CANCELLED',
      internal_notes: [internal_notes, "Cancelled: #{reason}"].compact.join("\n"),
      updated_by: cancelled_by_user
    )
  end
  
  def draft?
    status == 'DRAFT'
  end
  
  def sent?
    status == 'SENT'
  end
  
  def can_be_sent?
    draft? && rfq_items.any? && rfq_suppliers.any?
  end
  
  def can_be_awarded?
    ['RESPONSES_RECEIVED', 'UNDER_REVIEW'].include?(status) && vendor_quotes.any?
  end
  
  # ============================================================================
  # SUPPLIER INVITATION METHODS
  # ============================================================================
  def invite_supplier!(supplier, invited_by_user, contact: nil)
    rfq_suppliers.create!(
      supplier: supplier,
      invited_by: invited_by_user,
      invited_at: Time.current,
      supplier_contact: contact || supplier.primary_contact,
      contact_email_used: (contact || supplier.primary_contact)&.email
    )
    
    increment!(:suppliers_invited_count)
  end
  
  def invite_multiple_suppliers!(supplier_ids, invited_by_user)
    supplier_ids.each do |supplier_id|
      supplier = Supplier.find(supplier_id)
      invite_supplier!(supplier, invited_by_user) unless rfq_suppliers.exists?(supplier_id: supplier_id)
    end
  end
  
  def remove_supplier!(supplier)
    rfq_suppliers.find_by(supplier: supplier)&.destroy
    decrement!(:suppliers_invited_count)
  end
  
  # ============================================================================
  # QUOTE MANAGEMENT METHODS
  # ============================================================================
  def record_quote_received!(rfq_supplier)
    increment!(:quotes_received_count)
    decrement!(:quotes_pending_count) if quotes_pending_count > 0
    
    rfq_supplier.update!(
      invitation_status: 'QUOTED',
      quoted_at: Time.current,
      response_time_hours: ((Time.current - rfq_supplier.invited_at) / 1.hour).to_i
    )
    
    mark_response_received!(updated_by) if quotes_received_count == suppliers_invited_count
  end
  
  def all_responses_received?
    quotes_received_count == suppliers_invited_count
  end
  
  def response_rate
    return 0 if suppliers_invited_count.zero?
    (quotes_received_count.to_f / suppliers_invited_count * 100).round(2)
  end
  
  # ============================================================================
  # COMPARISON & ANALYSIS METHODS
  # ============================================================================
  def calculate_quote_statistics!
    return if vendor_quotes.empty?
    
    amounts = vendor_quotes.group(:supplier_id).sum(:total_price).values
    
    update_columns(
      lowest_quote_amount: amounts.min,
      highest_quote_amount: amounts.max,
      average_quote_amount: (amounts.sum / amounts.size.to_f).round(2)
    )
  end
  
  def calculate_cost_savings!
    return unless awarded_total_amount && highest_quote_amount
    
    savings = highest_quote_amount - awarded_total_amount
    percentage = (savings / highest_quote_amount * 100).round(2)
    
    update_columns(
      cost_savings: savings,
      cost_savings_percentage: percentage
    )
  end
  
  # ============================================================================
  # SCORING & RECOMMENDATION ALGORITHM
  # ============================================================================
  def calculate_recommendations!
    return if vendor_quotes.empty?
    
    # Calculate scores for each quote
    vendor_quotes.includes(:supplier).find_each do |quote|
      quote.calculate_scores!(self)
    end
    
    # Find best overall score
    best_quote = vendor_quotes.order(overall_score: :desc).first
    
    if best_quote
      update!(
        recommended_supplier: best_quote.supplier,
        recommended_supplier_score: best_quote.overall_score
      )
      
      best_quote.update!(is_recommended: true)
    end
  end
  
  def weights
    {
      price: (price_weight || 40).to_f,
      delivery: (delivery_weight || 20).to_f,
      quality: (quality_weight || 25).to_f,
      service: (service_weight || 15).to_f
    }
  end
  
  def set_weights(price:, delivery:, quality:, service:)
    total = price + delivery + quality + service
    raise ArgumentError, "Weights must sum to 100" unless total == 100
    
    update!(
      scoring_weights: {
        price_weight: price,
        delivery_weight: delivery,
        quality_weight: quality,
        service_weight: service
      }
    )
  end
  
  # ============================================================================
  # COMPARISON VIEW
  # ============================================================================
  def comparison_matrix
    # Returns structured data for comparison dashboard
    items = rfq_items.includes(:product, vendor_quotes: :supplier).order(:line_number)
    
    items.map do |item|
      {
        item: item,
        quotes: item.vendor_quotes.includes(:supplier).order(:overall_rank).map do |quote|
          {
            supplier: quote.supplier,
            unit_price: quote.unit_price,
            total_price: quote.total_price,
            lead_time: quote.lead_time_days,
            total_cost: quote.total_cost,
            overall_score: quote.overall_score,
            is_lowest_price: quote.is_lowest_price,
            is_fastest_delivery: quote.is_fastest_delivery,
            is_best_value: quote.is_best_value,
            is_recommended: quote.is_recommended
          }
        end
      }
    end
  end
  
  # ============================================================================
  # ANALYTICS & REPORTING
  # ============================================================================
  def days_open
    if closed_at
      (closed_at.to_date - rfq_date).to_i
    else
      (Date.current - rfq_date).to_i
    end
  end
  
  def days_until_deadline
    (response_deadline - Date.current).to_i
  end
  
  def is_overdue?
    response_deadline < Date.current && !['CLOSED', 'CANCELLED'].include?(status)
  end
  
  def completion_percentage
    return 100 if closed? || awarded?
    return 0 if draft?
    
    steps = {
      'SENT' => 25,
      'RESPONSES_RECEIVED' => 50,
      'UNDER_REVIEW' => 75
    }
    
    steps[status] || 0
  end
  
  # ============================================================================
  # CONVERSION TO PO
  # ============================================================================
  def convert_to_purchase_order!(converted_by_user)
    # Will implement when PO module exists
    # Creates PO from awarded quotes
    transaction do
      # po = PurchaseOrder.create_from_rfq!(self, converted_by_user)
      update!(
        converted_to_po: true,
        po_created_date: Date.current
        # purchase_order: po
      )
      # po
    end
  end
  
  # ============================================================================
  # SOFT DELETE
  # ============================================================================
  def soft_delete!(deleted_by_user)
    update!(
      is_deleted: true,
      deleted_at: Time.current,
      deleted_by: deleted_by_user
    )
  end
  
  private
  
  # ============================================================================
  # PRIVATE CALLBACK METHODS
  # ============================================================================

  def set_items_line_numbers
    self.rfq_items.each_with_index do |item, i|
      item.line_number = (i+1)*10
    end
  end

  def set_supplier_invited_date_stamps
    self.rfq_suppliers.each do |rs| 
      rs.invited_at = DateTime.now
    end
    self.suppliers_invited_count = self.rfq_suppliers.length
  end  

  def generate_rfq_number
    self.rfq_number ||= self.class.generate_next_number
  end
  
  def set_defaults
    self.rfq_date ||= Date.current
    self.due_date ||= 14.days.from_now.to_date
    self.response_deadline ||= due_date
    self.status ||= 'DRAFT'
    self.priority ||= 'NORMAL'
  end
  
  def initialize_scoring_weights
    return if scoring_weights.present?
    
    self.scoring_weights = {
      price_weight: 40,
      delivery_weight: 20,
      quality_weight: 25,
      service_weight: 15
    }
    save if persisted?
  end
  
  def calculate_totals
    self.total_items_count = rfq_items.count
    self.total_quantity_requested = rfq_items.sum(:quantity_requested)
  end
  
  def update_supplier_counts
    self.suppliers_invited_count = rfq_suppliers.count
    self.quotes_pending_count = suppliers_invited_count - quotes_received_count
  end
  
  def calculate_awarded_amount!
    if awarded_supplier
      awarded_amount = vendor_quotes.where(supplier: awarded_supplier, is_selected: true).sum(:total_price)
      update_column(:awarded_total_amount, awarded_amount)
      calculate_cost_savings!
    end
  end
  
  def due_date_after_rfq_date
    return if rfq_date.blank? || due_date.blank?
    errors.add(:due_date, "must be after RFQ date") if due_date < rfq_date
  end
  
  def response_deadline_valid
    return if response_deadline.blank?
    errors.add(:response_deadline, "cannot be in the past") if response_deadline < Date.current && new_record?
  end
end

# ============================================================
# Model 24: rfq_item
# File: app/models/rfq_item.rb
# ============================================================

# frozen_string_literal: true

# ============================================================================
# ALL REMAINING RFQ MODELS
# Split into separate files during implementation
# ============================================================================

# ============================================================================
# MODEL: RfqItem
# ============================================================================
class RfqItem < ApplicationRecord
  belongs_to :rfq
  belongs_to :product
  belongs_to :selected_supplier, class_name: 'Supplier', optional: true
  belongs_to :last_purchased_from, class_name: 'Supplier', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  
  has_many :vendor_quotes, dependent: :destroy
  
  validates :line_number, presence: true, uniqueness: { scope: :rfq_id }
  validates :quantity_requested, presence: true, numericality: { greater_than: 0 }
  
  scope :critical, -> { where(is_critical_item: true) }
  scope :long_lead, -> { where(is_long_lead_item: true) }
  scope :by_line_number, -> { order(:line_number) }
  
  before_validation :set_line_number, on: :create
  before_save :calculate_target_total
  
  def display_name
     product&.name_with_sku.presence || item_description.presence
  end
  
  def calculate_quote_statistics!
    return if vendor_quotes.empty?
    
    prices = vendor_quotes.pluck(:unit_price)
    lead_times = vendor_quotes.pluck(:lead_time_days)
    
    update_columns(
      quotes_received_count: vendor_quotes.count,
      lowest_quoted_price: prices.min,
      highest_quoted_price: prices.max,
      average_quoted_price: (prices.sum / prices.size.to_f).round(4),
      best_delivery_days: lead_times.min
    )
  end
  
  def select_quote!(quote, selected_by_user, reason: nil)
    transaction do
      update!(
        selected_supplier: quote.supplier,
        selected_unit_price: quote.unit_price,
        selected_total_price: quote.total_price,
        selected_lead_time_days: quote.lead_time_days,
        selection_reason: reason
      )
      
      quote.update!(is_selected: true, selected_by: selected_by_user, selected_date: Date.current)
      calculate_variance!
    end
  end
  
  def calculate_variance!
    if selected_unit_price && target_unit_price
      variance = selected_unit_price - target_unit_price
      percentage = (variance / target_unit_price * 100).round(2)
      
      update_columns(
        price_variance_vs_target: variance * quantity_requested,
        price_variance_percentage: percentage
      )
    end
    
    if selected_unit_price && last_purchase_price
      variance = (selected_unit_price - last_purchase_price) * quantity_requested
      update_column(:price_variance_vs_last, variance)
    end
    
    if selected_total_price && highest_quoted_price
      savings = (highest_quoted_price - selected_unit_price) * quantity_requested
      update_column(:savings_vs_highest_quote, savings)
    end
  end
  
  private
  
  def set_line_number
    self.line_number ||= (rfq.rfq_items.maximum(:line_number) || 0) + 10
  end
  
  def calculate_target_total
    if target_unit_price && quantity_requested
      self.target_total_price = target_unit_price * quantity_requested
    end
  end
end


# ============================================================
# Model 25: rfq_supplier
# File: app/models/rfq_supplier.rb
# ============================================================

# ============================================================================
# MODEL: RfqSupplier (Join table with invitation tracking)
# ============================================================================
class RfqSupplier < ApplicationRecord
  belongs_to :rfq
  belongs_to :supplier
  belongs_to :supplier_contact, optional: true
  belongs_to :invited_by, class_name: 'User', optional: true
  
  has_many :vendor_quotes, dependent: :destroy
  
  validates :rfq_id, uniqueness: { scope: :supplier_id }
  
  scope :invited, -> { where(invitation_status: 'INVITED') }
  scope :quoted, -> { where(invitation_status: 'QUOTED') }
  scope :declined, -> { where(invitation_status: 'DECLINED') }
  scope :no_response, -> { where(invitation_status: 'NO_RESPONSE') }
  scope :selected, -> { where(is_selected: true) }
  
  def mark_quoted!
    update!(
      invitation_status: 'QUOTED',
      quoted_at: Time.current,
      response_time_hours: calculate_response_time
    )
    
    check_response_timeliness!
  end
  
  def mark_declined!(reason)
    update!(
      invitation_status: 'DECLINED',
      declined_at: Time.current,
      decline_reason: reason
    )
  end
  
  def mark_no_response!
    update!(invitation_status: 'NO_RESPONSE')
  end
  
  def calculate_response_time
    return nil unless invited_at
    ((Time.current - invited_at) / 1.hour).to_i
  end
  
  def check_response_timeliness!
    return unless rfq.response_deadline && quoted_at
    
    if quoted_at.to_date > rfq.response_deadline
      days_late = (quoted_at.to_date - rfq.response_deadline).to_i
      update!(responded_on_time: false, days_overdue: days_late)
    end
  end
  
  def calculate_quote_summary!
    quotes = vendor_quotes.where(is_latest_revision: true)
    
    update!(
      total_quoted_amount: quotes.sum(:total_price),
      items_quoted_count: quotes.count,
      items_not_quoted_count: rfq.rfq_items.count - quotes.count,
      quoted_all_items: quotes.count == rfq.rfq_items.count
    )
  end
end

# ============================================================
# Model 26: routing
# File: app/models/routing.rb
# ============================================================

# app/models/routing.rb

class Routing < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :product
  belongs_to :created_by, class_name: "User", optional: true
  
  has_many :routing_operations, -> { where(deleted: false).order(:operation_sequence) }, 
           dependent: :destroy,
           inverse_of: :routing
  
  accepts_nested_attributes_for :routing_operations, 
                                allow_destroy: true,
                                reject_if: :all_blank
  
  # ========================================
  # CONSTANTS
  # ========================================
  STATUS_CHOICES = %w[DRAFT ACTIVE INACTIVE ARCHIVED].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :code, presence: true, 
                   uniqueness: { case_sensitive: false },
                   length: { maximum: 20 }
  
  validates :name, presence: true, length: { maximum: 100 }
  
  validates :revision, length: { maximum: 16 }
  
  validates :status, presence: true, inclusion: { in: STATUS_CHOICES }
  
  validates :effective_from, presence: true
  
  validates :product_id, uniqueness: { 
    scope: :revision, 
    message: "already has a routing with this revision" 
  }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  validate :product_must_allow_routing
  validate :date_range_must_be_valid
  validate :only_one_default_per_product
  validate :default_routing_must_be_active
  validate :no_overlapping_active_ranges
  validate :active_routing_must_have_operations
  validate :archived_cannot_be_default
  validate :operation_sequences_must_be_unique
  
  def product_must_allow_routing
    allowed_types = ["Finished Goods", "Semi-Finished Goods"]
    
    unless allowed_types.include?(self.product.product_type)
      errors.add(:product_id, "can only have a routing if it is Finished or Semi-Finished Goods")
    end
  end
  
  def date_range_must_be_valid
    if effective_to.present? && effective_to < effective_from
      errors.add(:effective_to, "cannot be earlier than Effective From date")
    end
  end
  
  def only_one_default_per_product
    return unless is_default?
    conflict = Routing.where(deleted: false).where(product_id: product_id, is_default: true).where.not(id: id)
    
    if conflict.exists?
      errors.add(:is_default, "Only one default routing is allowed per product")
    end
  end
  
  def default_routing_must_be_active
    if is_default? && status != "ACTIVE"
      errors.add(:is_default, "Only an 'Active' routing can be set as default")
    end
  end
  
  def active_routing_must_have_operations
    return unless status == "ACTIVE"
    
    # Only one ACTIVE routing allowed per product
    if Routing.where(deleted: false)
              .where(product_id: product_id, status: "ACTIVE")
              .where.not(id: id)
              .exists?
      errors.add(:status, "Only one ACTIVE routing per product")
    end
    
    if routing_operations.empty?
      errors.add(:base, "An Active routing must contain at least one operation")
    end
  end
  
  def archived_cannot_be_default
    if status == "ARCHIVED" && is_default?
      errors.add(:is_default, "ARCHIVED routing cannot be marked as default")
    end
  end
  
  def no_overlapping_active_ranges
    return unless status == "ACTIVE"
    
    from = effective_from
    to   = effective_to || effective_from
    
    overlap_exists = Routing.where(deleted: false)
                            .where(product_id: product_id, status: "ACTIVE")
                            .where.not(id: id)
                            .where("effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)", to, from)
                            .exists?
    
    if overlap_exists
      errors.add(:base, "Another ACTIVE routing exists for this product within the same effective date range")
    end
  end
  
  def operation_sequences_must_be_unique
    sequences = routing_operations.reject(&:marked_for_destruction?).map(&:operation_sequence).compact
    
    if sequences.uniq.length != sequences.length
      errors.add(:base, "Operation sequences must be unique")
    end
  end
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :normalize_code
  before_save :handle_active_status
  before_save :ensure_single_default
  after_save :recalculate_totals
  
  def normalize_code
    self.code = code.to_s.upcase.strip if code.present?
  end
  
  def handle_active_status
    return unless status == "ACTIVE"
    
    # Archive other active routings
    Routing.where(deleted: false)
           .where(product_id: product_id, status: "ACTIVE")
           .where.not(id: id)
           .update_all(status: "ARCHIVED", is_default: false)
    
    # Auto-set default if not already
    self.is_default = true unless is_default?
  end
  
  def ensure_single_default
    return unless is_default?
    
    Routing.where(deleted: false)
           .where(product_id: product_id)
           .where.not(id: id)
           .update_all(is_default: false)
  end
  
  def recalculate_totals
    return if routing_operations.empty?
    
    setup_total = 0
    run_total = 0
    labor_cost_total = 0
    overhead_cost_total = 0
    
    routing_operations.where(deleted: false).each do |op|
      setup_total += op.setup_time_minutes.to_d
      run_total += op.run_time_per_unit_minutes.to_d
      labor_cost_total += op.labor_cost_per_unit.to_d
      overhead_cost_total += op.overhead_cost_per_unit.to_d
    end
    
    update_columns(
      total_setup_time_minutes: setup_total,
      total_run_time_per_unit_minutes: run_total,
      total_labor_cost_per_unit: labor_cost_total,
      total_overhead_cost_per_unit: overhead_cost_total
    )
  end
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(deleted: false, is_active: true) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_status, ->(status) { where(status: status) }
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Total cost per unit (labor + overhead)
  def total_cost_per_unit
    (total_labor_cost_per_unit.to_d + total_overhead_cost_per_unit.to_d).round(2)
  end
  
  # Calculate total time for a batch
  def calculate_total_time_for_batch(quantity)
    setup_time = total_setup_time_minutes.to_d
    run_time = total_run_time_per_unit_minutes.to_d * quantity
    
    setup_time + run_time
  end
  
  # Calculate total cost for a batch
  def calculate_total_cost_for_batch(quantity)
    # Setup costs (one-time)
    setup_costs = routing_operations.where(deleted: false).sum do |op|
      op.work_center.calculate_setup_cost(op.setup_time_minutes)
    end
    
    # Run costs (per unit × quantity)
    run_costs = total_cost_per_unit * quantity
    
    (setup_costs + run_costs).round(2)
  end
  
  # Get critical path (longest operation)
  def critical_operation
    routing_operations.where(deleted: false).max_by { |op| op.total_time_per_unit }
  end
  
  # Display name
  def display_name
    "#{code} - #{name}"
  end
  
  # Can be deleted?
  def can_be_deleted?
    # Future: check if used in production orders
    # production_orders.none?
    true
  end
  
  # Soft delete
  def destroy!
    if can_be_deleted?
      update_attribute(:deleted, true)
    else
      errors.add(:base, "Cannot delete routing that is being used in production orders")
      false
    end
  end
  
  # ========================================
  # CLASS METHODS
  # ========================================
  
  # Generate next code
  def self.generate_next_code
    last_routing = Routing.where("code LIKE 'RTG-%'")
                          .order(code: :desc)
                          .first
    
    if last_routing && last_routing.code =~ /RTG-(\d+)/
      next_number = $1.to_i + 1
      "RTG-#{next_number.to_s.rjust(4, '0')}"
    else
      "RTG-0001"
    end
  end
  
  # Get next operation sequence
  def next_operation_sequence
    last_seq = routing_operations.maximum(:operation_sequence) || 0
    last_seq + 10
  end
end

# ============================================================
# Model 27: routing_operation
# File: app/models/routing_operation.rb
# ============================================================

# app/models/routing_operation.rb

class RoutingOperation < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :routing, inverse_of: :routing_operations
  belongs_to :work_center
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :operation_sequence, presence: true,
                                 numericality: { only_integer: true, greater_than: 0 }
  
  validates :operation_name, presence: true, length: { maximum: 100 }
  
  validates :work_center_id, presence: true
  
  validates :setup_time_minutes,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :run_time_per_unit_minutes,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :wait_time_minutes,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :move_time_minutes,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :labor_hours_per_unit,
            numericality: { greater_than_or_equal_to: 0 }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  validate :work_center_must_be_active
  validate :sequence_must_be_unique_within_routing
  
  def work_center_must_be_active
    if work_center.present? && !work_center.is_active?
      errors.add(:work_center_id, "must be active")
    end
  end
  
  def sequence_must_be_unique_within_routing
    return if routing.blank? || operation_sequence.blank?
    
    duplicate = routing.routing_operations
                       .where(operation_sequence: operation_sequence)
                       .where(deleted: false)
                       .where.not(id: id)
    
    if duplicate.exists?
      errors.add(:operation_sequence, "already exists in this routing")
    end
  end
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_default_times
  before_save :calculate_costs
  after_save :update_routing_totals
  after_destroy :update_routing_totals
  
  def set_default_times
    if work_center.present?
      # If setup time not provided, use work center default
      self.setup_time_minutes ||= work_center.setup_time_minutes
      
      # If wait time not provided, use work center queue time
      self.wait_time_minutes ||= work_center.queue_time_minutes if wait_time_minutes.nil?
    end
  end
  
  def calculate_costs
    return unless work_center.present?
    
    # Calculate labor cost per unit
    # labor_hours_per_unit × work_center labor rate
    labor_hours = labor_hours_per_unit.to_d
    if labor_hours.zero?
      # If not specified, use run time as labor time
      labor_hours = run_time_per_unit_minutes.to_d / 60
    end
    
    self.labor_cost_per_unit = (labor_hours * work_center.labor_cost_per_hour).round(2)
    
    # Calculate overhead cost per unit
    # run_time (in hours) × overhead rate
    run_hours = run_time_per_unit_minutes.to_d / 60
    self.overhead_cost_per_unit = (run_hours * work_center.overhead_cost_per_hour).round(2)
  end
  
  def update_routing_totals
    routing.recalculate_totals if routing.present?
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Total time per unit (run + wait + move)
  def total_time_per_unit
    run_time_per_unit_minutes.to_d + 
    wait_time_minutes.to_d + 
    move_time_minutes.to_d
  end
  
  # Total time for a batch
  def calculate_total_time_for_batch(quantity)
    setup_time_minutes.to_d + 
    (run_time_per_unit_minutes.to_d * quantity) +
    wait_time_minutes.to_d +
    move_time_minutes.to_d
  end
  
  # Total cost per unit (labor + overhead)
  def total_cost_per_unit
    (labor_cost_per_unit.to_d + overhead_cost_per_unit.to_d).round(2)
  end
  
  # Calculate setup cost
  def calculate_setup_cost
    return 0 if work_center.blank?
    work_center.calculate_setup_cost(setup_time_minutes)
  end
  
  # Display name with sequence
  def display_name
    "#{operation_sequence} - #{operation_name}"
  end
  
  # Next operation in sequence
  def next_operation
    routing.routing_operations
           .where("operation_sequence > ?", operation_sequence)
           .where(deleted: false)
           .order(:operation_sequence)
           .first
  end
  
  # Previous operation in sequence
  def previous_operation
    routing.routing_operations
           .where("operation_sequence < ?", operation_sequence)
           .where(deleted: false)
           .order(operation_sequence: :desc)
           .first
  end
  
  # Is this the first operation?
  def first_operation?
    routing.routing_operations
           .where(deleted: false)
           .minimum(:operation_sequence) == operation_sequence
  end
  
  # Is this the last operation?
  def last_operation?
    routing.routing_operations
           .where(deleted: false)
           .maximum(:operation_sequence) == operation_sequence
  end
end

# ============================================================
# Model 28: stock_adjustment
# File: app/models/stock_adjustment.rb
# ============================================================

class StockAdjustment < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :warehouse
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :posted_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  
  has_many :lines,
           -> { where(deleted: false) },
           class_name: "StockAdjustmentLine",
           foreign_key: "stock_adjustment_id",
           dependent: :destroy, inverse_of: :stock_adjustment
           
  accepts_nested_attributes_for :lines, allow_destroy: true
  
  # ===================================
  # CONSTANTS
  # ===================================
  STATUS_DRAFT  = 'DRAFT'
  STATUS_POSTED = 'POSTED'
  STATUSES = [STATUS_DRAFT, STATUS_POSTED].freeze
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :reference_no, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :adjustment_date, presence: true
  validates :warehouse_id, presence: true
  validates :reason, presence: true, length: { minimum: 10, maximum: 1000 }
  
  validate :must_have_lines_before_posting
  validate :reason_must_be_meaningful
  
  # ===================================
  # SCOPES
  # ===================================
  scope :active, -> { where(deleted: false) }
  scope :draft, -> { where(status: STATUS_DRAFT, deleted: false) }
  scope :posted, -> { where(status: STATUS_POSTED, deleted: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  scope :recent, -> { order(adjustment_date: :desc, created_at: :desc) }
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :generate_reference_no, on: :create
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def can_post?
    status == STATUS_DRAFT && lines.exists?
  end
  
  def can_edit?
    status == STATUS_DRAFT
  end
  
  # Main posting method - creates stock transactions
  def post!(user:)
    raise "Cannot post - Adjustment is not in DRAFT status" unless can_post?
    
    StockAdjustment.transaction do
      lines.where(deleted: false).find_each do |line|
        delta = line.qty_delta.to_d
        
        # Skip zero adjustments
        next if delta.zero?
        
        # Determine transaction type based on positive/negative delta
        txn_type = delta > 0 ? "ADJUST_POS" : "ADJUST_NEG"
        
        # Create stock transaction
        # Note: quantity is always positive in StockTransaction
        StockTransaction.create!(
          product: line.product,
          uom: line.uom,
          txn_type: txn_type,
          quantity: delta.abs,  # Always positive quantity
          from_location: (delta < 0 ? line.location : nil),  # Source if negative
          to_location: (delta > 0 ? line.location : nil),    # Dest if positive
          batch: line.batch_if_applicable,
          reference_type: "ADJUSTMENT",
          reference_id: id.to_s,
          note: "Adjustment: #{reference_no} - #{line.line_reason || reason}",
          created_by: user
        )
      end
      
      # Update adjustment status
      update!(
        status: STATUS_POSTED,
        posted_at: Time.current,
        posted_by: user,
        approved_by: approved_by || user
      )
    end
    
    true
  rescue => e
    errors.add(:base, "Posting failed: #{e.message}")
    false
  end
  
  def total_lines
    lines.count
  end
  
  def total_positive_adjustments
    lines.where("qty_delta > 0").sum(:qty_delta)
  end
  
  def total_negative_adjustments
    lines.where("qty_delta < 0").sum(:qty_delta).abs
  end
  
  private
  
  def generate_reference_no
    return if reference_no.present?
    
    date_part = adjustment_date.strftime('%Y%m%d')
    random_part = SecureRandom.hex(3).upcase
    
    self.reference_no = "ADJ-#{date_part}-#{random_part}"
    
    # Ensure uniqueness
    counter = 1
    while StockAdjustment.where(reference_no: reference_no).exists?
      self.reference_no = "ADJ-#{date_part}-#{random_part}-#{counter}"
      counter += 1
    end
  end
  
  def must_have_lines_before_posting
    return unless status == STATUS_POSTED
    
    if lines.where(deleted: false).empty?
      errors.add(:base, "Cannot post adjustment without any line items")
    end
  end
  
  def reason_must_be_meaningful
    return if reason.blank?
    
    # Check if reason is too generic
    generic_reasons = ['adjustment', 'fix', 'update', 'change']
    if generic_reasons.any? { |word| reason.downcase.strip == word }
      errors.add(:reason, "must be more specific than '#{reason}'")
    end
  end
end

# ============================================================
# Model 29: stock_adjustment_line
# File: app/models/stock_adjustment_line.rb
# ============================================================

class StockAdjustmentLine < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :stock_adjustment, inverse_of: :lines
  belongs_to :product
  belongs_to :location
  belongs_to :batch, class_name: "StockBatch", optional: true
  belongs_to :uom, class_name: "UnitOfMeasure"
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :qty_delta, presence: true, numericality: { other_than: 0 }
  validates :product_id, presence: true
  validates :location_id, presence: true
  validates :uom_id, presence: true
  
  validate :location_must_belong_to_adjustment_warehouse
  validate :batch_rules
  validate :cannot_edit_if_posted
  validate :no_decimal_if_uom_disallows
  validate :negative_adjustment_cannot_exceed_available_stock
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :set_product_batch_if_batch_tracked
  before_validation :set_default_uom, on: :create
  before_validation :capture_system_qty, on: :create
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def batch_if_applicable
    product&.is_batch_tracked? ? batch : nil
  end
  
  def adjustment_type
    qty_delta.to_d > 0 ? "INCREASE" : "DECREASE"
  end
  
  def adjustment_amount
    qty_delta.abs
  end
  
  private
  
  def set_default_uom
    return if uom_id.present?
    self.uom_id = product&.unit_of_measure_id
  end
  
  def capture_system_qty
    return if product.nil? || location.nil?
    return if system_qty_at_adjustment.present?
    
    # Capture current stock level at time of creating adjustment
    stock_level = StockLevel.find_by(
      product: product,
      location: location,
      batch: batch_if_applicable
    )
    
    self.system_qty_at_adjustment = stock_level&.on_hand_qty || 0.to_d
  end
  
  def location_must_belong_to_adjustment_warehouse
    return if location.nil? || stock_adjustment.nil?
    
    if location.warehouse_id != stock_adjustment.warehouse_id
      errors.add(:location, "must belong to the adjustment's warehouse")
    end
  end
  
  def batch_rules
    return if product.nil?
    
    # If product is batch-tracked, batch is required
    if product.is_batch_tracked?
      if batch.nil?
        errors.add(:batch, "is required for batch-tracked products")
      elsif batch.product_id != product_id
        errors.add(:batch, "must belong to the selected product")
      end
    else
      # If product is NOT batch-tracked, batch must be blank
      if batch.present?
        errors.add(:batch, "must be blank for non batch-tracked products")
      end
    end
  end
  
  def cannot_edit_if_posted
    return if stock_adjustment.nil?
    
    if stock_adjustment.status == StockAdjustment::STATUS_POSTED && 
       (qty_delta_changed? || product_id_changed? || location_id_changed?)
      errors.add(:base, "Cannot modify line after adjustment is posted")
    end
  end
  
  def no_decimal_if_uom_disallows
    return if qty_delta.blank? || uom.nil?
    return if uom.is_decimal?
    
    if qty_delta.to_d != qty_delta.to_i
      errors.add(:qty_delta, "Decimal quantity not allowed for this Unit of Measure")
    end
  end
  
  def negative_adjustment_cannot_exceed_available_stock
    return unless qty_delta.to_d < 0
    return if product.nil? || location.nil?
    
    # Get current stock level
    stock_level = StockLevel.find_by(
      product: product,
      location: location,
      batch: batch_if_applicable
    )
    
    available = stock_level&.on_hand_qty || 0.to_d
    reduction = qty_delta.abs
    
    if reduction > available
      errors.add(:qty_delta, 
        "Cannot reduce by #{reduction}. Only #{available} available in stock."
      )
    end
  end
end

# ============================================================
# Model 30: stock_batch
# File: app/models/stock_batch.rb
# ============================================================

# app/models/stock_batch.rb

class StockBatch < ApplicationRecord
  # ============================================
  # ASSOCIATIONS
  # ============================================
  belongs_to :product
  belongs_to :created_by, class_name: "User", optional: true

  # Reverse associations
  has_many :stock_transactions, foreign_key: :batch_id, dependent: :restrict_with_error
  has_many :goods_receipt_lines, foreign_key: :batch_id, dependent: :restrict_with_error
  has_many :stock_issue_lines, foreign_key: :batch_id, dependent: :restrict_with_error
  has_many :stock_transfer_lines, foreign_key: :batch_id, dependent: :restrict_with_error
  has_many :stock_adjustment_lines, foreign_key: :batch_id, dependent: :restrict_with_error
  has_many :cycle_count_lines, foreign_key: :batch_id, dependent: :restrict_with_error
  has_many :stock_levels, foreign_key: :batch_id, dependent: :destroy

  # ============================================
  # VIRTUAL ATTRIBUTES
  # ============================================
  attr_accessor :current_stock

  # ============================================
  # VALIDATIONS - Basic
  # ============================================
  validates :batch_number, presence: true
  validates :batch_number, uniqueness: { 
    scope: :product_id, 
    message: "already exists for this product",
    case_sensitive: false
  }
  validates :batch_number, length: { maximum: 50 }
  validates :batch_number, format: { 
    with: /\A[A-Z0-9\-_]+\z/i, 
    message: "can only contain letters, numbers, hyphens, and underscores"
  }

  validates :product_id, presence: true

  # Quality status validation
  QUALITY_STATUS_CHOICES = %w[APPROVED PENDING REJECTED ON_HOLD QUARANTINE].freeze
  validates :quality_status, 
            inclusion: { in: QUALITY_STATUS_CHOICES, allow_blank: true }

  # String length validations
  validates :supplier_batch_ref, length: { maximum: 50 }, allow_blank: true
  validates :supplier_lot_number, length: { maximum: 50 }, allow_blank: true
  validates :certificate_number, length: { maximum: 50 }, allow_blank: true
  validates :notes, length: { maximum: 1000 }, allow_blank: true

  # ============================================
  # CUSTOM VALIDATIONS
  # ============================================
  validate :product_must_be_batch_tracked
  validate :expiry_date_must_be_after_manufacture_date
  validate :manufacture_date_cannot_be_future
  validate :expiry_date_cannot_be_past_on_creation
  validate :cannot_change_product_if_transactions_exist

  # ============================================
  # CALLBACKS
  # ============================================
  before_validation :normalize_batch_number
  before_validation :set_default_quality_status, on: :create
  after_save :update_stock_levels
  after_destroy :cleanup_stock_levels

  # ============================================
  # SCOPES
  # ============================================
  scope :non_deleted, -> { where(deleted: [nil, false]) }
  scope :active, -> { non_deleted.where('expiry_date IS NULL OR expiry_date >= ?', Date.today) }
  scope :expired, -> { non_deleted.where('expiry_date < ?', Date.today) }
  scope :expiring_soon, ->(days = 30) { 
    non_deleted.where('expiry_date BETWEEN ? AND ?', Date.today, Date.today + days.days) 
  }
  scope :with_stock, -> {
    non_deleted.joins(:stock_transactions)
      .group('stock_batches.id')
      .having('SUM(stock_transactions.quantity) > 0')
  }
  scope :without_stock, -> {
    non_deleted.left_joins(:stock_transactions)
      .group('stock_batches.id')
      .having('COALESCE(SUM(stock_transactions.quantity), 0) = 0')
  }
  scope :by_product, ->(product_id) { non_deleted.where(product_id: product_id) }
  scope :approved, -> { non_deleted.where(quality_status: 'APPROVED') }
  scope :pending_approval, -> { non_deleted.where(quality_status: 'PENDING') }

  # Order scopes
  scope :newest_first, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :by_batch_number, -> { order(:batch_number) }
  scope :by_expiry_date, -> { order(Arel.sql('expiry_date ASC NULLS LAST')) }

  # ============================================
  # CLASS METHODS
  # ============================================

  # Find batches with available stock for a product in a warehouse
  def self.available_for_product(product_id, warehouse_id = nil)
    batches = active.by_product(product_id).by_batch_number

    batches.select do |batch|
      stock = batch.current_stock_in_warehouse(warehouse_id)
      stock > 0
    end
  end

  # Get batches expiring within specified days
  def self.expiring_within(days)
    expiring_soon(days).order(:expiry_date)
  end

  # Get batches that need attention (expired or expiring soon)
  def self.needs_attention
    non_deleted.where('expiry_date IS NOT NULL')
      .where('expiry_date <= ?', Date.today + 30.days)
      .order(:expiry_date)
  end

  # Search batches
  def self.search(query)
    return non_deleted if query.blank?

    non_deleted.where(
      'batch_number ILIKE ? OR supplier_batch_ref ILIKE ? OR supplier_lot_number ILIKE ?',
      "%#{query}%", "%#{query}%", "%#{query}%"
    )
  end

  # Bulk import validation
  def self.validate_batch_number_uniqueness(batch_number, product_id, batch_id = nil)
    query = where(batch_number: batch_number, product_id: product_id)
    query = query.where.not(id: batch_id) if batch_id.present?
    !query.exists?
  end

  # ============================================
  # INSTANCE METHODS - Stock Calculations
  # ============================================

  # Get current stock across all locations
  def current_stock
    @current_stock ||= stock_transactions.sum(:quantity)
  end

  # Get current stock in specific warehouse
  def current_stock_in_warehouse(warehouse_id)
    return current_stock if warehouse_id.blank?

    stock_transactions
      .joins(:to_location)
      .where(locations: { warehouse_id: warehouse_id })
      .sum(:quantity)
  end

  # Get current stock in specific location
  def current_stock_in_location(location_id)
    stock_transactions
      .where(to_location_id: location_id)
      .sum(:quantity)
  end

  # Get stock breakdown by location
  def stock_by_location
    stock_transactions
      .joins(:to_location)
      .group('locations.id', 'locations.name')
      .select('locations.id, locations.name, SUM(stock_transactions.quantity) as quantity')
      .having('SUM(stock_transactions.quantity) > 0')
      .order('locations.name')
  end

  # Get stock breakdown by warehouse
  def stock_by_warehouse
    stock_transactions
      .joins(to_location: :warehouse)
      .group('warehouses.id', 'warehouses.name')
      .select('warehouses.id, warehouses.name, SUM(stock_transactions.quantity) as quantity')
      .having('SUM(stock_transactions.quantity) > 0')
      .order('warehouses.name')
  end

  # Check if batch has any stock
  def has_stock?
    current_stock > 0
  end

  # Check if batch has sufficient stock
  def sufficient_stock?(required_quantity, warehouse_id = nil)
    available = warehouse_id.present? ? 
                current_stock_in_warehouse(warehouse_id) : 
                current_stock
    available >= required_quantity
  end

  # ============================================
  # INSTANCE METHODS - Expiry Management
  # ============================================

  # Check if batch is expired
  def expired?
    expiry_date.present? && expiry_date < Date.today
  end

  # Check if batch is expiring soon (within 30 days)
  def expiring_soon?(days = 30)
    return false if expiry_date.blank?
    expiry_date.between?(Date.today, Date.today + days.days)
  end

  # Get days until expiry (negative if expired)
  def days_to_expiry
    return nil if expiry_date.blank?
    (expiry_date - Date.today).to_i
  end

  # Get expiry status
  def expiry_status
    return 'no_expiry' if expiry_date.blank?
    
    days = days_to_expiry
    return 'expired' if days < 0
    return 'expiring_soon' if days <= 30
    'active'
  end

  # Get expiry status with badge class
  def expiry_badge
    case expiry_status
    when 'expired'
      { text: 'Expired', class: 'bg-danger' }
    when 'expiring_soon'
      { text: 'Expiring Soon', class: 'bg-warning text-dark' }
    when 'active'
      { text: 'Active', class: 'bg-success' }
    else
      { text: 'No Expiry', class: 'bg-info' }
    end
  end

  # Get expiry message
  def expiry_message
    return 'No expiry date set' if expiry_date.blank?
    
    days = days_to_expiry
    if days < 0
      "Expired #{days.abs} day#{days.abs == 1 ? '' : 's'} ago"
    elsif days == 0
      "Expires today!"
    elsif days <= 30
      "Expires in #{days} day#{days == 1 ? '' : 's'}"
    else
      "Expires on #{expiry_date.strftime('%B %d, %Y')}"
    end
  end

  # Calculate shelf life percentage (how much time remaining vs total shelf life)
  def shelf_life_percentage
    return 100 if expiry_date.blank? || manufacture_date.blank?
    
    total_days = (expiry_date - manufacture_date).to_i
    return 0 if total_days <= 0
    
    remaining_days = days_to_expiry
    return 0 if remaining_days < 0
    
    ((remaining_days.to_f / total_days) * 100).round(2)
  end

  # ============================================
  # INSTANCE METHODS - Quality Management
  # ============================================

  # Check if batch is approved for use
  def approved?
    quality_status == 'APPROVED'
  end

  # Check if batch is pending approval
  def pending_approval?
    quality_status == 'PENDING'
  end

  # Check if batch is rejected
  def rejected?
    quality_status == 'REJECTED'
  end

  # Check if batch is on hold
  def on_hold?
    quality_status == 'ON_HOLD'
  end

  # Check if batch is in quarantine
  def quarantined?
    quality_status == 'QUARANTINE'
  end

  # Check if batch can be used in transactions
  def can_be_used?
    approved? && !expired? && has_stock?
  end

  # Get quality status badge
  def quality_badge
    case quality_status
    when 'APPROVED'
      { text: 'Approved', class: 'bg-success' }
    when 'PENDING'
      { text: 'Pending', class: 'bg-warning text-dark' }
    when 'REJECTED'
      { text: 'Rejected', class: 'bg-danger' }
    when 'ON_HOLD'
      { text: 'On Hold', class: 'bg-secondary' }
    when 'QUARANTINE'
      { text: 'Quarantine', class: 'bg-dark' }
    else
      { text: 'Not Set', class: 'bg-light text-dark' }
    end
  end

  # ============================================
  # INSTANCE METHODS - Transaction History
  # ============================================

  # Get recent transactions
  def recent_transactions(limit = 20)
    stock_transactions
      .order(transaction_date: :desc, created_at: :desc)
      .limit(limit)
      .includes(:created_by, :to_location)
  end

  # Get transactions by type
  def transactions_by_type(transaction_type)
    stock_transactions.where(transaction_type: transaction_type)
  end

  # Get first transaction (initial receipt)
  def first_transaction
    stock_transactions.order(:transaction_date, :created_at).first
  end

  # Get last transaction
  def last_transaction
    stock_transactions.order(:transaction_date, :created_at).last
  end

  # Calculate total received (positive transactions)
  def total_received
    stock_transactions.where('quantity > 0').sum(:quantity)
  end

  # Calculate total issued (negative transactions)
  def total_issued
    stock_transactions.where('quantity < 0').sum(:quantity).abs
  end

  # Get transaction summary
  def transaction_summary
    {
      total_transactions: stock_transactions.count,
      total_received: total_received,
      total_issued: total_issued,
      current_stock: current_stock,
      first_transaction_date: first_transaction&.transaction_date,
      last_transaction_date: last_transaction&.transaction_date
    }
  end

  # ============================================
  # INSTANCE METHODS - Utility
  # ============================================

  # Display name for dropdowns
  def display_name
    stock_info = has_stock? ? " (Stock: #{current_stock})" : " (No Stock)"
    expiry_info = expired? ? " [EXPIRED]" : (expiring_soon? ? " [Expiring Soon]" : "")
    "#{batch_number}#{stock_info}#{expiry_info}"
  end

  # Display name with product
  def full_display_name
    "#{product.code} - #{batch_number}"
  end

  # To string representation
  def to_s
    batch_number
  end

  # Check if batch can be deleted
  def can_be_deleted?
    !has_stock? && stock_transactions.empty?
  end

  # Get deletion block reason
  def deletion_blocked_reason
    return nil if can_be_deleted?
    
    if has_stock?
      "Batch has #{current_stock} units in stock"
    elsif stock_transactions.any?
      "Batch has transaction history (#{stock_transactions.count} transactions)"
    end
  end

  # Check if batch is editable
  def editable?
    # Can edit if no transactions or only manufacture/expiry dates
    stock_transactions.empty? || 
    stock_transactions.where.not(transaction_type: 'OPENING_BALANCE').empty?
  end

  # Get age of batch in days
  def age_in_days
    return nil if manufacture_date.blank?
    (Date.today - manufacture_date).to_i
  end

  # Generate QR code data (for printing labels)
  def qr_code_data
    {
      batch_number: batch_number,
      product_code: product.code,
      product_name: product.name,
      manufacture_date: manufacture_date&.iso8601,
      expiry_date: expiry_date&.iso8601,
      supplier_ref: supplier_batch_ref
    }.to_json
  end

  # ============================================
  # INSTANCE METHODS - Reporting
  # ============================================

  # Get batch metrics for dashboard
  def metrics
    {
      batch_number: batch_number,
      product_name: product.name,
      current_stock: current_stock,
      expiry_status: expiry_status,
      quality_status: quality_status,
      days_to_expiry: days_to_expiry,
      shelf_life_percentage: shelf_life_percentage,
      total_received: total_received,
      total_issued: total_issued,
      location_count: stock_by_location.count,
      first_received: first_transaction&.transaction_date,
      last_movement: last_transaction&.transaction_date
    }
  end

  # Export batch data
  def to_export_hash
    {
      'Batch Number' => batch_number,
      'Product Code' => product.code,
      'Product Name' => product.name,
      'Manufacture Date' => manufacture_date&.strftime('%Y-%m-%d'),
      'Expiry Date' => expiry_date&.strftime('%Y-%m-%d'),
      'Days to Expiry' => days_to_expiry,
      'Quality Status' => quality_status,
      'Supplier Batch Ref' => supplier_batch_ref,
      'Supplier Lot Number' => supplier_lot_number,
      'Certificate Number' => certificate_number,
      'Current Stock' => current_stock,
      'Total Received' => total_received,
      'Total Issued' => total_issued,
      'Created At' => created_at.strftime('%Y-%m-%d %H:%M'),
      'Created By' => created_by&.full_name || 'System'
    }
  end

  private

  # ============================================
  # VALIDATION METHODS
  # ============================================

  def product_must_be_batch_tracked
    return if product.nil?
    
    unless product.is_batch_tracked?
      errors.add(:product_id, "must be a batch-tracked product")
    end
  end

  def expiry_date_must_be_after_manufacture_date
    return if manufacture_date.blank? || expiry_date.blank?
    
    if expiry_date <= manufacture_date
      errors.add(:expiry_date, "must be after manufacture date")
    end
  end

  def manufacture_date_cannot_be_future
    return if manufacture_date.blank?
    
    if manufacture_date > Date.today
      errors.add(:manufacture_date, "cannot be in the future")
    end
  end

  def expiry_date_cannot_be_past_on_creation
    return if expiry_date.blank?
    return unless new_record?
    
    if expiry_date < Date.today
      errors.add(:expiry_date, "cannot be in the past when creating a new batch")
    end
  end

  def cannot_change_product_if_transactions_exist
    return if new_record?
    return unless product_id_changed?
    
    if stock_transactions.any?
      errors.add(:product_id, "cannot be changed as batch has transaction history")
    end
  end

  # ============================================
  # CALLBACK METHODS
  # ============================================

  def normalize_batch_number
    self.batch_number = batch_number.to_s.strip.upcase if batch_number.present?
  end

  def set_default_quality_status
    self.quality_status ||= 'PENDING'
  end

  def update_stock_levels
    # Update materialized view or cache if using
    # StockLevel.refresh_for_batch(self.id)
  end

  def cleanup_stock_levels
    # Clean up associated stock levels when batch is deleted
    stock_levels.destroy_all
  end
end

# ============================================================
# Model 31: stock_issue
# File: app/models/stock_issue.rb
# ============================================================

class StockIssue < ApplicationRecord
  belongs_to :warehouse
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :posted_by, class_name: "User", optional: true
  
  has_many :lines, 
           -> { where(deleted: false) },
           class_name: "StockIssueLine",
           foreign_key: "stock_issue_id",
           dependent: :destroy,
           inverse_of: :stock_issue
  accepts_nested_attributes_for :lines, allow_destroy: true

  STATUS_DRAFT  = 'DRAFT'
  STATUS_POSTED = 'POSTED'
  STATUSES = [STATUS_DRAFT, STATUS_POSTED].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :warehouse_id, presence: true

  before_validation :generate_reference_no

  scope :active, -> { where(deleted: false) }
  scope :draft, -> { where(status: STATUS_DRAFT, deleted: false) }
  scope :posted, -> { where(status: STATUS_POSTED, deleted: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }

  def can_post?
    status == STATUS_DRAFT && lines.exists?
  end
  
  def can_edit?
    status == STATUS_DRAFT
  end

  def posted?
    status == STATUS_POSTED
  end

  private

  def generate_reference_no
    self.reference_no ||= "ISS-#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end

# ============================================================
# Model 32: stock_issue_line
# File: app/models/stock_issue_line.rb
# ============================================================

class StockIssueLine < ApplicationRecord
  belongs_to :stock_issue, inverse_of: :lines
  belongs_to :product
  belongs_to :stock_batch, optional: true
  belongs_to :from_location, class_name: "Location"

  validates :quantity, numericality: { greater_than: 0 }

  validate :batch_required_if_tracked

  def batch_required_if_tracked
    return unless product

    if (product.is_batch_tracked || product.is_serial_tracked) && stock_batch_id.nil?
      errors.add(:stock_batch, "is required for this product")
    end
  end

  after_initialize do
    self.deleted ||= false
  end

  private

  def location_must_be_pickable
    if from_location && !from_location.is_pickable?
      errors.add(:from_location, "must be a pickable location")
    end
  end
end

# ============================================================
# Model 33: stock_level
# File: app/models/stock_level.rb
# ============================================================

class StockLevel < ApplicationRecord
  belongs_to :product
  belongs_to :location
  belongs_to :batch, class_name: "StockBatch", optional: true

  validates :on_hand_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :reserved_qty, numericality: { greater_than_or_equal_to: 0 }
  validate :reserved_not_more_than_on_hand

  def reserved_not_more_than_on_hand
    return if reserved_qty.blank? || on_hand_qty.blank?

    if reserved_qty > on_hand_qty
      errors.add(:reserved_qty, "cannot be greater than on-hand quantity")
    end
  end

  # Safely adjust on-hand quantity (called from StockTransaction)
  def self.adjust_on_hand(product:, location:, batch:, delta_qty:)
    transaction do
      level = StockLevel.lock.find_or_create_by(
        product: product,
        location: location,
        batch: batch
      ) do |l|
        l.on_hand_qty = 0.to_d
        l.reserved_qty = 0.to_d
        l.deleted = false
      end

      new_qty = (level.on_hand_qty || 0.to_d) + delta_qty.to_d
      if new_qty < 0
        level.errors.add(:on_hand_qty, "would become negative")
        raise ActiveRecord::RecordInvalid.new(level)
      end

      level.on_hand_qty = new_qty
      level.save!
      level
    end
  end

  def self.adjust_reserved(product:, location:, batch:, delta_qty:)
    transaction do
      level = StockLevel.lock.find_or_create_by(
        product: product,
        location: location,
        batch: batch
      ) do |l|
        l.on_hand_qty = 0.to_d
        l.reserved_qty = 0.to_d
        l.deleted = false
      end

      new_reserved = (level.reserved_qty || 0.to_d) + delta_qty.to_d
      if new_reserved < 0
        level.errors.add(:reserved_qty, "would become negative")
        raise ActiveRecord::RecordInvalid.new(level)
      end
      if new_reserved > level.on_hand_qty
        level.errors.add(:reserved_qty, "cannot exceed on-hand quantity")
        raise ActiveRecord::RecordInvalid.new(level)
      end

      level.reserved_qty = new_reserved
      level.save!
      level
    end
  end
end

# ============================================================
# Model 34: stock_transaction
# File: app/models/stock_transaction.rb
# ============================================================

class StockTransaction < ApplicationRecord
  belongs_to :product
  belongs_to :uom, class_name: "UnitOfMeasure"
  belongs_to :from_location, class_name: "Location", optional: true
  belongs_to :to_location, class_name: "Location", optional: true
  belongs_to :batch, class_name: "StockBatch", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  TXN_TYPES = [
    "RECEIPT",
    "ISSUE",
    "TRANSFER_OUT",
    "TRANSFER_IN",
    "ADJUST_POS",
    "ADJUST_NEG",
    "COUNT_CORRECTION",
    "PRODUCTION_CONSUMPTION",
    "PRODUCTION_OUTPUT",
    "PRODUCTION_RETURN",
    "RETURN_IN",
    "RETURN_OUT"
  ].freeze

  OUTFLOW_TYPES = %w[
    ISSUE
    TRANSFER_OUT
    ADJUST_NEG
    COUNT_CORRECTION
    PRODUCTION_CONSUMPTION
    PRODUCTION_RETURN
    RETURN_OUT
  ].freeze

  INFLOW_TYPES = %w[
    RECEIPT
    TRANSFER_IN
    ADJUST_POS
    COUNT_CORRECTION
    PRODUCTION_OUTPUT
    RETURN_IN
  ].freeze

  validates :txn_type, presence: true, inclusion: { in: TXN_TYPES }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :uom, presence: true

  validate :batch_rules
  validate :location_rules

  after_create :apply_stock_movement

  def outflow?
    OUTFLOW_TYPES.include?(txn_type)
  end

  def inflow?
    INFLOW_TYPES.include?(txn_type)
  end

  private

  def batch_rules
    if product&.is_batch_tracked?
      errors.add(:batch, "is required for batch-tracked products") if batch.nil?
    else
      errors.add(:batch, "must be blank for non batch-tracked products") if batch.present?
    end
  end

  def location_rules
    if outflow? && from_location.nil?
      errors.add(:from_location, "is required for outflow transactions")
    end

    if inflow? && to_location.nil?
      errors.add(:to_location, "is required for inflow transactions")
    end

    if %w[TRANSFER_IN TRANSFER_OUT].include?(txn_type)
      if from_location.present? && to_location.present? && from_location_id == to_location_id
        errors.add(:base, "From and To locations cannot be the same for transfers")
      end
    end
  end

  def batch_for_level
    product&.is_batch_tracked? ? batch : nil
  end

  def apply_stock_movement
    qty = quantity.to_d

    if outflow? && from_location.present?
      StockLevel.adjust_on_hand(
        product: product,
        location: from_location,
        batch: batch_for_level,
        delta_qty: -qty
      )
    end

    if inflow? && to_location.present?
      StockLevel.adjust_on_hand(
        product: product,
        location: to_location,
        batch: batch_for_level,
        delta_qty: qty
      )
    end
  end
end

# ============================================================
# Model 35: stock_transfer
# File: app/models/stock_transfer.rb
# ============================================================

class StockTransfer < ApplicationRecord
  STATUS_DRAFT     = "DRAFT"
  STATUS_POSTED    = "POSTED"
  STATUS_CANCELLED = "CANCELLED"

  STATUSES = [STATUS_DRAFT, STATUS_POSTED, STATUS_CANCELLED].freeze

  belongs_to :from_warehouse, class_name: "Warehouse"
  belongs_to :to_warehouse, class_name: "Warehouse"
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :posted_by, class_name: "User", optional: true

  has_many :lines,
           class_name: "StockTransferLine",
           dependent: :destroy,
           inverse_of: :stock_transfer

  accepts_nested_attributes_for :lines, allow_destroy: true

  validates :transfer_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :different_warehouses

  scope :active, -> { where(deleted: false) }
  scope :draft, -> { where(status: STATUS_DRAFT, deleted: false) }
  scope :cancelled, -> { where(status: STATUS_CANCELLED, deleted: false) }
  scope :posted, -> { where(status: STATUS_POSTED, deleted: false) }

  before_validation :generate_transfer_no
  def different_warehouses
    if from_warehouse_id.present? && to_warehouse_id.present? &&
       from_warehouse_id == to_warehouse_id
      errors.add(:base, "From and To warehouse cannot be the same")
    end
  end

  def can_edit?
    status == STATUS_DRAFT
  end

  def posted?
    status == STATUS_POSTED
  end
  
  def can_post?
    status == STATUS_DRAFT && lines.where(deleted: false).exists?
  end

  def post!(user:)
    raise "Cannot post this transfer" unless can_post?

    StockTransfer.transaction do
      lines.where(deleted: false).find_each do |line|
        # OUT
        StockTransaction.create!(
          product: line.product,
          uom: line.uom,
          txn_type: "TRANSFER_OUT",
          quantity: line.qty,
          from_location: line.from_location,
          to_location: nil,
          batch: line.batch_if_applicable,
          reference_type: "STOCK_TRANSFER",
          reference_id: id.to_s,
          note: line.line_note,
          created_by: user
        )

        # IN
        StockTransaction.create!(
          product: line.product,
          uom: line.uom,
          txn_type: "TRANSFER_IN",
          quantity: line.qty,
          from_location: nil,
          to_location: line.to_location,
          batch: line.batch_if_applicable,
          reference_type: "STOCK_TRANSFER",
          reference_id: id.to_s,
          note: line.line_note,
          created_by: user
        )
      end

      update!(
        status: STATUS_POSTED,
        approved_by: approved_by || user,
        posted_at: DateTime.now
      )
    end
  end

  private

  def generate_transfer_no
    self.transfer_number ||= "STR-#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end

# ============================================================
# Model 36: stock_transfer_line
# File: app/models/stock_transfer_line.rb
# ============================================================

class StockTransferLine < ApplicationRecord
  belongs_to :stock_transfer, inverse_of: :lines
  belongs_to :product
  belongs_to :uom, class_name: "UnitOfMeasure"
  belongs_to :from_location, class_name: "Location"
  belongs_to :to_location, class_name: "Location"
  belongs_to :batch, class_name: "StockBatch", optional: true

  validates :qty, numericality: { greater_than: 0 }
  validate :locations_match_warehouses
  validate :different_locations
  validate :batch_rules

  def locations_match_warehouses
    return if from_location.blank? || to_location.blank? || stock_transfer.blank?

    if from_location.warehouse_id != stock_transfer.from_warehouse_id
      errors.add(:from_location, "does not belong to the source warehouse")
    end

    if to_location.warehouse_id != stock_transfer.to_warehouse_id
      errors.add(:to_location, "does not belong to the destination warehouse")
    end
  end

  def different_locations
    if from_location_id.present? && to_location_id.present? &&
       from_location_id == to_location_id
      errors.add(:base, "From and To location cannot be the same")
    end
  end

  def batch_rules
    return if product.nil?

    if product.is_batch_tracked? && batch.nil?
      errors.add(:batch, "is required for batch-tracked products")
    end

    if !product.is_batch_tracked? && batch.present?
      errors.add(:batch, "must be blank for non batch-tracked products")
    end
  end

  def batch_if_applicable
    product&.is_batch_tracked? ? batch : nil
  end
end

# ============================================================
# Model 37: supplier
# File: app/models/supplier.rb
# ============================================================

# frozen_string_literal: true

# ============================================================================
# MODEL: Supplier
# Core supplier/vendor management with performance tracking and rating system
# ============================================================================
class Supplier < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  # Related Models
  has_many :addresses, class_name: 'SupplierAddress', dependent: :destroy
  has_many :contacts, class_name: 'SupplierContact', dependent: :destroy
  has_many :documents, class_name: 'SupplierDocument', dependent: :destroy
  has_many :quality_issues, class_name: 'SupplierQualityIssue', dependent: :destroy
  has_many :activities, class_name: 'SupplierActivity', dependent: :destroy
  has_many :performance_reviews, class_name: 'SupplierPerformanceReview', dependent: :destroy
  
  # Product Catalog (many-to-many)
  has_many :product_suppliers, dependent: :destroy
  has_many :products, through: :product_suppliers
  
  # Purchase Orders (will add when PO module exists)
  # has_many :purchase_orders, dependent: :restrict_with_error
  
  # User References
  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :default_buyer, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true
  
  # ============================================================================
  # NESTED ATTRIBUTES
  # ============================================================================
  accepts_nested_attributes_for :addresses, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :contacts, allow_destroy: true, reject_if: :all_blank
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :code, presence: true, uniqueness: { case_sensitive: false, conditions: -> { where(is_deleted: false) } }
  validates :legal_name, presence: true, length: { maximum: 255 }
  validates :supplier_type, presence: true, inclusion: { 
    in: %w[MANUFACTURER DISTRIBUTOR SERVICE_PROVIDER TRADER IMPORTER],
    message: "%{value} is not a valid supplier type"
  }
  validates :supplier_status, presence: true, inclusion: { 
    in: %w[PENDING APPROVED SUSPENDED BLACKLISTED INACTIVE],
    message: "%{value} is not a valid status"
  }
  validates :currency, presence: true, inclusion: { in: %w[USD CAD EUR GBP MXN], message: "%{value} is not supported" }
  validates :primary_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  
  # Financial validations
  validates :credit_limit_extended, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :current_payable_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :early_payment_discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :tax_withholding_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  
  # Rating validations
  validates :overall_rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :quality_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :delivery_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :price_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :generate_code, on: :create
  before_validation :set_display_name
  before_validation :normalize_fields
  before_save :calculate_rating_label
  after_create :log_creation
  after_update :log_status_change, if: :saved_change_to_supplier_status?
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  # Status Scopes
  scope :non_deleted, -> { where(is_deleted: false) }
  scope :active, -> { non_deleted.where(is_active: true) }
  scope :inactive, -> { non_deleted.where(is_active: false) }
  scope :approved, -> { non_deleted.where(supplier_status: 'APPROVED') }
  scope :pending, -> { non_deleted.where(supplier_status: 'PENDING') }
  scope :suspended, -> { non_deleted.where(supplier_status: 'SUSPENDED') }
  scope :blacklisted, -> { non_deleted.where(supplier_status: 'BLACKLISTED') }
  
  # Type Scopes
  scope :manufacturers, -> { where(supplier_type: 'MANUFACTURER') }
  scope :distributors, -> { where(supplier_type: 'DISTRIBUTOR') }
  scope :service_providers, -> { where(supplier_type: 'SERVICE_PROVIDER') }
  
  # Category Scopes
  scope :raw_material_suppliers, -> { where(supplier_category: 'RAW_MATERIAL') }
  scope :component_suppliers, -> { where(supplier_category: 'COMPONENTS') }
  scope :packaging_suppliers, -> { where(supplier_category: 'PACKAGING') }
  
  # Strategic Scopes
  scope :preferred, -> { where(is_preferred_supplier: true) }
  scope :strategic, -> { where(is_strategic_supplier: true) }
  scope :local, -> { where(is_local_supplier: true) }
  scope :minority_owned, -> { where(is_minority_owned: true) }
  scope :woman_owned, -> { where(is_woman_owned: true) }
  
  # Performance Scopes
  scope :high_rated, -> { where('overall_rating >= ?', 80) }
  scope :medium_rated, -> { where('overall_rating >= ? AND overall_rating < ?', 60, 80) }
  scope :low_rated, -> { where('overall_rating < ?', 60) }
  scope :excellent, -> { where(rating_label: 'EXCELLENT') }
  scope :good, -> { where(rating_label: 'GOOD') }
  
  # Can Receive Scopes
  scope :can_receive_pos, -> { where(can_receive_pos: true) }
  scope :can_receive_rfqs, -> { where(can_receive_rfqs: true) }
  
  # Ordering
  scope :by_name, -> { order(:legal_name) }
  scope :by_rating, -> { order(overall_rating: :desc) }
  scope :by_total_spend, -> { order(total_purchase_value: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Search
  scope :search, ->(term) {
    return all if term.blank?
    where('legal_name ILIKE ? OR trade_name ILIKE ? OR code ILIKE ? OR primary_email ILIKE ?',
          "%#{term}%", "%#{term}%", "%#{term}%", "%#{term}%")
  }
  
  # ============================================================================
  # SERIALIZATION
  # ============================================================================
  serialize :manufacturing_processes, type: Array, coder: JSON
  serialize :quality_control_capabilities, type: Array, coder: JSON
  serialize :testing_capabilities, type: Array, coder: JSON
  serialize :materials_specialization, type: Array, coder: JSON
  serialize :geographic_coverage, type: Array, coder: JSON
  serialize :factory_locations, type: Array, coder: JSON
  serialize :certifications, type: Array, coder: JSON
  serialize :risk_factors, type: Array, coder: JSON
  
  # ============================================================================
  # CLASS METHODS
  # ============================================================================
  def self.generate_next_code
    last_supplier = where("code LIKE 'SUP-%'").order(code: :desc).first
    if last_supplier && last_supplier.code =~ /SUP-(\d+)/
      next_number = $1.to_i + 1
    else
      next_number = 1
    end
    "SUP-#{next_number.to_s.rjust(5, '0')}"
  end
  
  def self.rating_labels
    %w[EXCELLENT GOOD FAIR POOR CRITICAL]
  end
  
  def self.supplier_types
    %w[MANUFACTURER DISTRIBUTOR SERVICE_PROVIDER TRADER IMPORTER]
  end
  
  def self.supplier_categories
    %w[RAW_MATERIAL COMPONENTS PACKAGING SERVICES MRO CAPITAL_EQUIPMENT]
  end
  
  def self.supplier_statuses
    %w[PENDING APPROVED SUSPENDED BLACKLISTED INACTIVE]
  end
  
  # ============================================================================
  # DISPLAY METHODS
  # ============================================================================
  def display_name
    trade_name.presence || legal_name
  end
  
  def full_display_name
    "#{display_name} (#{code})"
  end
  
  def to_s
    full_display_name
  end
  
  # ============================================================================
  # STATUS MANAGEMENT
  # ============================================================================
  def approve!(approved_by_user, notes: nil)
    update!(
      supplier_status: 'APPROVED',
      approved_date: Date.current,
      approved_by: approved_by_user,
      status_effective_date: Date.current,
      status_reason: notes
    )
  end
  
  def suspend!(reason, suspended_by_user)
    update!(
      supplier_status: 'SUSPENDED',
      status_reason: reason,
      status_effective_date: Date.current,
      can_receive_pos: false,
      updated_by: suspended_by_user
    )
  end
  
  def blacklist!(reason, blacklisted_by_user)
    update!(
      supplier_status: 'BLACKLISTED',
      status_reason: reason,
      status_effective_date: Date.current,
      can_receive_pos: false,
      can_receive_rfqs: false,
      is_active: false,
      updated_by: blacklisted_by_user
    )
  end
  
  def reactivate!(reactivated_by_user, notes: nil)
    update!(
      supplier_status: 'APPROVED',
      status_reason: notes,
      status_effective_date: Date.current,
      can_receive_pos: true,
      can_receive_rfqs: true,
      is_active: true,
      updated_by: reactivated_by_user
    )
  end
  
  def approved?
    supplier_status == 'APPROVED'
  end
  
  def pending_approval?
    supplier_status == 'PENDING'
  end
  
  def suspended?
    supplier_status == 'SUSPENDED'
  end
  
  def blacklisted?
    supplier_status == 'BLACKLISTED'
  end
  
  # ============================================================================
  # RATING & PERFORMANCE METHODS
  # ============================================================================
  def calculate_overall_rating!
    # Weighted calculation: Quality 30%, Delivery 40%, Price 30%
    new_rating = (quality_score * 0.30) + (delivery_score * 0.40) + (price_score * 0.30)
    update_columns(
      overall_rating: new_rating.round(2),
      rating_last_calculated_at: Time.current
    )
    calculate_rating_label
    save if changed?
  end
  
  def rating_label
    case overall_rating
    when 90..100 then 'EXCELLENT'
    when 75..89 then 'GOOD'
    when 60..74 then 'FAIR'
    when 40..59 then 'POOR'
    else 'CRITICAL'
    end
  end
  
  def rating_badge_class
    case rating_label
    when 'EXCELLENT' then 'success'
    when 'GOOD' then 'primary'
    when 'FAIR' then 'warning'
    when 'POOR' then 'danger'
    when 'CRITICAL' then 'dark'
    end
  end
  
  def status_badge_class
    case supplier_status
    when 'APPROVED' then 'success'
    when 'PENDING' then 'warning'
    when 'SUSPENDED' then 'danger'
    when 'BLACKLISTED' then 'dark'
    when 'INACTIVE' then 'secondary'
    end
  end
  
  # ============================================================================
  # FINANCIAL METHODS
  # ============================================================================
  def available_credit
    credit_limit_extended - current_payable_balance
  end
  
  def credit_utilization_percentage
    return 0 if credit_limit_extended.zero?
    (current_payable_balance / credit_limit_extended * 100).round(2)
  end
  
  def over_credit_limit?
    current_payable_balance > credit_limit_extended
  end
  
  def can_extend_credit?(amount)
    (current_payable_balance + amount) <= credit_limit_extended
  end
  
  def update_payable_balance!
    # Calculate from purchase orders/invoices when those modules exist
    # self.current_payable_balance = purchase_orders.unpaid.sum(:total_amount)
    # save
  end
  
  # ============================================================================
  # PERFORMANCE TRACKING METHODS
  # ============================================================================
  def update_performance_metrics!
    # Will be called after each PO receipt/delivery
    calculate_delivery_performance!
    calculate_quality_performance!
    calculate_order_statistics!
    calculate_overall_rating!
  end
  
  def calculate_delivery_performance!
    # Logic when PO module exists
    # total_deliveries = purchase_order_receipts.count
    # on_time = purchase_order_receipts.on_time.count
    # late = purchase_order_receipts.late.count
    # self.on_time_delivery_rate = (on_time.to_f / total_deliveries * 100).round(2)
    # self.late_deliveries_count = late
    # Calculate delivery_score
  end
  
  def calculate_quality_performance!
    total_issues = quality_issues.count
    critical_issues = quality_issues.where(severity: 'CRITICAL').count
    
    # Quality score calculation
    base_score = 100
    deduction = (critical_issues * 10) + ((total_issues - critical_issues) * 2)
    self.quality_score = [base_score - deduction, 0].max
    self.quality_issues_count = total_issues
  end
  
  def calculate_order_statistics!
    # Will calculate from PO data when available
    # self.total_po_count = purchase_orders.count
    # self.total_purchase_value = purchase_orders.sum(:total_amount)
    # etc.
  end
  
  # ============================================================================
  # PRODUCT CATALOG METHODS
  # ============================================================================
  def supplies_product?(product)
    product_suppliers.where(product: product, is_active: true).exists?
  end
  
  def add_product(product, attributes = {})
    product_suppliers.create!(
      product: product,
      current_unit_price: attributes[:unit_price],
      lead_time_days: attributes[:lead_time_days] || default_lead_time_days,
      minimum_order_quantity: attributes[:moq] || minimum_order_quantity,
      **attributes
    )
  end
  
  def remove_product(product)
    product_suppliers.where(product: product).destroy_all
  end
  
  def product_catalog
    product_suppliers.includes(:product).where(is_active: true)
  end
  
  def preferred_products
    product_suppliers.where(is_preferred_supplier: true, is_active: true)
  end
  
  def get_product_price(product)
    product_suppliers.find_by(product: product, is_active: true)&.current_unit_price
  end
  
  def get_product_lead_time(product)
    product_suppliers.find_by(product: product, is_active: true)&.lead_time_days || default_lead_time_days
  end
  
  # ============================================================================
  # QUALITY ISSUE METHODS
  # ============================================================================
  def log_quality_issue!(attributes)
    quality_issues.create!(attributes)
    calculate_quality_performance!
    calculate_overall_rating!
  end
  
  def open_quality_issues
    quality_issues.where(status: 'OPEN')
  end
  
  def critical_quality_issues
    quality_issues.where(severity: 'CRITICAL')
  end
  
  def has_open_critical_issues?
    critical_quality_issues.where(status: 'OPEN').exists?
  end
  
  # ============================================================================
  # ACTIVITY LOGGING
  # ============================================================================
  def log_activity!(activity_type, subject, description, user, attributes = {})
    activities.create!(
      activity_type: activity_type,
      subject: subject,
      description: description,
      activity_date: Time.current,
      related_user: user,
      created_by: user,
      **attributes
    )
  end
  
  def recent_activities(limit = 10)
    activities.order(activity_date: :desc).limit(limit)
  end
  
  # ============================================================================
  # CONTACT METHODS
  # ============================================================================
  def primary_contact
    contacts.find_by(is_primary_contact: true, is_active: true)
  end
  
  def sales_contacts
    contacts.where(contact_role: 'SALES', is_active: true)
  end
  
  def accounts_payable_contacts
    contacts.where(contact_role: 'ACCOUNTS_PAYABLE', is_active: true)
  end
  
  def technical_contacts
    contacts.where(contact_role: 'TECHNICAL', is_active: true)
  end
  
  # ============================================================================
  # ADDRESS METHODS
  # ============================================================================
  def primary_address
    addresses.find_by(address_type: 'PRIMARY_OFFICE', is_default: true, is_active: true) ||
    addresses.find_by(is_default: true, is_active: true) ||
    addresses.where(is_active: true).first
  end
  
  def factory_addresses
    addresses.where(address_type: 'FACTORY', is_active: true)
  end
  
  def warehouse_addresses
    addresses.where(address_type: 'WAREHOUSE', is_active: true)
  end
  
  def billing_address
    addresses.find_by(address_type: 'BILLING', is_active: true) || primary_address
  end
  
  # ============================================================================
  # CERTIFICATION METHODS
  # ============================================================================
  def has_certification?(cert_name)
    certifications.to_a.include?(cert_name)
  end
  
  def iso_certified?
    iso_9001_certified? || iso_14001_certified? || iso_45001_certified?
  end
  
  def certifications_expiring_soon?(days = 90)
    [iso_9001_expiry, iso_14001_expiry, iso_45001_expiry].compact.any? { |date| date <= days.days.from_now.to_date }
  end
  
  # ============================================================================
  # DOCUMENT METHODS
  # ============================================================================
  def active_documents
    documents.where(is_active: true)
  end
  
  def expired_documents
    documents.where('expiry_date < ?', Date.current)
  end
  
  def expiring_documents(days = 30)
    documents.where('expiry_date BETWEEN ? AND ?', Date.current, days.days.from_now.to_date)
  end
  
  def has_valid_contract?
    documents.where(document_type: 'CONTRACT', is_active: true)
            .where('expiry_date > ? OR expiry_date IS NULL', Date.current)
            .exists?
  end
  
  # ============================================================================
  # SOFT DELETE
  # ============================================================================
  def soft_delete!(deleted_by_user)
    update!(
      is_deleted: true,
      deleted_at: Time.current,
      deleted_by: deleted_by_user,
      is_active: false
    )
  end
  
  def restore!
    update!(
      is_deleted: false,
      deleted_at: nil,
      deleted_by: nil,
      is_active: true
    )
  end
  
  private
  
  # ============================================================================
  # PRIVATE CALLBACK METHODS
  # ============================================================================
  def generate_code
    self.code ||= self.class.generate_next_code
  end
  
  def set_display_name
    self.display_name = trade_name.presence || legal_name
  end
  
  def normalize_fields
    self.legal_name = legal_name.strip if legal_name.present?
    self.trade_name = trade_name.strip if trade_name.present?
    self.primary_email = primary_email.downcase.strip if primary_email.present?
  end
  
  def calculate_rating_label
    self.rating_label = case overall_rating
    when 90..100 then 'EXCELLENT'
    when 75..89 then 'GOOD'
    when 60..74 then 'FAIR'
    when 40..59 then 'POOR'
    else 'CRITICAL'
    end
  end
  
  def log_creation
    log_activity!('NOTE', 'Supplier Created', "Supplier #{code} was created", created_by) if created_by
  end
  
  def log_status_change
    if saved_change_to_supplier_status?
      old_status, new_status = saved_change_to_supplier_status
      log_activity!('NOTE', 'Status Changed', "Status changed from #{old_status} to #{new_status}", updated_by) if updated_by
    end
  end
end

# ============================================================
# Model 38: supplier_activity
# File: app/models/supplier_activity.rb
# ============================================================

class SupplierActivity < ApplicationRecord
  belongs_to :supplier
  belongs_to :supplier_contact, optional: true
  belongs_to :related_user, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :related_record, polymorphic: true, optional: true
  
  validates :activity_type, presence: true
  validates :subject, presence: true
  validates :activity_date, presence: true
  
  serialize :tags, type: Array, coder: JSON
  
  scope :recent, -> { order(activity_date: :desc) }
  scope :by_type, ->(type) { where(activity_type: type) }
  scope :completed, -> { where(activity_status: 'COMPLETED') }
  scope :scheduled, -> { where(activity_status: 'SCHEDULED') }
  scope :overdue, -> { where(is_overdue: true) }
  
  def mark_completed!(outcome = nil, completed_by_user)
    update!(
      activity_status: 'COMPLETED',
      outcome: outcome,
      is_overdue: false
    )
  end
  
  def reschedule!(new_date)
    update!(activity_date: new_date, is_overdue: false)
  end
end

# ============================================================
# Model 39: supplier_address
# File: app/models/supplier_address.rb
# ============================================================

class SupplierAddress < ApplicationRecord
  belongs_to :supplier
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  
  validates :address_type, presence: true, inclusion: { in: %w[PRIMARY_OFFICE FACTORY WAREHOUSE BILLING RETURNS OTHER] }
  validates :street_address_1, :city, :postal_code, :country, presence: true
  
  serialize :equipment_available, type: Array, coder: JSON
  serialize :certifications_at_location, type: Array, coder: JSON
  
  scope :active, -> { where(is_active: true) }
  scope :default_addresses, -> { where(is_default: true) }
  scope :factories, -> { where(address_type: 'FACTORY') }
  scope :warehouses, -> { where(address_type: 'WAREHOUSE') }
  
  before_save :ensure_single_default, if: :is_default?
  
  def display_label
    address_label.presence || "#{address_type.titleize} Address"
  end
  
  def full_address
    [street_address_1, street_address_2, city, state_province, postal_code, country].compact.join(', ')
  end
  
  def single_line_address
    [street_address_1, city, state_province, postal_code].compact.join(', ')
  end
  
  def make_default!
    transaction do
      supplier.addresses.where(address_type: address_type).update_all(is_default: false)
      update!(is_default: true)
    end
  end
  
  private
  
  def ensure_single_default
    if is_default? && is_default_changed?
      supplier.addresses.where(address_type: address_type).where.not(id: id).update_all(is_default: false)
    end
  end
end

# ============================================================
# Model 40: supplier_contact
# File: app/models/supplier_contact.rb
# ============================================================

class SupplierContact < ApplicationRecord
  belongs_to :supplier
  belongs_to :last_contacted_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  
  validates :first_name, :last_name, :email, :phone, presence: true
  validates :contact_role, presence: true, inclusion: { 
    in: %w[SALES TECHNICAL ACCOUNTS_PAYABLE QUALITY SHIPPING MANAGEMENT PRIMARY OTHER]
  }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  serialize :languages_spoken, type: Array, coder: JSON
  
  scope :active, -> { where(is_active: true) }
  scope :primary, -> { where(is_primary_contact: true) }
  scope :decision_makers, -> { where(is_decision_maker: true) }
  
  before_save :ensure_single_primary, if: :is_primary_contact?
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def name_with_title
    title.present? ? "#{full_name}, #{title}" : full_name
  end
  
  def make_primary!
    transaction do
      supplier.contacts.update_all(is_primary_contact: false)
      update!(is_primary_contact: true)
    end
  end
  
  def record_contact!(contacted_by_user)
    update!(
      last_contacted_at: Time.current,
      last_contacted_by: contacted_by_user,
      total_interactions_count: total_interactions_count + 1
    )
  end
  
  private
  
  def ensure_single_primary
    if is_primary_contact? && is_primary_contact_changed?
      supplier.contacts.where.not(id: id).update_all(is_primary_contact: false)
    end
  end
end

# ============================================================
# Model 41: supplier_document
# File: app/models/supplier_document.rb
# ============================================================

class SupplierDocument < ApplicationRecord
  belongs_to :supplier
  belongs_to :uploaded_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :superseded_by, class_name: 'SupplierDocument', optional: true
  
  mount_uploader :file, AttachmentUploader
  
  validates :document_type, presence: true
  validates :document_title, presence: true
  
  scope :active, -> { where(is_active: true) }
  scope :expired, -> { where('expiry_date < ?', Date.current) }
  scope :expiring_soon, ->(days = 30) { where('expiry_date BETWEEN ? AND ?', Date.current, days.days.from_now) }
  scope :by_type, ->(type) { where(document_type: type) }
  
  def expired?
    expiry_date.present? && expiry_date < Date.current
  end
  
  def expiring_soon?(days = 30)
    expiry_date.present? && expiry_date.between?(Date.current, days.days.from_now)
  end
  
  def days_until_expiry
    return nil unless expiry_date.present?
    (expiry_date - Date.current).to_i
  end
  
  def file_attached?
    file.attached?
  end
  
  def file_name
    file.attached? ? file.filename.to_s : super
  end
  
  def file_size
    file.attached? ? file.byte_size : super
  end
end


# ============================================================
# Model 42: supplier_performance_review
# File: app/models/supplier_performance_review.rb
# ============================================================

class SupplierPerformanceReview < ApplicationRecord
  belongs_to :supplier
  belongs_to :reviewed_by, class_name: 'User', optional: true
  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :shared_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  
  validates :period_start_date, :period_end_date, :review_date, presence: true
  validates :review_type, inclusion: { in: %w[MONTHLY QUARTERLY SEMI_ANNUAL ANNUAL AD_HOC] }
  validates :review_status, inclusion: { in: %w[DRAFT COMPLETED APPROVED SHARED_WITH_SUPPLIER] }
  
  scope :by_period, ->(start_date, end_date) { where('period_start_date >= ? AND period_end_date <= ?', start_date, end_date) }
  scope :approved, -> { where(review_status: 'APPROVED') }
  scope :recent, -> { order(review_date: :desc) }
  
  def approve!(approved_by_user)
    update!(
      review_status: 'APPROVED',
      approved_by: approved_by_user,
      approved_date: Date.current
    )
  end
  
  def share_with_supplier!(shared_by_user)
    update!(
      shared_with_supplier: true,
      shared_date: Date.current,
      shared_by: shared_by_user
    )
  end
  
  def calculate_overall_score
    scores = [quality_score, delivery_score, cost_score, service_score, responsiveness_score].compact
    return 0 if scores.empty?
    (scores.sum / scores.size).round(2)
  end
end

# ============================================================
# Model 43: supplier_quality_issue
# File: app/models/supplier_quality_issue.rb
# ============================================================

class SupplierQualityIssue < ApplicationRecord
  belongs_to :supplier
  belongs_to :product, optional: true
  belongs_to :reported_by, class_name: 'User', optional: true
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :related_issue, class_name: 'SupplierQualityIssue', optional: true
  
  has_many_attached :attachments
  
  validates :issue_title, :issue_description, :severity, :issue_date, presence: true
  validates :severity, inclusion: { in: %w[CRITICAL MAJOR MINOR] }
  validates :status, inclusion: { in: %w[OPEN IN_PROGRESS RESOLVED CLOSED RECURRING] }
  
  before_create :generate_issue_number
  after_create :notify_stakeholders
  after_update :update_supplier_rating, if: :saved_change_to_status?
  
  scope :open, -> { where(status: 'OPEN') }
  scope :critical, -> { where(severity: 'CRITICAL') }
  scope :resolved, -> { where(status: 'RESOLVED') }
  scope :closed, -> { where(status: 'CLOSED') }
  scope :repeat_issues, -> { where(is_repeat_issue: true) }
  
  def generate_issue_number
    last_issue = SupplierQualityIssue.order(issue_number: :desc).first
    if last_issue && last_issue.issue_number =~ /QI-(\d+)/
      next_number = $1.to_i + 1
    else
      next_number = 1
    end
    self.issue_number = "QI-#{next_number.to_s.rjust(5, '0')}"
  end
  
  def mark_resolved!(resolution_notes, resolved_by_user)
    update!(
      status: 'RESOLVED',
      resolution_date: Date.current,
      root_cause_analysis: resolution_notes,
      days_to_resolve: (Date.current - issue_date).to_i
    )
    
    supplier.log_activity!('ISSUE_RESOLUTION', "Quality Issue Resolved", 
                          "Issue #{issue_number} resolved", resolved_by_user)
  end
  
  def close!(closed_by_user)
    update!(
      status: 'CLOSED',
      closed_date: Date.current
    )
  end
  
  private
  
  def notify_stakeholders
    # Send email notifications (implement when mailer exists)
  end
  
  def update_supplier_rating
    return unless saved_change_to_status? && status == 'CLOSED'
    supplier.calculate_quality_performance!
    supplier.calculate_overall_rating!
  end
end

# ============================================================
# Model 44: tax_code
# File: app/models/tax_code.rb
# ============================================================

class TaxCode < ApplicationRecord
  # -------------------------------
  # ENUM-LIKE CONSTANTS
  # -------------------------------
  JURISDICTIONS = {
    "FEDERAL"  => "Federal",
    "STATE"    => "State",
    "PROVINCE" => "Province",
    "COUNTY"   => "County",
    "CITY"     => "City",
    "SPECIAL"  => "Special District"
  }.freeze

  TAX_TYPES = {
    "SALES" => "Sales Tax",
    "USE"   => "Use Tax",
    "VAT"   => "VAT",
    "GST"   => "GST",
    "HST"   => "HST",
    "PST"   => "PST"
  }.freeze

  FILING_FREQUENCIES = {
    "MONTHLY"   => "Monthly",
    "QUARTERLY" => "Quarterly",
    "ANNUALLY"  => "Annually"
  }.freeze

  # -------------------------------
  # VALIDATIONS
  # -------------------------------
  validates :code, uniqueness: true, allow_blank: true
  validates :name, presence: true
  validates :jurisdiction, presence: true, inclusion: { in: JURISDICTIONS.keys }
  validates :tax_type, presence: true, inclusion: { in: TAX_TYPES.keys }

  validates :rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  validate :jurisdiction_hierarchy_validation
  validate :effective_date_validation
  validate :compound_tax_validation

  scope :active, -> { where(is_active: true, deleted: false) }
  scope :not_deleted, -> { where(deleted: false) }

  # -------------------------------
  # CUSTOM VALIDATION METHODS
  # -------------------------------
  def jurisdiction_hierarchy_validation
    if jurisdiction == "FEDERAL" && (state_province.present? || county.present? || city.present?)
      errors.add(:base, "Federal taxes cannot have state/county/city specified")
    end

    if jurisdiction == "STATE" && state_province.blank?
      errors.add(:state_province, "State level taxes must specify state/province")
    end

    if jurisdiction == "COUNTY" && county.blank?
      errors.add(:county, "County taxes require county")
    end
  end

  def effective_date_validation
    if effective_to.present? && effective_to < effective_from
      errors.add(:effective_to, "cannot be earlier than effective from")
    end
  end

  def compound_tax_validation
    if is_compound? && compounds_on.blank?
      errors.add(:base, "Compound taxes must specify which tax they compound on")
    end
  end

  # -------------------------------
  # AUTO-GENERATE CODE
  # -------------------------------
  before_save :generate_code_if_blank

  def generate_code_if_blank
    return if code.present?

    base_code = tax_type.dup
    base_code += "-#{state_province}" if state_province.present?
    base_code += "-#{county}" if county.present?
    base_code += "-#{city}" if city.present?

    # Ensure uniqueness
    proposed = base_code
    counter = 1

    while TaxCode.where(code: proposed).where.not(id: id).exists?
      proposed = "#{base_code}-#{counter}"
      counter += 1
    end

    self.code = proposed
  end

  # -------------------------------
  # DISPLAY METHOD
  # -------------------------------
  def display_name
    "#{code} - #{name} (#{(rate.to_f * 100).round(2)}%)"
  end
end

# ============================================================
# Model 45: unit_of_measure
# File: app/models/unit_of_measure.rb
# ============================================================

class UnitOfMeasure < ApplicationRecord

  validates_uniqueness_of :name, :symbol
  validates :name, presence: true, length: { maximum: 100 }
  validates :symbol, presence: true, length: { maximum: 10 } 

end

# ============================================================
# Model 46: user
# File: app/models/user.rb
# ============================================================

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  mount_uploader :avatar, ImageUploader

  has_many :assigned_work_order_operations, class_name: 'WorkOrderOperation', foreign_key: :assigned_operator_id
end

# ============================================================
# Model 47: vendor_quote
# File: app/models/vendor_quote.rb
# ============================================================

class VendorQuote < ApplicationRecord
  belongs_to :rfq
  belongs_to :rfq_item
  belongs_to :supplier
  belongs_to :rfq_supplier
  belongs_to :selected_by, class_name: 'User', optional: true
  belongs_to :reviewed_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  belongs_to :superseded_by, class_name: 'VendorQuote', optional: true
  
  validates :quote_date, :unit_price, :total_price, :lead_time_days, presence: true
  validates :unit_price, :total_price, numericality: { greater_than: 0 }
  validates :lead_time_days, numericality: { greater_than: 0 }
  
  scope :latest, -> { where(is_latest_revision: true) }
  scope :selected, -> { where(is_selected: true) }
  scope :lowest_price, -> { where(is_lowest_price: true) }
  scope :fastest_delivery, -> { where(is_fastest_delivery: true) }
  scope :best_value, -> { where(is_best_value: true) }
  scope :recommended, -> { where(is_recommended: true) }
  scope :by_rank, -> { order(:overall_rank) }
  scope :by_price, -> { order(:unit_price) }
  scope :by_delivery, -> { order(:lead_time_days) }
  
  before_save :calculate_total_cost
  after_create :update_rfq_item_statistics
  after_save :calculate_rankings, if: :saved_change_to_unit_price?
  
  def calculate_scores!(rfq)
    # Get all competing quotes for this item
    competing_quotes = rfq_item.vendor_quotes.latest
    
    # 1. PRICE SCORE (0-100, lower price = higher score)
    prices = competing_quotes.pluck(:unit_price)
    min_price = prices.min
    max_price = prices.max
    price_range = max_price - min_price
    
    if price_range.zero?
      self.price_score = 100
    else
      # Inverse scoring: lowest price gets 100, highest gets 0
      self.price_score = ((max_price - unit_price) / price_range * 100).round(2)
    end
    
    # 2. DELIVERY SCORE (0-100, faster = higher score)
    lead_times = competing_quotes.pluck(:lead_time_days)
    min_lead_time = lead_times.min
    max_lead_time = lead_times.max
    lead_time_range = max_lead_time - min_lead_time
    
    if lead_time_range.zero?
      self.delivery_score = 100
    else
      # Inverse scoring: shortest lead time gets 100
      self.delivery_score = ((max_lead_time - lead_time_days) / lead_time_range * 100).round(2)
    end
    
    # 3. QUALITY SCORE (from supplier's overall rating)
    self.quality_score = supplier.overall_rating || 75
    
    # 4. SERVICE SCORE (from supplier's service rating)
    self.service_score = supplier.service_score || 75
    
    # 5. OVERALL WEIGHTED SCORE
    weights = rfq.weights
    self.overall_score = (
      (price_score * weights[:price] / 100) +
      (delivery_score * weights[:delivery] / 100) +
      (quality_score * weights[:quality] / 100) +
      (service_score * weights[:service] / 100)
    ).round(2)
    
    save if changed?
  end
  
  def calculate_total_price!(quote)
    # Base price
    base = unit_price × quantity_requested
    
    # Additional costs
    additional = tooling_cost + 
                 setup_cost + 
                 shipping_cost + 
                 other_charges
    
    total_price = base + additional
  end

  def generate_quote_number(supplier)
    # Format: QT-SUP001-20241223-001
    prefix = supplier.supplier_code || supplier.id.to_s.rjust(3, '0')
    date_part = Date.current.strftime('%Y%m%d')
    sequence = VendorQuote.where(supplier: supplier).count + 1
    
    "QT-#{prefix}-#{date_part}-#{sequence.to_s.rjust(3, '0')}"
  end

  def calculate_rankings
    # Rank among all quotes for this RFQ item
    quotes = rfq_item.vendor_quotes.latest.order(:unit_price)
    
    # Price rankings
    quotes.each_with_index do |quote, index|
      quote.update_column(:price_rank, index + 1)
      quote.update_column(:is_lowest_price, index.zero?)
    end
    
    # Delivery rankings
    quotes_by_delivery = rfq_item.vendor_quotes.latest.order(:lead_time_days)
    quotes_by_delivery.each_with_index do |quote, index|
      quote.update_column(:delivery_rank, index + 1)
      quote.update_column(:is_fastest_delivery, index.zero?)
    end
    
    # Total cost rankings
    quotes_by_cost = rfq_item.vendor_quotes.latest.order(:total_cost)
    quotes_by_cost.each_with_index do |quote, index|
      quote.update_column(:total_cost_rank, index + 1)
    end
    
    # Overall rankings (by score)
    quotes_by_score = rfq_item.vendor_quotes.latest.order(overall_score: :desc)
    quotes_by_score.each_with_index do |quote, index|
      quote.update_column(:overall_rank, index + 1)
      quote.update_column(:is_best_value, index.zero?)
    end
  end
  
  def calculate_price_comparisons!
    # Compare with lowest price
    lowest = rfq_item.lowest_quoted_price
    if lowest && lowest > 0
      diff = ((unit_price - lowest) / lowest * 100).round(2)
      update_column(:price_vs_lowest_percentage, diff)
    end
    
    # Compare with average
    average = rfq_item.average_quoted_price
    if average && average > 0
      diff = ((unit_price - average) / average * 100).round(2)
      update_column(:price_vs_average_percentage, diff)
    end
    
    # Compare with target
    if rfq_item.target_unit_price && rfq_item.target_unit_price > 0
      diff = ((unit_price - rfq_item.target_unit_price) / rfq_item.target_unit_price * 100).round(2)
      update_column(:price_vs_target_percentage, diff)
    end
    
    # Compare with last purchase
    if rfq_item.last_purchase_price && rfq_item.last_purchase_price > 0
      diff = ((unit_price - rfq_item.last_purchase_price) / rfq_item.last_purchase_price * 100).round(2)
      update_column(:price_vs_last_purchase_percentage, diff)
    end
  end
  
  # ============================================================================
  # QUOTE MANAGEMENT
  # ============================================================================
  def create_revision!(attributes, updated_by_user)
    new_quote = self.class.new(
      attributes.merge(
        rfq: rfq,
        rfq_item: rfq_item,
        supplier: supplier,
        rfq_supplier: rfq_supplier,
        quote_revision: quote_revision + 1,
        created_by: updated_by_user,
        superseded_by: nil,
        is_latest_revision: true
      )
    )
    
    if new_quote.save
      update!(is_latest_revision: false, superseded_by: new_quote)
      new_quote
    end
  end
  
  def select!(selected_by_user, reason: nil)
    update!(
      is_selected: true,
      selected_by: selected_by_user,
      selected_date: Date.current,
      selection_reason: reason,
      quote_status: 'ACCEPTED'
    )
    
    rfq_item.select_quote!(self, selected_by_user, reason: reason)
  end
  
  def reject!(reviewed_by_user, reason: nil)
    update!(
      quote_status: 'REJECTED',
      reviewed_by: reviewed_by_user,
      reviewed_at: Time.current,
      review_notes: reason
    )
  end
  
  # ============================================================================
  # DISPLAY HELPERS
  # ============================================================================
  def price_difference_from_lowest
    return 0 unless rfq_item.lowest_quoted_price
    unit_price - rfq_item.lowest_quoted_price
  end
  
  def is_competitive?
    price_vs_average_percentage && price_vs_average_percentage <= 5
  end
  
  def delivery_status
    if can_meet_required_date
      'On Time'
    else
      "#{days_after_required_date} days late"
    end
  end
  
  def highlight_class
    return 'best-value' if is_best_value
    return 'lowest-price' if is_lowest_price
    return 'fastest-delivery' if is_fastest_delivery
    nil
  end
  
  private
  
  def calculate_total_cost
    self.total_cost = total_price + 
                      (tooling_cost || 0) + 
                      (setup_cost || 0) + 
                      (shipping_cost || 0) + 
                      (other_charges || 0)
  end
  
  def update_rfq_item_statistics
    rfq_item.calculate_quote_statistics!
    rfq_supplier.calculate_quote_summary!
  end
end

# ============================================================
# Model 48: warehouse
# File: app/models/warehouse.rb
# ============================================================

class Warehouse < ApplicationRecord
  # Basic presence validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :code, presence: true, uniqueness: true, length: { minimum: 2, maximum: 20 }

  # Address optional but length control
  validates :address, length: { maximum: 500 }, allow_blank: true

  has_many :stock_issues
  has_many :locations
end

# ============================================================
# Model 49: work_center
# File: app/models/work_center.rb
# ============================================================

# app/models/work_center.rb

class WorkCenter < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :location, optional: true
  belongs_to :warehouse, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  has_many :routing_operations
  
  # Future: routing operations will belong to work centers
  # has_many :routing_operations
  
  # ========================================
  # CONSTANTS & ENUMS
  # ========================================
  WORK_CENTER_TYPES = {
    "MACHINE"        => "Machine/Equipment",
    "ASSEMBLY"       => "Assembly Station",
    "QUALITY_CHECK"  => "Quality Control",
    "PACKING"        => "Packing Station",
    "PAINTING"       => "Painting/Coating",
    "WELDING"        => "Welding Station",
    "CUTTING"        => "Cutting/Sawing",
    "DRILLING"       => "Drilling Station",
    "FINISHING"      => "Finishing/Polish",
    "INSPECTION"     => "Inspection Point",
    "STORAGE"        => "Staging/Storage",
    "MANUAL"         => "Manual Labor",
    "OTHER"          => "Other"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :code, presence: true, 
                   uniqueness: { case_sensitive: false },
                   length: { maximum: 20 },
                   format: { 
                     with: /\A[A-Z0-9\-_]+\z/i, 
                     message: "only allows letters, numbers, hyphens and underscores" 
                   }
  
  validates :name, presence: true, length: { maximum: 100 }
  
  validates :work_center_type, presence: true, 
                               inclusion: { in: WORK_CENTER_TYPES.keys }
  
  validates :capacity_per_hour, 
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: false
  
  validates :efficiency_percent,
            numericality: { 
              only_integer: true,
              greater_than: 0, 
              less_than_or_equal_to: 100 
            }
  
  validates :labor_cost_per_hour,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :overhead_cost_per_hour,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :setup_time_minutes,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  validates :queue_time_minutes,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  validate :location_belongs_to_warehouse
  
  def location_belongs_to_warehouse
    return if location.blank? || warehouse.blank?
    
    if location.warehouse_id != warehouse_id
      errors.add(:location, "must belong to the selected warehouse")
    end
  end
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  scope :by_type, ->(type) { where(work_center_type: type) }
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :normalize_code
  
  def normalize_code
    self.code = code.to_s.upcase.strip if code.present?
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Total cost per hour (labor + overhead)
  def total_cost_per_hour
    (labor_cost_per_hour.to_d + overhead_cost_per_hour.to_d).round(2)
  end
  
  # Effective capacity considering efficiency
  def effective_capacity_per_hour
    (capacity_per_hour.to_d * (efficiency_percent.to_d / 100)).round(2)
  end
  
  # Calculate cost for a given run time (in minutes)
  def calculate_run_cost(run_time_minutes, quantity = 1)
    hours = run_time_minutes.to_d / 60
    (total_cost_per_hour * hours * quantity).round(2)
  end
  
  # Calculate setup cost
  def calculate_setup_cost(setup_minutes = nil)
    setup_mins = setup_minutes || setup_time_minutes
    hours = setup_mins.to_d / 60
    (total_cost_per_hour * hours).round(2)
  end
  
  # Total time for a job (queue + setup + run)
  def calculate_total_time(setup_mins, run_mins_per_unit, quantity)
    queue_time_minutes + setup_mins + (run_mins_per_unit * quantity)
  end
  
  # Display name for dropdowns
  def display_name
    "#{code} - #{name}"
  end
  
  # Work center type label
  def type_label
    WORK_CENTER_TYPES[work_center_type] || work_center_type
  end
  
  # Check if work center can be deleted
  def can_be_deleted?
    # Future: check if used in any routing operations
    # routing_operations.none?
    true
  end
  
  # Soft delete
  def destroy!
    if can_be_deleted?
      update_attribute(:deleted, true)
    else
      errors.add(:base, "Cannot delete work center that is being used in routings")
      false
    end
  end
  
  # ========================================
  # CLASS METHODS
  # ========================================
  
  # Generate next code
  def self.generate_next_code
    last_wc = WorkCenter.where("code LIKE 'WC-%'")
                        .order(code: :desc)
                        .first
    
    if last_wc && last_wc.code =~ /WC-(\d+)/
      next_number = $1.to_i + 1
      "WC-#{next_number.to_s.rjust(3, '0')}"
    else
      "WC-001"
    end
  end
end

# ============================================================
# Model 50: work_order
# File: app/models/work_order.rb
# ============================================================

# app/models/work_order.rb

class WorkOrder < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :product
  belongs_to :bom, class_name: "BillOfMaterial", optional: true
  belongs_to :routing, optional: true
  belongs_to :customer, optional: true
  belongs_to :warehouse
  belongs_to :uom, class_name: "UnitOfMeasure"
  
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :released_by, class_name: "User", optional: true
  belongs_to :completed_by, class_name: "User", optional: true
  
  has_many :work_order_operations, -> { where(deleted: false).order(:sequence_no) }, dependent: :destroy
  has_many :work_order_materials, -> { where(deleted: false) }, dependent: :destroy
  
  # ========================================
  # CONSTANTS
  # ========================================
  STATUSES = %w[NOT_STARTED RELEASED IN_PROGRESS COMPLETED CANCELLED].freeze
  PRIORITIES = %w[LOW NORMAL HIGH URGENT].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :wo_number, presence: true, uniqueness: true
  validates :product_id, presence: true
  validates :quantity_to_produce, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }
  
  validates :scheduled_start_date, presence: true
  validates :scheduled_end_date, presence: true
  
  # Custom validations
  validate :product_must_have_bom_and_routing
  validate :end_date_after_start_date
  validate :valid_status_transition, on: :update
  validate :cannot_release_without_bom_and_routing
  validate :quantity_completed_cannot_exceed_to_produce
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_wo_number, on: :create
  before_validation :auto_fetch_bom_and_routing, on: :create
  before_create :calculate_planned_costs
  
  after_update :handle_status_change, if: :saved_change_to_status?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :non_deleted, -> { where(deleted: false) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :scheduled_between, ->(start_date, end_date) { 
    where("scheduled_start_date >= ? AND scheduled_end_date <= ?", start_date, end_date) 
  }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  
  def product_must_have_bom_and_routing
    return if product.blank?
    
    allowed_types = ["Finished Goods", "Semi-Finished Goods"]
    unless allowed_types.include?(product.product_type)
      errors.add(:product_id, "must be a Finished Goods or Semi-Finished Goods to create a Work Order")
    end
  end
  
  def end_date_after_start_date
    return if scheduled_start_date.blank? || scheduled_end_date.blank?
    
    if scheduled_end_date < scheduled_start_date
      errors.add(:scheduled_end_date, "must be after the start date")
    end
  end
  
  def valid_status_transition
    return if status_was.nil? || !status_changed? # New record
    
    valid_transitions = {
      'NOT_STARTED' => ['RELEASED', 'CANCELLED'],
      'RELEASED' => ['IN_PROGRESS', 'CANCELLED'],
      'IN_PROGRESS' => ['COMPLETED', 'CANCELLED'],
      'COMPLETED' => [],
      'CANCELLED' => []
    }
    
    allowed = valid_transitions[status_was] || []
    
    unless allowed.include?(status)
      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    end
  end
  
  def cannot_release_without_bom_and_routing
    return unless status == 'RELEASED' && status_was == 'NOT_STARTED'
    
    if bom.blank?
      errors.add(:base, "Cannot release Work Order without an active BOM")
    end
    
    if routing.blank?
      errors.add(:base, "Cannot release Work Order without an active Routing")
    end
  end
  
  def quantity_completed_cannot_exceed_to_produce
    return if quantity_completed.blank?
    
    if quantity_completed > quantity_to_produce
      errors.add(:quantity_completed, "cannot exceed quantity to produce")
    end
  end
  
  # ========================================
  # CALLBACKS METHODS
  # ========================================
  
  def set_wo_number
    return if wo_number.present?
    
    # Generate WO number: WO-YYYY-0001
    year = Date.current.year
    last_wo = WorkOrder.where("wo_number LIKE ?", "WO-#{year}-%")
                       .order(wo_number: :desc)
                       .first
    
    if last_wo && last_wo.wo_number =~ /WO-#{year}-(\d+)/
      next_number = $1.to_i + 1
    else
      next_number = 1
    end
    
    self.wo_number = "WO-#{year}-#{next_number.to_s.rjust(4, '0')}"
  end
  
  def auto_fetch_bom_and_routing
    return if product.blank?
    
    # Fetch active BOM (prefer default, otherwise get active)
    self.bom ||= product.bill_of_materials
                        .non_deleted
                        .where(status: 'ACTIVE')
                        .order(is_default: :desc, effective_from: :desc)
                        .first
    
    # Fetch active Routing (prefer default, otherwise get active)
    self.routing ||= product.routings
                            .non_deleted
                            .where(status: 'ACTIVE')
                            .order(is_default: :desc)
                            .first
  end
  
  def calculate_planned_costs
    calculate_planned_material_cost
    calculate_planned_labor_and_overhead_cost
  end
  
  def calculate_planned_material_cost
    return unless bom.present?
    
    total_material_cost = BigDecimal("0")
    
    bom.bom_items.where(deleted: false).includes(:component).each do |bom_item|
      component_cost = bom_item.component.standard_cost.to_d
      required_qty = bom_item.quantity.to_d * quantity_to_produce.to_d
      
      # Consider scrap percentage
      if bom_item.scrap_percent.to_d > 0
        scrap_factor = 1 + (bom_item.scrap_percent.to_d / 100)
        required_qty = required_qty * scrap_factor
      end
      
      total_material_cost += (required_qty * component_cost)
    end
    
    self.planned_material_cost = total_material_cost.round(2)
  end
  
  def calculate_planned_labor_and_overhead_cost
    return unless routing.present?
    
    total_labor = BigDecimal("0")
    total_overhead = BigDecimal("0")
    
    routing.routing_operations.where(deleted: false).includes(:work_center).each do |routing_op|
      wc = routing_op.work_center
      
      # Setup cost (one-time per batch)
      setup_hours = routing_op.setup_time_minutes.to_d / 60
      setup_labor = wc.labor_cost_per_hour.to_d * setup_hours
      setup_overhead = wc.overhead_cost_per_hour.to_d * setup_hours
      
      # Run cost (per unit × quantity)
      run_hours_per_unit = routing_op.run_time_per_unit_minutes.to_d / 60
      run_hours_total = run_hours_per_unit * quantity_to_produce.to_d
      run_labor = wc.labor_cost_per_hour.to_d * run_hours_total
      run_overhead = wc.overhead_cost_per_hour.to_d * run_hours_total
      
      total_labor += (setup_labor + run_labor)
      total_overhead += (setup_overhead + run_overhead)
    end
    
    self.planned_labor_cost = total_labor.round(2)
    self.planned_overhead_cost = total_overhead.round(2)
  end
  
  def handle_status_change
    case status
    when 'RELEASED'
      handle_release
    when 'IN_PROGRESS'
      handle_start_production
    when 'COMPLETED'
      handle_completion
    when 'CANCELLED'
      handle_cancellation
    end
  end
  
  def handle_release
    self.update_attribute(:released_at, Time.current)
    
    # Auto-create operations from routing
    create_operations_from_routing!
    
    # Auto-create materials from BOM
    create_materials_from_bom!

    if released_by.present?
      WorkOrderNotificationJob.perform_later('released', id, self.released_by.email)
    end
  end
  
  def handle_start_production
    self.update_attribute(:actual_start_date, Time.current)
  end
  
  def handle_completion
    self.update_attribute(:actual_end_date, Time.current)
    self.update_attribute(:quantity_completed, quantity_to_produce) unless quantity_completed.present?
    self.update_attribute(:completed_at, Time.current)

    # Calculate actual costs from child records
    recalculate_actual_costs
    
    # Create stock transaction for finished goods receipt
    receive_finished_goods_to_inventory

    # Send completion notification
    if self.completed_by.present?
      WorkOrderNotificationJob.perform_later('completed', id, self.completed_by.email)
    end
    
    # Notify production manager
    if self.created_by.present? && self.created_by != self.completed_by
      WorkOrderNotificationJob.perform_later('completed', id, self.created_by.email)
    end
  end
  
  def handle_cancellation
    # Return all allocated/issued materials back to inventory
    work_order_materials.where(status: ['ALLOCATED', 'ISSUED']).each do |wo_material|
      next unless wo_material.location_id.present?
      
      # Create stock transaction to return material
      if wo_material.quantity_issued.to_d > 0
        StockTransaction.create!(
          transaction_type: 'PRODUCTION_RETURN',
          product_id: wo_material.product_id,
          quantity: wo_material.quantity_issued,
          uom_id: wo_material.uom_id,
          to_location_id: wo_material.location_id,
          batch_number: wo_material.batch_number,
          reference_type: 'WorkOrder',
          reference_id: id,
          reference_number: wo_number,
          transaction_date: Date.current,
          notes: "Material returned due to Work Order cancellation",
          created_by_id: Current.user&.id || completed_by_id
        )
        
        # Update stock level
        stock_level = StockLevel.find_or_initialize_by(
          product_id: wo_material.product_id,
          location_id: wo_material.location_id,
          batch_number: wo_material.batch_number
        )
        stock_level.on_hand_qty = (stock_level.on_hand_qty.to_d + wo_material.quantity_issued.to_d)
        stock_level.save!
      end
      
      # Mark material as CANCELLED
      wo_material.update!(status: 'CANCELLED')
    end
    
    # Cancel all pending/in-progress operations
    work_order_operations.where(status: ['PENDING', 'IN_PROGRESS']).each do |operation|
      # Clock out any active labor entries
      operation.labor_time_entries.active.each do |entry|
        entry.clock_out!(Time.current)
      end
      
      operation.update!(status: 'CANCELLED')
    end
    
    # Send cancellation notification
    if created_by.present?
      WorkOrderNotificationJob.perform_later('cancelled', id, created_by.email)
    end
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  def create_operations_from_routing!
    return unless routing.present?
    
    routing.routing_operations.order(:operation_sequence).each do |routing_op|
      wc = routing_op.work_center
      
      # Calculate planned time
      setup_mins = routing_op.setup_time_minutes.to_i
      run_mins_per_unit = routing_op.run_time_per_unit_minutes.to_d
      total_run_mins = (run_mins_per_unit * quantity_to_produce.to_d).to_i
      total_mins = setup_mins + total_run_mins
      
      # Calculate planned cost
      setup_hours = setup_mins.to_d / 60
      run_hours = total_run_mins.to_d / 60
      operation_cost = (wc.total_cost_per_hour.to_d * (setup_hours + run_hours)).round(2)
      
      work_order_operations.create!(
        routing_operation_id: routing_op.id,
        work_center_id: routing_op.work_center_id,
        sequence_no: routing_op.operation_sequence,
        operation_name: routing_op.operation_name,
        operation_description: routing_op.description,
        quantity_to_process: quantity_to_produce,
        planned_setup_minutes: setup_mins,
        planned_run_minutes_per_unit: run_mins_per_unit,
        planned_total_minutes: total_mins,
        planned_cost: operation_cost,
        status: 'PENDING'
      )
    end
  end
  
  def create_materials_from_bom!
    return unless bom.present?
    
    bom.bom_items.where(deleted: false).includes(:component).each do |bom_item|
      required_qty = bom_item.quantity.to_d * quantity_to_produce.to_d
      
      # Consider scrap percentage
      if bom_item.scrap_percent.to_d > 0
        scrap_factor = 1 + (bom_item.scrap_percent.to_d / 100)
        required_qty = required_qty * scrap_factor
      end
      
      component_cost = bom_item.component.standard_cost.to_d
      total_cost = (required_qty * component_cost).round(2)
      
      work_order_materials.create!(
        bom_item_id: bom_item.id,
        product_id: bom_item.component_id,
        uom_id: bom_item.uom_id,
        quantity_required: required_qty.round(4),
        unit_cost: component_cost.round(4),
        total_cost: total_cost,
        status: 'REQUIRED'
      )
    end
  end
  
  def recalculate_actual_costs
    # Material cost from work_order_materials
    self.actual_material_cost = work_order_materials.sum(:total_cost).round(2)
    
    # Labor and overhead from work_order_operations
    self.actual_labor_cost = BigDecimal("0")
    self.actual_overhead_cost = BigDecimal("0")
    
    work_order_operations.where(status: 'COMPLETED').includes(:work_center).each do |op|
      wc = op.work_center
      actual_hours = op.actual_total_minutes.to_d / 60
      
      self.actual_labor_cost += (wc.labor_cost_per_hour.to_d * actual_hours)
      self.actual_overhead_cost += (wc.overhead_cost_per_hour.to_d * actual_hours)
    end
    
    self.actual_labor_cost = self.actual_labor_cost.round(2)
    self.actual_overhead_cost = self.actual_overhead_cost.round(2)
    
    save
  end
  
  def receive_finished_goods_to_inventory
    return unless quantity_completed.to_d > 0
    
    # Determine destination location
    # Priority: 1) Warehouse's FG location, 2) First active location, 3) Error
    fg_location = warehouse.locations.non_deleted
                          .where(location_type: 'FINISHED_GOODS')
                          .first
    
    fg_location ||= warehouse.locations.non_deleted.first
    
    unless fg_location
      raise "No valid location found in warehouse #{warehouse.name} to receive finished goods"
    end
    
    # Create stock transaction for finished goods receipt
    stock_transaction = StockTransaction.create!(
      transaction_type: 'PRODUCTION_OUTPUT',
      product_id: product_id,
      quantity: quantity_completed,
      uom_id: uom_id,
      to_location_id: fg_location.id,
      reference_type: 'WorkOrder',
      reference_id: id,
      reference_number: wo_number,
      transaction_date: Date.current,
      notes: "Finished goods received from Work Order #{wo_number}",
      created_by_id: completed_by_id || current_user&.id
    )
    
    # Update or create stock level for finished goods
    stock_level = StockLevel.find_or_initialize_by(
      product_id: product_id,
      location_id: fg_location.id,
      batch_number: nil  # FG typically don't have batch numbers unless you want to track by WO
    )
    
    stock_level.on_hand_qty = (stock_level.on_hand_qty.to_d + quantity_completed.to_d)
    stock_level.save!
    
    # Optional: Update product's last_cost based on actual production cost
    if total_actual_cost > 0
      unit_cost = (total_actual_cost / quantity_completed).round(4)
      product.update!(last_cost: unit_cost)
    end
    
    stock_transaction
  rescue => e
    Rails.logger.error "Failed to receive finished goods for WO #{wo_number}: #{e.message}"
    errors.add(:base, "Failed to receive finished goods: #{e.message}")
    raise ActiveRecord::Rollback
  end

  def check_material_shortages
    shortage_details = []
    
    return shortage_details unless bom.present?
    
    work_order_materials.each do |wo_material|
      # Calculate available stock across all locations in the warehouse
      available_qty = StockLevel.joins(:location)
                                .where(product_id: wo_material.product_id)
                                .where(locations: { warehouse_id: warehouse_id })
                                .sum(:on_hand_qty)
      
      required_qty = wo_material.quantity_required
      
      # Check if there's a shortage
      if available_qty < required_qty
        shortage_details << {
          material_code: wo_material.product.sku,
          material_name: wo_material.product.name,
          required_qty: required_qty,
          available_qty: available_qty,
          shortage_qty: required_qty - available_qty,
          uom: wo_material.uom.symbol
        }
      end
    end
    
    shortage_details
  end

  def previous_in_progress_operations_before(op)
    op.work_order.work_order_operations.where("sequence_no < ?", op.sequence_no).where(status: 'IN_PROGRESS')
  end
  
  # ========================================
  # HELPER METHODS
  # ========================================

  def total_planned_cost
    (planned_material_cost.to_d + planned_labor_cost.to_d + planned_overhead_cost.to_d).round(2)
  end
  
  def total_actual_cost
    (actual_material_cost.to_d + actual_labor_cost.to_d + actual_overhead_cost.to_d).round(2)
  end
  
  def cost_variance
    total_planned_cost - total_actual_cost
  end
  
  def cost_variance_percent
    return 0 if total_planned_cost.zero?
    ((cost_variance / total_planned_cost) * 100).round(2)
  end
  
  def progress_percentage
    return 0 if quantity_to_produce.zero?
    ((quantity_completed.to_d / quantity_to_produce.to_d) * 100).round(2)
  end
  
  def operations_completed_count
    work_order_operations.where(status: 'COMPLETED').count
  end
  
  def operations_total_count
    work_order_operations.count
  end
  
  def operations_progress_percentage
    return 0 if operations_total_count.zero?
    ((operations_completed_count.to_f / operations_total_count) * 100).round(2)
  end
  
  def can_be_released?
    status == 'NOT_STARTED' && bom.present? && routing.present?
  end
  
  def can_start_production?
    status == 'RELEASED'
  end
  
  def can_be_completed?
    status == 'IN_PROGRESS' && all_operations_completed?
  end
  
  def all_operations_completed?
    work_order_operations.where.not(status: 'COMPLETED').none?
  end
  
  def can_be_cancelled?
    ['NOT_STARTED', 'RELEASED', 'IN_PROGRESS'].include?(status)
  end
  
  def status_badge_class
    case status
    when 'NOT_STARTED' then 'secondary'
    when 'RELEASED' then 'info'
    when 'IN_PROGRESS' then 'warning'
    when 'COMPLETED' then 'success'
    when 'CANCELLED' then 'danger'
    else 'secondary'
    end
  end
  
  def priority_badge_class
    case priority
    when 'URGENT' then 'danger'
    when 'HIGH' then 'warning'
    when 'NORMAL' then 'info'
    when 'LOW' then 'secondary'
    else 'secondary'
    end
  end
  
  # ========================================
  # SOFT DELETE
  # ========================================
  def destroy!
    update_attribute(:deleted, true)
  end
end

# ============================================================
# Model 51: work_order_material
# File: app/models/work_order_material.rb
# ============================================================

# app/models/work_order_material.rb

class WorkOrderMaterial < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :work_order
  belongs_to :bom_item, optional: true
  belongs_to :product  # The component/material
  belongs_to :uom, class_name: "UnitOfMeasure"
  belongs_to :batch, class_name: "StockBatch", optional: true
  belongs_to :location, optional: true
  belongs_to :issued_by, class_name: "User", optional: true
  
  # ========================================
  # CONSTANTS
  # ========================================
  STATUSES = %w[REQUIRED ALLOCATED ISSUED CONSUMED RETURNED].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :product_id, presence: true
  validates :quantity_required, numericality: { greater_than: 0 }
  validates :quantity_allocated, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_consumed, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  
  validate :consumed_cannot_exceed_required
  validate :allocated_cannot_exceed_available_stock
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_save :calculate_total_cost
  after_update :update_work_order_material_cost, if: :saved_change_to_quantity_consumed?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :non_deleted, -> { where(deleted: false) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :required, -> { where(status: 'REQUIRED') }
  scope :allocated, -> { where(status: 'ALLOCATED') }
  scope :issued, -> { where(status: 'ISSUED') }
  scope :consumed, -> { where(status: 'CONSUMED') }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  
  def consumed_cannot_exceed_required
    if quantity_consumed.to_d > quantity_required.to_d
      errors.add(:quantity_consumed, "cannot exceed quantity required")
    end
  end
  
  def allocated_cannot_exceed_available_stock
    return if location.blank? || product.blank?
    return unless status == 'ALLOCATED' && quantity_allocated_changed?
    
    # Check available stock at location
    available = StockLevel.where(
      product_id: product_id,
      location_id: location_id
    ).sum(:on_hand_qty)
    
    if quantity_allocated.to_d > available.to_d
      errors.add(:quantity_allocated, "exceeds available stock (#{available} available)")
    end
  end
  
  # ========================================
  # CALLBACK METHODS
  # ========================================
  
  def calculate_total_cost
    self.total_cost = (quantity_consumed.to_d * unit_cost.to_d).round(2)
  end
  
  def update_work_order_material_cost
    # When material consumption changes, update WO's actual material cost
    work_order.recalculate_actual_costs if work_order.present?
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Allocate material from inventory (reserve it)
  def allocate_material!(location_obj, batch_obj = nil, qty = nil)
    return false unless status == 'REQUIRED'
    allocation_qty = qty || quantity_required
    
    # Check if stock is available
    available = if batch_obj.present?
      StockLevel.where(
        product_id: product_id,
        location_id: location_obj.id,
        batch_id: batch_obj.id
      ).sum(:on_hand_qty)
    else
      StockLevel.where(
        product_id: product_id,
        location_id: location_obj.id
      ).sum(:on_hand_qty)
    end
    
    if available < allocation_qty
      errors.add(:base, "Insufficient stock available for allocation")
      return false
    end
    
    self.location = location_obj
    self.batch = batch_obj if batch_obj.present?
    self.quantity_allocated = allocation_qty
    self.status = 'ALLOCATED'
    self.allocated_at = Time.current
    
    save
  end
  
  # Issue material to production floor (create stock transaction)
  def issue_material!(issued_by_user, qty = nil)
    return false unless status == 'ALLOCATED'
    
    issue_qty = qty || quantity_allocated
    
    # Create StockTransaction for material issue
    transaction = StockTransaction.create!(
      txn_type: 'PRODUCTION_CONSUMPTION',
      product_id: product_id,
      quantity: issue_qty,  # Negative because it's going OUT
      uom_id: uom_id,
      from_location_id: location_id,
      batch_id: batch_id,
      reference_type: 'WorkOrder',
      reference_id: work_order_id,
      created_at: Date.current,
      created_by_id: issued_by_user.id,
      note: "Issued for WO: #{work_order.wo_number}"
    )
    
    if transaction.persisted?
      self.status = 'ISSUED'
      self.issued_at = Time.current
      self.issued_by = issued_by_user
      self.quantity_consumed = issue_qty  # Assume issued = consumed for now
      
      save
    else
      errors.add(:base, "Failed to create stock transaction")
      false
    end
  end
  
  # Record actual material consumption (if different from issued)
  def record_consumption!(qty_consumed)
    return false unless ['ISSUED', 'CONSUMED'].include?(status)
    
    self.quantity_consumed = qty_consumed
    self.status = 'CONSUMED'
    
    # Update cost based on actual consumption
    self.total_cost = (qty_consumed.to_d * unit_cost.to_d).round(2)
    
    save
  end
  
  # Return excess material to inventory
  def return_material!(qty_to_return, returned_by_user)
    return false unless status == 'CONSUMED'
    return false if qty_to_return > quantity_consumed
    
    # Create StockTransaction for material return
    transaction = StockTransaction.create!(
      txn_type: 'PRODUCTION_RETURN',
      product_id: product_id,
      quantity: qty_to_return,  # Positive because it's coming back
      uom_id: uom_id,
      to_location_id: location_id,
      batch_id: batch_id,
      reference_type: 'WorkOrder',
      reference_id: work_order_id,
      created_at: Date.current,
      created_by_id: returned_by_user.id,
      note: "Returned from WO: #{work_order.wo_number}"
    )
    
    if transaction.persisted?
      self.quantity_consumed -= qty_to_return
      self.total_cost = (quantity_consumed.to_d * unit_cost.to_d).round(2)
      self.status = 'RETURNED'
      
      save
    else
      errors.add(:base, "Failed to create return transaction")
      false
    end
  end
  
  # ========================================
  # HELPER METHODS
  # ========================================
  
  def quantity_variance
    quantity_required.to_d - quantity_consumed.to_d
  end
  
  def quantity_variance_percent
    return 0 if quantity_required.zero?
    ((quantity_variance / quantity_required.to_d) * 100).round(2)
  end
  
  def cost_variance
    planned_cost = (quantity_required.to_d * unit_cost.to_d)
    planned_cost - total_cost.to_d
  end
  
  def is_fully_consumed?
    quantity_consumed >= quantity_required
  end
  
  def is_over_consumed?
    quantity_consumed > quantity_required
  end
  
  def remaining_quantity
    (quantity_required.to_d - quantity_consumed.to_d).round(4)
  end
  
  def consumption_percentage
    return 0 if quantity_required.zero?
    ((quantity_consumed.to_d / quantity_required.to_d) * 100).round(2)
  end
  
  def status_badge_class
    case status
    when 'REQUIRED' then 'secondary'
    when 'ALLOCATED' then 'info'
    when 'ISSUED' then 'warning'
    when 'CONSUMED' then 'success'
    when 'RETURNED' then 'primary'
    else 'secondary'
    end
  end
  
  def display_name
    "#{product.sku} - #{product.name}"
  end
  
  # Soft delete
  def destroy!
    update_attribute(:deleted, true)
  end
end

# ============================================================
# Model 52: work_order_operation
# File: app/models/work_order_operation.rb
# ============================================================

# app/models/work_order_operation.rb

class WorkOrderOperation < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :work_order
  belongs_to :routing_operation
  belongs_to :work_center
  belongs_to :operator, class_name: "User", optional: true

  belongs_to :assigned_operator, class_name: 'User', foreign_key: 'assigned_operator_id', optional: true
  belongs_to :assigned_by, class_name: 'User', foreign_key: 'assigned_by_id', optional: true
  belongs_to :operator, class_name: 'User', foreign_key: 'operator_id', optional: true  # actual executor
  
  has_many :labor_time_entries, dependent: :destroy
  
  # ========================================
  # CONSTANTS
  # ========================================
  STATUSES = %w[PENDING IN_PROGRESS COMPLETED SKIPPED].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :sequence_no, presence: true
  validates :operation_name, presence: true
  validates :quantity_to_process, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  
  validates :quantity_completed, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_scrapped, numericality: { greater_than_or_equal_to: 0 }
  
  validate :total_quantity_cannot_exceed_to_process
  validate :valid_status_transition, on: :update
  validate :cannot_complete_without_time_tracking
  
  # ========================================
  # CALLBACKS
  # ========================================
  after_update :update_work_order_status, if: :saved_change_to_status?
  after_update :recalculate_actual_cost, if: :saved_change_to_actual_total_minutes?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :non_deleted, -> { where(deleted: false) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_work_center, ->(work_center_id) { where(work_center_id: work_center_id) }
  scope :pending, -> { where(status: 'PENDING') }
  scope :in_progress, -> { where(status: 'IN_PROGRESS') }
  scope :completed, -> { where(status: 'COMPLETED') }

  scope :assigned_to, ->(operator_id) { where(assigned_operator_id: operator_id) }
  scope :unassigned, -> { where(assigned_operator_id: nil) }
  scope :assigned, -> { where.not(assigned_operator_id: nil) }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  
  def total_quantity_cannot_exceed_to_process
    total = quantity_completed.to_d + quantity_scrapped.to_d
    if total > quantity_to_process.to_d
      errors.add(:base, "Total quantity (completed + scrapped) cannot exceed quantity to process")
    end
  end
  
  def valid_status_transition
    if status_changed?
      return if status_was.nil?
    
      valid_transitions = {
        'PENDING' => ['IN_PROGRESS', 'SKIPPED'],
        'IN_PROGRESS' => ['COMPLETED', 'PENDING'],
        'COMPLETED' => [],
        'SKIPPED' => ['PENDING']
      }
      
      allowed = valid_transitions[status_was] || []
      
      unless allowed.include?(status)
        errors.add(:status, "cannot transition from #{status_was} to #{status}")
      end
    end      
  end
  
  def cannot_complete_without_time_tracking
    return unless status == 'COMPLETED'
    
    if actual_total_minutes.to_i <= 0
      errors.add(:actual_total_minutes, "must be recorded before completing operation")
    end
  end
  
  # ========================================
  # CALLBACK METHODS
  # ========================================
  
  def update_work_order_status
    case status
    when 'IN_PROGRESS'
      # If this is first operation to start, update WO to IN_PROGRESS
      if work_order.status == 'RELEASED'
        work_order.update(status: 'IN_PROGRESS', actual_start_date: Time.current)
      end
      
      self.started_at ||= Time.current
      save if started_at_changed?
      
    when 'COMPLETED'
      self.completed_at = Time.current
      save if completed_at_changed?
      
      # If all operations completed, WO can be marked complete (manually by user)
      # work_order.check_for_completion
    end
  end
  
  def recalculate_actual_cost
    return if actual_total_minutes.to_i <= 0
    
    wc = work_center
    actual_hours = actual_total_minutes.to_d / 60
    
    self.actual_cost = (wc.total_cost_per_hour.to_d * actual_hours).round(2)
    save if actual_cost_changed?
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  def assign_to_operator!(operator, assigned_by:)
    self.assigned_operator = operator
    self.assigned_at = Time.current
    self.assigned_by = assigned_by
    save!
  end
  
  # Unassign operator
  def unassign_operator!
    self.assigned_operator = nil
    self.assigned_at = nil
    self.assigned_by = nil
    save!
  end
  
  # Check if assigned
  def assigned?
    assigned_operator_id.present?
  end
  
  # Can be assigned?
  def can_be_assigned?
    status.in?(['PENDING', 'IN_PROGRESS'])
  end

  def start_operation!(operator_user)
    return false unless status == 'PENDING'
    
    self.status = 'IN_PROGRESS'
    self.operator = operator_user
    self.started_at = Time.current
    save
  end
  
  def complete_operation!(actual_setup_mins, actual_run_mins, qty_completed, qty_scrapped = 0)
    return false unless status == 'IN_PROGRESS'
    
    self.actual_setup_minutes = actual_setup_mins
    self.actual_run_minutes = actual_run_mins
    self.actual_total_minutes = actual_setup_mins + actual_run_mins
    
    self.quantity_completed = qty_completed
    self.quantity_scrapped = qty_scrapped
    
    self.status = 'COMPLETED'
    self.completed_at = Time.current
    
    save
  end

  def current_clock_in
    labor_time_entries.active.order(clock_in_at: :desc).first
  end
  
  # Check if anyone is currently clocked in
  def has_active_clock_in?
    labor_time_entries.active.exists?
  end
  
  # Get total labor hours from all entries
  def total_labor_hours
    labor_time_entries.non_deleted.sum(:hours_worked)
  end
  
  # Get total labor minutes
  def total_labor_minutes
    (total_labor_hours * 60).round(0)
  end
  
  # Recalculate actual time from labor entries
  def recalculate_actual_time_from_labor_entries
    return unless status == 'COMPLETED'
    
    total_minutes = total_labor_minutes
    
    # Update actual times
    # Note: This assumes labor time includes both setup and run
    # You might want to track these separately
    self.actual_total_minutes = total_minutes
    
    # For now, we'll keep the manually entered setup time
    # and adjust run time
    if actual_setup_minutes.present?
      self.actual_run_minutes = total_minutes - actual_setup_minutes
    else
      self.actual_run_minutes = total_minutes
    end
    
    save if changed?
  end
  
  # Check if operation can be clocked into
  def can_clock_in?(operator)
    return false unless status.in?(['PENDING', 'IN_PROGRESS'])
    
    # Check if this operator is already clocked in to THIS operation
    return false if has_active_clock_in_by?(operator)
    
    # Check if operator is clocked in ANYWHERE else
    if LaborTimeEntry.operator_clocked_in?(operator.id)
      other_entry = LaborTimeEntry.current_for_operator(operator.id)
      return false if other_entry.work_order_operation_id != self.id
    end
    
    true
  end

  def has_active_clock_in_by?(operator)
    labor_time_entries.active.for_operator(operator.id).exists?
  end

  def can_be_completed?
    return false unless status == 'IN_PROGRESS'
    
    # Must not have any active clock-ins
    !has_active_clock_in?
  end

  def show_complete_button?(operator)
    return false unless status == 'IN_PROGRESS'
    return false if self.work_order.previous_in_progress_operations_before(self).present?
    # If operator is clocked in to THIS operation, don't show complete
    # They must clock out first
    return false if operator_clocked_in?(operator)
    
    true
  end

  # Should show clock in button?
  def show_clock_in_button?(operator)
    return false if self.assigned_operator != operator
    return false unless status.in?(['PENDING', 'IN_PROGRESS'])
    
    # Don't show if already clocked in to this operation
    return false if operator_clocked_in?(operator)
    
    # Don't show if clocked in elsewhere
    return false if LaborTimeEntry.operator_clocked_in?(operator.id)
    
    true
  end
  
  # Should show clock out button?
  def show_clock_out_button?(operator)
    return false if self.assigned_operator != operator
    operator_clocked_in?(operator)
  end
  
  # Get operator's current entry for this operation
  def current_entry_for_operator(operator)
    labor_time_entries.active.for_operator(operator.id).last
  end

  def operator_clocked_in?(operator)
    has_active_clock_in_by?(operator)
  end
  
  # Clock in an operator
  def clock_in_operator!(operator, entry_type: 'REGULAR', notes: nil)
    # Check if operator is already clocked in elsewhere
    if LaborTimeEntry.operator_clocked_in?(operator.id)
      existing = LaborTimeEntry.current_for_operator(operator.id)
      raise "Operator is already clocked in to Operation ##{existing.work_order_operation.sequence_no}"
    end
    
    # Start the operation if it's still pending
    if status == 'PENDING'
      self.status = 'IN_PROGRESS'
      self.started_at = Time.current
      self.operator = operator
      save!
    end
    
    # Create labor time entry
    labor_time_entries.create!(
      operator: operator,
      clock_in_at: Time.current,
      entry_type: entry_type,
      notes: notes
    )
  end
  
  # Clock out current operator
  def clock_out_operator!(operator)
    active_entry = labor_time_entries.active.for_operator(operator.id).last
    
    unless active_entry
      raise "No active clock-in found for this operator"
    end
    
    active_entry.clock_out!
    active_entry
  end
  
  # Get labor summary for display
  def labor_summary
    {
      total_entries: labor_time_entries.non_deleted.count,
      total_hours: total_labor_hours.round(2),
      regular_hours: labor_time_entries.non_deleted.regular.sum(:hours_worked).round(2),
      break_hours: labor_time_entries.non_deleted.breaks.sum(:hours_worked).round(2),
      unique_operators: labor_time_entries.non_deleted.distinct.count(:operator_id)
    }
  end
  
  # ========================================
  # HELPER METHODS
  # ========================================
  
  def time_variance_minutes
    planned_total_minutes - actual_total_minutes.to_i
  end
  
  def cost_variance
    planned_cost.to_d - actual_cost.to_d
  end
  
  def efficiency_percentage
    return 0 if actual_total_minutes.to_i.zero?
    ((planned_total_minutes.to_d / actual_total_minutes.to_d) * 100).round(2)
  end
  
  def progress_percentage
    return 0 if quantity_to_process.zero?
    ((quantity_completed.to_d / quantity_to_process.to_d) * 100).round(2)
  end
  
  def status_badge_class
    case status
    when 'PENDING' then 'secondary'
    when 'IN_PROGRESS' then 'warning'
    when 'COMPLETED' then 'success'
    when 'SKIPPED' then 'info'
    else 'secondary'
    end
  end
  
  # Soft delete
  def destroy!
    update_attribute(:deleted, true)
  end
end

# ==========================================
# End of Models
# ==========================================
