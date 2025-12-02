class Location < ApplicationRecord
  belongs_to :warehouse
  has_many :stock_issue_lines, foreign_key: :from_location_id
  
  # Soft delete flag
  scope :active, -> { where(deleted: false) }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :code, presence: true, length: { minimum: 2, maximum: 20 }

  # Code must be unique inside each warehouse
  validates :code, uniqueness: {
    scope: :warehouse_id,
    message: "must be unique inside the warehouse"
  }

  validates :is_pickable, inclusion: { in: [true, false] }
  validates :is_receivable, inclusion: { in: [true, false] }
end