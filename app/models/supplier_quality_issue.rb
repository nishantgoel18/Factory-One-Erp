class SupplierQualityIssue < ApplicationRecord
  belongs_to :supplier
  belongs_to :product, optional: true
  belongs_to :reported_by, class_name: 'User', optional: true
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :related_issue, class_name: 'SupplierQualityIssue', optional: true
  
  has_many_attached :attachments
  
  validates :issue_title, :issue_description, :severity, :issue_date, presence: true
  validates :severity, inclusion: { in: %w[CRITICAL MAJOR MINOR] }
  validates :status, inclusion: { in: %w[OPEN IN_PROGRESS RESOLVED CLOSED RECURRING] }
  
  before_create :generate_issue_number
  after_create :notify_stakeholders
  after_update :update_supplier_rating, if: :saved_change_to_status?
  
  scope :open, -> { where(status: 'OPEN') }
  scope :critical, -> { where(severity: 'CRITICAL') }
  scope :resolved, -> { where(status: 'RESOLVED') }
  scope :closed, -> { where(status: 'CLOSED') }
  scope :repeat_issues, -> { where(is_repeat_issue: true) }
  
  def generate_issue_number
    last_issue = SupplierQualityIssue.order(issue_number: :desc).first
    if last_issue && last_issue.issue_number =~ /QI-(\d+)/
      next_number = $1.to_i + 1
    else
      next_number = 1
    end
    self.issue_number = "QI-#{next_number.to_s.rjust(5, '0')}"
  end
  
  def mark_resolved!(resolution_notes, resolved_by_user)
    update!(
      status: 'RESOLVED',
      resolution_date: Date.current,
      root_cause_analysis: resolution_notes,
      days_to_resolve: (Date.current - issue_date).to_i
    )
    
    supplier.log_activity!('ISSUE_RESOLUTION', "Quality Issue Resolved", 
                          "Issue #{issue_number} resolved", resolved_by_user)
  end
  
  def close!(closed_by_user)
    update!(
      status: 'CLOSED',
      closed_date: Date.current
    )
  end
  
  private
  
  def notify_stakeholders
    # Send email notifications (implement when mailer exists)
  end
  
  def update_supplier_rating
    return unless saved_change_to_status? && status == 'CLOSED'
    supplier.calculate_quality_performance!
    supplier.calculate_overall_rating!
  end
end
