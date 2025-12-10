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
  serialize :manufacturing_processes, Array
  serialize :quality_control_capabilities, Array
  serialize :testing_capabilities, Array
  serialize :materials_specialization, Array
  serialize :geographic_coverage, Array
  serialize :factory_locations, Array
  serialize :certifications, Array
  serialize :risk_factors, Array
  
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