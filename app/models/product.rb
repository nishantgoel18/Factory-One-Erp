class Product < ApplicationRecord
  belongs_to :product_category
  belongs_to :unit_of_measure

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :reorder_point, numericality: {greater_than_or_equal_to: 0, message: "cannot be negative"}

  PRODUCT_TYPE_CHOICES = [
    'Raw Material',
    'Semi-Finished',
    'Finished Goods',
    'Service',
    'Consumable'
  ]

  validates :product_type, presence: true, inclusion: { in: PRODUCT_TYPE_CHOICES }

  # show standard cost only for specific types
  def requires_standard_cost?
    ['Raw Material', 'Service', 'Consumable'].include?(product_type)
  end
end