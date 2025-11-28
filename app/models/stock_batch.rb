class StockBatch < ApplicationRecord
  belongs_to :product
  belongs_to :created_by, class_name: "User", optional: true

  # ------------------------------------
  # VALIDATIONS
  # ------------------------------------

  validates :batch_number, presence: true
  validates :batch_number, uniqueness: { scope: [:product_id, :deleted], message: "must be unique per product" }

  validate :expiry_not_before_manufacture
  validate :expiry_not_in_past_for_active_batch
  validate :product_must_be_batch_tracked
  validate :product_must_not_be_serial_tracked

  before_validation :assign_default_batch_number, on: :create

  def assign_default_batch_number
    return if batch_number.present?

    base = "#{product.sku}-#{Date.today.strftime("%Y%m%d")}"

    counter = 1
    new_code = base

    while StockBatch.where(product_id: product_id, batch_number: new_code, deleted: false).exists?
      counter += 1
      new_code = "#{base}-#{counter}"
    end

    self.batch_number = new_code
  end

  # Needed to run this using a cron or sidekiq daily.
  def auto_expire_if_needed
    if expiry_date.present? && expiry_date < Date.today
      update_column(:is_active, false)
    end
  end

  def expiry_not_before_manufacture
    return if expiry_date.blank? || manufacture_date.blank?

    if expiry_date < manufacture_date
      errors.add(:expiry_date, "cannot be before manufacture date")
    end
  end

  def expiry_not_in_past_for_active_batch
    return if expiry_date.blank? || !is_active?

    if expiry_date < Date.today
      errors.add(:expiry_date, "cannot be in the past for an active batch")
    end
  end

  def product_must_be_batch_tracked
    unless product.is_batch_tracked?
      errors.add(:product, "is not enabled for batch tracking")
    end
  end

  def product_must_not_be_serial_tracked
    if product.is_serial_tracked?
      errors.add(:product, "is serial tracked, not batch tracked")
    end
  end
end