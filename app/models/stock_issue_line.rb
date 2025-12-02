class StockIssueLine < ApplicationRecord
  belongs_to :stock_issue, inverse_of: :lines
  belongs_to :product
  belongs_to :stock_batch, optional: true
  belongs_to :from_location, class_name: "Location"

  validates :quantity, numericality: { greater_than: 0 }

  validate :batch_required_if_tracked

  def batch_required_if_tracked
    return unless product

    if (product.is_batch_tracked || product.is_serial_tracked) && stock_batch_id.nil?
      errors.add(:stock_batch, "is required for this product")
    end
  end

  after_initialize do
    self.deleted ||= false
  end

  private

  def location_must_be_pickable
    if from_location && !from_location.is_pickable?
      errors.add(:from_location, "must be a pickable location")
    end
  end
end
