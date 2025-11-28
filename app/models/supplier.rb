class Supplier < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  # Soft delete default
  attribute :deleted, :boolean, default: false
  attribute :is_active, :boolean, default: true
  attribute :lead_time_days, :integer, default: 7
  attribute :on_time_delivery_rate, :decimal, default: 100.00

  validates :code, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :name, presence: true, length: { maximum: 255 }

  validates :email, 
            allow_blank: true, 
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :phone, length: { maximum: 50 }, allow_blank: true

  validates :billing_address, presence: true

  validates :lead_time_days,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :on_time_delivery_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(deleted: false) }

  def to_s
    "#{code} - #{name}"
  end
end