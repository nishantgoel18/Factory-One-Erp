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
