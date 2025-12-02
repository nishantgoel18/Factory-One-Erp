class StockIssue < ApplicationRecord
  belongs_to :warehouse
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :posted_by, class_name: "User", optional: true
  
  has_many :lines, 
           -> { where(deleted: false) },
           class_name: "StockIssueLine",
           foreign_key: "stock_issue_id",
           dependent: :destroy,
           inverse_of: :stock_issue
  accepts_nested_attributes_for :lines, allow_destroy: true

  STATUS_DRAFT  = 'DRAFT'
  STATUS_POSTED = 'POSTED'
  STATUSES = [STATUS_DRAFT, STATUS_POSTED].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :warehouse_id, presence: true

  before_validation :generate_reference_no

  scope :active, -> { where(deleted: false) }
  scope :draft, -> { where(status: STATUS_DRAFT, deleted: false) }
  scope :posted, -> { where(status: STATUS_POSTED, deleted: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }

  def can_post?
    status == STATUS_DRAFT && lines.exists?
  end
  
  def can_edit?
    status == STATUS_DRAFT
  end

  def posted?
    status == STATUS_POSTED
  end

  private

  def generate_reference_no
    self.reference_no ||= "ISS-#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end
