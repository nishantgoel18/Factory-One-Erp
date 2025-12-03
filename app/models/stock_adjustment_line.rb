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
