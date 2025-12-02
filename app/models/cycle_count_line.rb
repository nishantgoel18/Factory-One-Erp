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
