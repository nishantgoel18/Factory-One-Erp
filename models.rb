# ==========================================
# All Rails Models - Merged for AI Context
# Generated: 2025-12-08 01:09:28 +0530
# Total Models: 37
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

# ============================================================
# Model 6: cycle_count
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
# Model 7: cycle_count_line
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
# Model 8: goods_receipt
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
# Model 9: goods_receipt_line
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
# Model 10: journal_entry
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
# Model 11: journal_line
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
# Model 12: labor_time_entry
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
# Model 13: location
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
# Model 14: product
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
# Model 15: product_category
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
# Model 16: purchase_order
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
# Model 17: purchase_order_line
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
# Model 18: routing
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
# Model 19: routing_operation
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
# Model 20: stock_adjustment
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
# Model 21: stock_adjustment_line
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
# Model 22: stock_batch
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
# Model 23: stock_issue
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
# Model 24: stock_issue_line
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
# Model 25: stock_level
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
# Model 26: stock_transaction
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
# Model 27: stock_transfer
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
# Model 28: stock_transfer_line
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
# Model 29: supplier
# File: app/models/supplier.rb
# ============================================================

class Supplier < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  # Soft delete default
  attribute :deleted, :boolean, default: false
  attribute :is_active, :boolean, default: true
  attribute :lead_time_days, :integer, default: 7
  attribute :on_time_delivery_rate, :decimal, default: 100.00

  validates :code, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :name, presence: true, length: { maximum: 255 }

  validates :email, 
            allow_blank: true, 
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :phone, length: { maximum: 50 }, allow_blank: true

  validates :billing_address, presence: true

  validates :lead_time_days,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :on_time_delivery_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(deleted: false) }

  def to_s
    "#{code} - #{name}"
  end
end

# ============================================================
# Model 30: tax_code
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
# Model 31: unit_of_measure
# File: app/models/unit_of_measure.rb
# ============================================================

class UnitOfMeasure < ApplicationRecord

  validates_uniqueness_of :name, :symbol
  validates :name, presence: true, length: { maximum: 100 }
  validates :symbol, presence: true, length: { maximum: 10 } 

end

# ============================================================
# Model 32: user
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
# Model 33: warehouse
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
# Model 34: work_center
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
# Model 35: work_order
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
# Model 36: work_order_material
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
# Model 37: work_order_operation
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
