class SupplierPerformanceReview < ApplicationRecord
  belongs_to :supplier
  belongs_to :reviewed_by, class_name: 'User', optional: true
  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :shared_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  
  validates :period_start_date, :period_end_date, :review_date, presence: true
  validates :review_type, inclusion: { in: %w[MONTHLY QUARTERLY SEMI_ANNUAL ANNUAL AD_HOC] }
  validates :review_status, inclusion: { in: %w[DRAFT COMPLETED APPROVED SHARED_WITH_SUPPLIER] }
  
  scope :by_period, ->(start_date, end_date) { where('period_start_date >= ? AND period_end_date <= ?', start_date, end_date) }
  scope :approved, -> { where(review_status: 'APPROVED') }
  scope :recent, -> { order(review_date: :desc) }
  
  def approve!(approved_by_user)
    update!(
      review_status: 'APPROVED',
      approved_by: approved_by_user,
      approved_date: Date.current
    )
  end
  
  def share_with_supplier!(shared_by_user)
    update!(
      shared_with_supplier: true,
      shared_date: Date.current,
      shared_by: shared_by_user
    )
  end
  
  def calculate_overall_score
    scores = [quality_score, delivery_score, cost_score, service_score, responsiveness_score].compact
    return 0 if scores.empty?
    (scores.sum / scores.size).round(2)
  end
end
