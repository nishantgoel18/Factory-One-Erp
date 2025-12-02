class StockLevel < ApplicationRecord
  belongs_to :product
  belongs_to :location
  belongs_to :batch, class_name: "StockBatch", optional: true

  validates :on_hand_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :reserved_qty, numericality: { greater_than_or_equal_to: 0 }
  validate :reserved_not_more_than_on_hand

  def reserved_not_more_than_on_hand
    return if reserved_qty.blank? || on_hand_qty.blank?

    if reserved_qty > on_hand_qty
      errors.add(:reserved_qty, "cannot be greater than on-hand quantity")
    end
  end

  # Safely adjust on-hand quantity (called from StockTransaction)
  def self.adjust_on_hand(product:, location:, batch:, delta_qty:)
    transaction do
      level = StockLevel.lock.find_or_create_by(
        product: product,
        location: location,
        batch: batch
      ) do |l|
        l.on_hand_qty = 0.to_d
        l.reserved_qty = 0.to_d
        l.deleted = false
      end

      new_qty = (level.on_hand_qty || 0.to_d) + delta_qty.to_d
      if new_qty < 0
        level.errors.add(:on_hand_qty, "would become negative")
        raise ActiveRecord::RecordInvalid.new(level)
      end

      level.on_hand_qty = new_qty
      level.save!
      level
    end
  end

  def self.adjust_reserved(product:, location:, batch:, delta_qty:)
    transaction do
      level = StockLevel.lock.find_or_create_by(
        product: product,
        location: location,
        batch: batch
      ) do |l|
        l.on_hand_qty = 0.to_d
        l.reserved_qty = 0.to_d
        l.deleted = false
      end

      new_reserved = (level.reserved_qty || 0.to_d) + delta_qty.to_d
      if new_reserved < 0
        level.errors.add(:reserved_qty, "would become negative")
        raise ActiveRecord::RecordInvalid.new(level)
      end
      if new_reserved > level.on_hand_qty
        level.errors.add(:reserved_qty, "cannot exceed on-hand quantity")
        raise ActiveRecord::RecordInvalid.new(level)
      end

      level.reserved_qty = new_reserved
      level.save!
      level
    end
  end
end
