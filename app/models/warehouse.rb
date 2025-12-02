class Warehouse < ApplicationRecord
  # Basic presence validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :code, presence: true, uniqueness: true, length: { minimum: 2, maximum: 20 }

  # Address optional but length control
  validates :address, length: { maximum: 500 }, allow_blank: true

  has_many :stock_issues
end
