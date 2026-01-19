# frozen_string_literal: true

# ============================================================================
# MODEL: CustomerAddress
# ============================================================================
# Manages multiple addresses per customer (billing, shipping, warehouse, etc.)
# ============================================================================

class CustomerAddress < ApplicationRecord
  include OrganizationScoped
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :customer, inverse_of: :addresses
  belongs_to :created_by, class_name: "User", optional: true
  
  # ========================================
  # CONSTANTS
  # ========================================
  ADDRESS_TYPES = {
    "BILLING"   => "Billing Only",
    "SHIPPING"  => "Shipping Only",
    "BOTH"      => "Billing & Shipping",
    "WAREHOUSE" => "Warehouse/Pickup",
    "OTHER"     => "Other"
  }.freeze
  
  COUNTRIES = {
    "US" => "United States",
    "CA" => "Canada"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :address_type, presence: true, inclusion: { in: ADDRESS_TYPES.keys }
  validates :street_address_1, presence: true, length: { maximum: 255 }
  validates :street_address_2, length: { maximum: 255 }, allow_blank: true
  validates :city, presence: true, length: { maximum: 100 }
  validates :state_province, length: { maximum: 100 }, allow_blank: true
  validates :postal_code, presence: true, length: { maximum: 20 }
  validates :country, presence: true, inclusion: { in: COUNTRIES.keys }
  
  validates :address_label, length: { maximum: 100 }, allow_blank: true
  validates :attention_to, length: { maximum: 100 }, allow_blank: true
  validates :contact_phone, length: { maximum: 20 }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  
  # Only one default address per type per customer
  validates :is_default, uniqueness: { scope: [:customer_id, :address_type, :deleted], 
                                      message: "only one default address allowed per type" },
                        if: -> { is_default? && deleted == false }
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :normalize_data
  after_save :ensure_single_default, if: :saved_change_to_is_default?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :billing, -> { where(address_type: ["BILLING", "BOTH"], deleted: false) }
  scope :shipping, -> { where(address_type: ["SHIPPING", "BOTH"], deleted: false) }
  scope :defaults, -> { where(is_default: true, deleted: false) }
  scope :by_type, ->(type) { where(address_type: type, deleted: false) }
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  def full_address
    parts = [street_address_1]
    parts << street_address_2 if street_address_2.present?
    parts << "#{city}, #{state_province} #{postal_code}"
    parts << COUNTRIES[country]
    parts.join("\n")
  end
  
  def single_line_address
    parts = [street_address_1]
    parts << street_address_2 if street_address_2.present?
    parts << city
    parts << state_province if state_province.present?
    parts << postal_code
    parts << country
    parts.join(", ")
  end
  
  def display_label
    address_label.presence || ADDRESS_TYPES[address_type]
  end
  
  def can_use_for_billing?
    address_type.in?(["BILLING", "BOTH"])
  end
  
  def can_use_for_shipping?
    address_type.in?(["SHIPPING", "BOTH"])
  end
  
  def make_default!
    transaction do
      # Remove default from other addresses of same type
      self.class.where(customer_id: customer_id, address_type: address_type, is_default: true)
                .where.not(id: id)
                .update_all(is_default: false)
      
      update!(is_default: true)
    end
  end
  
  # ========================================
  # SOFT DELETE
  # ========================================
  
  def destroy!
    update_attribute(:deleted, true)
  end
  
  def restore!
    update_attribute(:deleted, false)
  end
  
  private
  
  def normalize_data
    self.postal_code = postal_code.upcase.strip if postal_code.present?
    self.country = country.upcase if country.present?
    self.contact_email = contact_email.downcase.strip if contact_email.present?
  end
  
  def ensure_single_default
    return unless is_default?
    
    # Unset default from other addresses of same type for this customer
    self.class.where(customer_id: customer_id, address_type: address_type, deleted: false)
              .where.not(id: id)
              .update_all(is_default: false)
  end
end