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
