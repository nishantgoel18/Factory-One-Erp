class Location < ApplicationRecord
  LOCATION_TYPES = %w[RAW_MATERIALS WIP FINISHED_GOODS QUARANTINE SCRAP STAGING GENERAL].freeze

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

  validates :location_type, inclusion: { in: LOCATION_TYPES }

  scope :raw_materials, -> { where(location_type: 'RAW_MATERIALS') }
  scope :finished_goods, -> { where(location_type: 'FINISHED_GOODS') }
end