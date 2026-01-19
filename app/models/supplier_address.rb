class SupplierAddress < ApplicationRecord
  include OrganizationScoped
  belongs_to :supplier
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  
  validates :address_type, presence: true, inclusion: { in: %w[PRIMARY_OFFICE FACTORY WAREHOUSE BILLING RETURNS OTHER] }
  validates :street_address_1, :city, :postal_code, :country, presence: true
  
  serialize :equipment_available, type: Array, coder: JSON
  serialize :certifications_at_location, type: Array, coder: JSON
  
  scope :active, -> { where(is_active: true) }
  scope :default_addresses, -> { where(is_default: true) }
  scope :factories, -> { where(address_type: 'FACTORY') }
  scope :warehouses, -> { where(address_type: 'WAREHOUSE') }
  
  before_save :ensure_single_default, if: :is_default?
  
  def display_label
    address_label.presence || "#{address_type.titleize} Address"
  end
  
  def full_address
    [street_address_1, street_address_2, city, state_province, postal_code, country].compact.join(', ')
  end
  
  def single_line_address
    [street_address_1, city, state_province, postal_code].compact.join(', ')
  end
  
  def make_default!
    transaction do
      supplier.addresses.where(address_type: address_type).update_all(is_default: false)
      update!(is_default: true)
    end
  end
  
  private
  
  def ensure_single_default
    if is_default? && is_default_changed?
      supplier.addresses.where(address_type: address_type).where.not(id: id).update_all(is_default: false)
    end
  end
end