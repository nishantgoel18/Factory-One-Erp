class SupplierDocument < ApplicationRecord
  include OrganizationScoped
  belongs_to :supplier
  belongs_to :uploaded_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :superseded_by, class_name: 'SupplierDocument', optional: true
  
  mount_uploader :file, AttachmentUploader
  
  validates :document_type, presence: true
  validates :document_title, presence: true
  
  scope :active, -> { where(is_active: true) }
  scope :expired, -> { where('expiry_date < ?', Date.current) }
  scope :expiring_soon, ->(days = 30) { where('expiry_date BETWEEN ? AND ?', Date.current, days.days.from_now) }
  scope :by_type, ->(type) { where(document_type: type) }
  
  def expired?
    expiry_date.present? && expiry_date < Date.current
  end
  
  def expiring_soon?(days = 30)
    expiry_date.present? && expiry_date.between?(Date.current, days.days.from_now)
  end
  
  def days_until_expiry
    return nil unless expiry_date.present?
    (expiry_date - Date.current).to_i
  end
  
  def file_attached?
    file.attached?
  end
  
  def file_name
    file.attached? ? file.filename.to_s : super
  end
  
  def file_size
    file.attached? ? file.byte_size : super
  end
end

