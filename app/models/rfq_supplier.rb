# ============================================================================
# MODEL: RfqSupplier (Join table with invitation tracking)
# ============================================================================
class RfqSupplier < ApplicationRecord
  include OrganizationScoped
  belongs_to :rfq
  belongs_to :supplier
  belongs_to :supplier_contact, optional: true
  belongs_to :invited_by, class_name: 'User', optional: true
  
  has_many :vendor_quotes, dependent: :destroy
  
  validates :rfq_id, uniqueness: { scope: :supplier_id }
  
  scope :invited, -> { where(invitation_status: 'INVITED') }
  scope :quoted, -> { where(invitation_status: 'QUOTED') }
  scope :declined, -> { where(invitation_status: 'DECLINED') }
  scope :no_response, -> { where(invitation_status: 'NO_RESPONSE') }
  scope :selected, -> { where(is_selected: true) }
  
  def mark_quoted!
    update!(
      invitation_status: 'QUOTED',
      quoted_at: Time.current,
      response_time_hours: calculate_response_time
    )
    
    check_response_timeliness!
  end
  
  def mark_declined!(reason)
    update!(
      invitation_status: 'DECLINED',
      declined_at: Time.current,
      decline_reason: reason
    )
  end
  
  def mark_no_response!
    update!(invitation_status: 'NO_RESPONSE')
  end
  
  def calculate_response_time
    return nil unless invited_at
    ((Time.current - invited_at) / 1.hour).to_i
  end
  
  def check_response_timeliness!
    return unless rfq.response_deadline && quoted_at
    
    if quoted_at.to_date > rfq.response_deadline
      days_late = (quoted_at.to_date - rfq.response_deadline).to_i
      update!(responded_on_time: false, days_overdue: days_late)
    end
  end
  
  def calculate_quote_summary!
    quotes = vendor_quotes.where(is_latest_revision: true)
    
    update!(
      total_quoted_amount: quotes.sum(:total_price),
      items_quoted_count: quotes.count,
      items_not_quoted_count: rfq.rfq_items.count - quotes.count,
      quoted_all_items: quotes.count == rfq.rfq_items.count
    )
  end
end
