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
