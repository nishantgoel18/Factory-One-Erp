# frozen_string_literal: true

# ============================================================================
# MODEL: CustomerContact
# ============================================================================
# Manages multiple contact persons per customer with roles and communication prefs
# ============================================================================

class CustomerContact < ApplicationRecord
  include OrganizationScoped
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :customer, inverse_of: :contacts
  belongs_to :created_by, class_name: "User", optional: true
  
  has_many :activities, 
           class_name: "CustomerActivity",
           foreign_key: :customer_contact_id,
           dependent: :nullify
  
  # ========================================
  # CONSTANTS
  # ========================================
  CONTACT_ROLES = {
    "PRIMARY"        => "Primary Contact",
    "PURCHASING"     => "Purchasing",
    "FINANCE"        => "Finance/Accounts Payable",
    "TECHNICAL"      => "Technical/Engineering",
    "SHIPPING"       => "Shipping/Receiving",
    "DECISION_MAKER" => "Decision Maker",
    "QUALITY"        => "Quality Assurance",
    "MANAGEMENT"     => "Management",
    "OTHER"          => "Other"
  }.freeze
  
  CONTACT_METHODS = {
    "EMAIL" => "Email",
    "PHONE" => "Phone",
    "BOTH"  => "Email & Phone",
    "SMS"   => "SMS"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :contact_role, presence: true, inclusion: { in: CONTACT_ROLES.keys }
  
  validates :title, :department, length: { maximum: 100 }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true, length: { maximum: 255 }
  validates :phone, :mobile, :fax, length: { maximum: 20 }, allow_blank: true
  validates :extension, length: { maximum: 10 }, allow_blank: true
  validates :skype_id, length: { maximum: 100 }, allow_blank: true
  
  validates :preferred_contact_method, inclusion: { in: CONTACT_METHODS.keys }, allow_blank: true
  
  # Only one primary contact per customer
  validates :is_primary_contact, uniqueness: { scope: [:customer_id, :deleted],
                                              message: "only one primary contact allowed" },
                                if: -> { is_primary_contact? && deleted == false }
  
  # At least email or phone must be present
  validate :must_have_contact_method
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :normalize_data
  after_save :ensure_single_primary, if: :saved_change_to_is_primary_contact?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :primary, -> { where(is_primary_contact: true, deleted: false) }
  scope :decision_makers, -> { where(is_decision_maker: true, deleted: false) }
  scope :by_role, ->(role) { where(contact_role: role, deleted: false) }
  scope :by_department, ->(dept) { where(department: dept, deleted: false) }
  
  scope :search, ->(query) {
    where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR title ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
  }
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def full_name_with_title
    parts = [full_name]
    parts << title if title.present?
    parts.join(" - ")
  end
  
  def display_name
    parts = [full_name]
    parts << "(#{title})" if title.present?
    parts << "[#{CONTACT_ROLES[contact_role]}]"
    parts.join(" ")
  end
  
  def primary_email
    email.presence || customer.email
  end
  
  def primary_phone
    phone.presence || mobile.presence || customer.phone_number
  end
  
  def can_receive_orders?
    contact_role.in?(["PRIMARY", "PURCHASING", "MANAGEMENT", "DECISION_MAKER"])
  end
  
  def can_receive_invoices?
    contact_role.in?(["PRIMARY", "FINANCE", "MANAGEMENT"]) || receive_invoice_copies?
  end
  
  def make_primary!
    transaction do
      # Remove primary from other contacts
      self.class.where(customer_id: customer_id, is_primary_contact: true, deleted: false)
                .where.not(id: id)
                .update_all(is_primary_contact: false)
      
      update!(is_primary_contact: true, is_active: true)
    end
  end
  
  def log_interaction!(notes:, method: "PHONE")
    update!(
      last_contacted_at: Time.current,
      last_contacted_by: Current.user&.email || "System",
      last_interaction_notes: notes
    )
  end
  
  def has_birthday_soon?(days = 7)
    return false if birthday.blank?
    
    today = Date.current
    this_year_birthday = Date.new(today.year, birthday.month, birthday.day)
    
    (this_year_birthday - today).to_i.between?(0, days)
  end
  
  # ========================================
  # SOFT DELETE
  # ========================================
  
  def destroy!
    # If deleting primary contact, make another contact primary
    if is_primary_contact?
      next_contact = customer.contacts.where.not(id: id).first
      next_contact&.make_primary!
    end
    
    update_attribute(:deleted, true)
  end
  
  def restore!
    update_attribute(:deleted, false)
  end
  
  private
  
  def normalize_data
    self.first_name = first_name.strip.titleize if first_name.present?
    self.last_name = last_name.strip.titleize if last_name.present?
    self.email = email.downcase.strip if email.present?
  end
  
  def must_have_contact_method
    if email.blank? && phone.blank? && mobile.blank?
      errors.add(:base, "Must provide at least email, phone, or mobile number")
    end
  end
  
  def ensure_single_primary
    return unless is_primary_contact?
    
    # Unset primary from other contacts for this customer
    self.class.where(customer_id: customer_id, deleted: false)
              .where.not(id: id)
              .update_all(is_primary_contact: false)
  end
end
