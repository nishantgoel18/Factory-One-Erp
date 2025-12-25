class SupplierActivity < ApplicationRecord
  belongs_to :supplier
  belongs_to :supplier_contact, optional: true
  belongs_to :related_user, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :related_record, polymorphic: true, optional: true
  
  validates :activity_type, presence: true
  validates :subject, presence: true
  validates :activity_date, presence: true
  
  serialize :tags, type: Array, coder: JSON
  
  scope :recent, -> { order(activity_date: :desc) }
  scope :by_type, ->(type) { where(activity_type: type) }
  scope :completed, -> { where(activity_status: 'COMPLETED') }
  scope :scheduled, -> { where(activity_status: 'SCHEDULED') }
  scope :overdue, -> { where(is_overdue: true) }
  
  def mark_completed!(outcome = nil, completed_by_user)
    update!(
      activity_status: 'COMPLETED',
      outcome: outcome,
      is_overdue: false
    )
  end
  
  def reschedule!(new_date)
    update!(activity_date: new_date, is_overdue: false)
  end
end
