class Product < ApplicationRecord
  belongs_to :product_category
  belongs_to :unit_of_measure
  has_many :bill_of_materials

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :reorder_point, numericality: {greater_than_or_equal_to: 0, message: "cannot be negative"}

  PRODUCT_TYPE_CHOICES = [
    'Raw Material',
    'Semi-Finished Goods',
    'Finished Goods',
    'Service',
    'Consumable'
  ]

  scope :bom_products, -> {where(product_type: ["Finished Goods", "Semi-Finished Goods"])}
  scope :bom_item_components, -> {where(product_type: ['Raw Material', 'Service', 'Consumable'])}


  validates :product_type, presence: true, inclusion: { in: PRODUCT_TYPE_CHOICES }
  # validate :validate_inventory_account
  validate :validate_batch_tracking
  validate :validate_serial_batch_conflict

  def validate_inventory_account
    if self.is_stocked && self.inventory_account.blank?
      errors.add(:inventory_account, "Stocked product must have an inventory account")
    end
  end

  def validate_batch_tracking
    if self.is_batch_tracked && !self.is_stocked
      errors.add(:is_batch_tracked, "Batch tracking allowed only for stocked products")
    end
  end

  def validate_serial_batch_conflict
    if self.is_serial_tracked && self.is_batch_tracked
      errors.add(:is_serial_tracked, "Enable either serial OR batch tracking, not both")
    end
  end

  def in_use_bill_of_material
    self.bill_of_materials.find_by(is_default: true, status: 'ACTIVE')
  end
  
  # show standard cost only for specific types
  def requires_standard_cost?
    ['Raw Material', 'Service', 'Consumable'].include?(self.product_type)
  end

  def can_have_bom?
    ['Finished Goods', 'Semi-Finished Goods'].include?(self.product_type)
  end


end