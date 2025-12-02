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
