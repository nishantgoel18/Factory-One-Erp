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
