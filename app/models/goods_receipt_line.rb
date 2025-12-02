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
