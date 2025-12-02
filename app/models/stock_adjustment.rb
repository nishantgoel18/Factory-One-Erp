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
