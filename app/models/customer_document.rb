# frozen_string_literal: true

# ============================================================================
# MODEL: CustomerDocument
# ============================================================================
# Manages document attachments with ActiveStorage integration
# ============================================================================

class CustomerDocument < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :customer, inverse_of: :documents
  belongs_to :uploaded_by, class_name: "User", optional: true
  belongs_to :superseded_by_document, class_name: "CustomerDocument", foreign_key: :superseded_by_id, optional: true
  
  # ActiveStorage for file uploads
  has_one_attached :file
  
  # ========================================
  # CONSTANTS
  # ========================================
  DOCUMENT_TYPES = {
    "CONTRACT"         => "Contract/Agreement",
    "TAX_CERT"         => "Tax Exemption Certificate",
    "NDA"              => "Non-Disclosure Agreement",
    "CREDIT_APP"       => "Credit Application",
    "QUALITY_AGREEMENT"=> "Quality Agreement",
    "INSURANCE_CERT"   => "Insurance Certificate",
    "BUSINESS_LICENSE" => "Business License",
    "W9_FORM"          => "W-9 Form",
    "OTHER"            => "Other Document"
  }.freeze
  
  DOCUMENT_CATEGORIES = {
    "LEGAL"      => "Legal",
    "FINANCIAL"  => "Financial",
    "QUALITY"    => "Quality",
    "COMPLIANCE" => "Compliance",
    "GENERAL"    => "General"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES.keys }
  validates :document_category, inclusion: { in: DOCUMENT_CATEGORIES.keys }, allow_blank: true
  validates :document_title, presence: true, length: { maximum: 255 }
  validates :version, length: { maximum: 20 }, allow_blank: true
  
  validate :expiry_date_must_be_future, if: :effective_date
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_file_metadata, if: -> { file.attached? }
  after_save :check_for_expiry_alert
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :expired, -> { where("expiry_date < ?", Date.current).where(deleted: false) }
  scope :expiring_soon, ->(days = 30) { 
    where("expiry_date BETWEEN ? AND ?", Date.current, Date.current + days.days)
    .where(deleted: false, requires_renewal: true)
  }
  scope :by_type, ->(type) { where(document_type: type, deleted: false) }
  scope :by_category, ->(cat) { where(document_category: cat, deleted: false) }
  scope :latest_versions, -> { where(is_latest_version: true, deleted: false) }
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  def expired?
    expiry_date.present? && expiry_date < Date.current
  end
  
  def expiring_soon?(days = 30)
    return false unless expiry_date.present? && requires_renewal?
    expiry_date.between?(Date.current, Date.current + days.days)
  end
  
  def days_until_expiry
    return nil unless expiry_date.present?
    (expiry_date - Date.current).to_i
  end
  
  def file_attached?
    file.attached?
  end
  
  def file_url_or_attachment
    file_url.presence || (file.attached? ? Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true) : nil)
  end
  
  def supersede_with!(new_document)
    transaction do
      update!(
        is_latest_version: false,
        superseded_by_id: new_document.id,
        is_active: false
      )
      new_document.update!(
        version: increment_version,
        is_latest_version: true
      )
    end
  end
  
  def increment_version
    return "1.0" if version.blank?
    major, minor = version.split('.').map(&:to_i)
    "#{major}.#{minor + 1}"
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
  
  def set_file_metadata
    return unless file.attached?
    
    self.file_name = file.filename.to_s
    self.file_type = file.content_type
    self.file_size = file.byte_size
  end
  
  def expiry_date_must_be_future
    if expiry_date.present? && effective_date.present? && expiry_date < effective_date
      errors.add(:expiry_date, "must be after effective date")
    end
  end
  
  def check_for_expiry_alert
    return unless saved_change_to_expiry_date? && expiring_soon?(renewal_reminder_days)
    
    # TODO: Trigger alert/notification
    # ExpiryAlertJob.perform_later(self.id)
  end
end
