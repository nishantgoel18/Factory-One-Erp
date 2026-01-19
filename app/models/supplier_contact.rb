class SupplierContact < ApplicationRecord
  include OrganizationScoped
  belongs_to :supplier
  belongs_to :last_contacted_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  
  validates :first_name, :last_name, :email, :phone, presence: true
  validates :contact_role, presence: true, inclusion: { 
    in: %w[SALES TECHNICAL ACCOUNTS_PAYABLE QUALITY SHIPPING MANAGEMENT PRIMARY OTHER]
  }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  serialize :languages_spoken, type: Array, coder: JSON
  
  scope :active, -> { where(is_active: true) }
  scope :primary, -> { where(is_primary_contact: true) }
  scope :decision_makers, -> { where(is_decision_maker: true) }
  
  before_save :ensure_single_primary, if: :is_primary_contact?
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def name_with_title
    title.present? ? "#{full_name}, #{title}" : full_name
  end
  
  def make_primary!
    transaction do
      supplier.contacts.update_all(is_primary_contact: false)
      update!(is_primary_contact: true)
    end
  end
  
  def record_contact!(contacted_by_user)
    update!(
      last_contacted_at: Time.current,
      last_contacted_by: contacted_by_user,
      total_interactions_count: total_interactions_count + 1
    )
  end
  
  private
  
  def ensure_single_primary
    if is_primary_contact? && is_primary_contact_changed?
      supplier.contacts.where.not(id: id).update_all(is_primary_contact: false)
    end
  end
end