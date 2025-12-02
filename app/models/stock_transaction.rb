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
    "RETURN_IN",
    "RETURN_OUT"
  ].freeze

  OUTFLOW_TYPES = %w[
    ISSUE
    TRANSFER_OUT
    ADJUST_NEG
    COUNT_CORRECTION
    PRODUCTION_CONSUMPTION
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
