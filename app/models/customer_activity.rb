class CustomerActivity < ApplicationRecord
  include OrganizationScoped
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :customer, inverse_of: :activities, touch: :last_activity_date
  belongs_to :customer_contact, optional: true
  belongs_to :related_user, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  
  # Polymorphic association for linking to orders, quotes, etc.
  belongs_to :related_entity, polymorphic: true, optional: true
  
  # ========================================
  # CONSTANTS
  # ========================================
  ACTIVITY_TYPES = {
    "CALL"      => "Phone Call",
    "EMAIL"     => "Email",
    "MEETING"   => "Meeting",
    "NOTE"      => "Note/Comment",
    "QUOTE"     => "Quote Sent",
    "ORDER"     => "Order Placed",
    "COMPLAINT" => "Complaint/Issue",
    "VISIT"     => "Site Visit",
    "FOLLOWUP"  => "Follow-up"
  }.freeze
  
  ACTIVITY_STATUSES = {
    "SCHEDULED" => "Scheduled",
    "COMPLETED" => "Completed",
    "CANCELLED" => "Cancelled",
    "OVERDUE"   => "Overdue"
  }.freeze
  
  OUTCOMES = {
    "SUCCESS"      => "Successful",
    "NO_ANSWER"    => "No Answer",
    "VOICEMAIL"    => "Left Voicemail",
    "RESCHEDULED"  => "Rescheduled",
    "NOT_INTERESTED" => "Not Interested",
    "PENDING"      => "Pending Response",
    "RESOLVED"     => "Resolved",
    "ESCALATED"    => "Escalated"
  }.freeze
  
  COMMUNICATION_METHODS = {
    "PHONE"      => "Phone",
    "EMAIL"      => "Email",
    "IN_PERSON"  => "In Person",
    "VIDEO_CALL" => "Video Call",
    "SMS"        => "SMS",
    "PORTAL"     => "Customer Portal"
  }.freeze
  
  DIRECTIONS = {
    "INBOUND"  => "Inbound",
    "OUTBOUND" => "Outbound"
  }.freeze
  
  SENTIMENTS = {
    "POSITIVE" => "Positive",
    "NEUTRAL"  => "Neutral",
    "NEGATIVE" => "Negative",
    "URGENT"   => "Urgent"
  }.freeze
  
  PRIORITIES = {
    "LOW"    => "Low",
    "NORMAL" => "Normal",
    "HIGH"   => "High",
    "URGENT" => "Urgent"
  }.freeze
  
  CATEGORIES = {
    "SALES"   => "Sales",
    "SUPPORT" => "Support",
    "BILLING" => "Billing",
    "GENERAL" => "General"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES.keys }
  validates :activity_status, inclusion: { in: ACTIVITY_STATUSES.keys }, allow_blank: true
  validates :subject, presence: true, length: { maximum: 255 }
  validates :activity_date, presence: true
  
  validates :outcome, inclusion: { in: OUTCOMES.keys }, allow_blank: true
  validates :communication_method, inclusion: { in: COMMUNICATION_METHODS.keys }, allow_blank: true
  validates :direction, inclusion: { in: DIRECTIONS.keys }, allow_blank: true
  validates :customer_sentiment, inclusion: { in: SENTIMENTS.keys }, allow_blank: true
  validates :priority, inclusion: { in: PRIORITIES.keys }, allow_blank: true
  validates :category, inclusion: { in: CATEGORIES.keys }, allow_blank: true
  
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_defaults, on: :create
  after_save :check_for_followup_reminder
  
  # ========================================
  # SCOPES
  # ========================================
  scope :completed, -> { where(activity_status: "COMPLETED", deleted: false) }
  scope :scheduled, -> { where(activity_status: "SCHEDULED", deleted: false) }
  scope :overdue, -> { where("followup_date < ? AND activity_status = ?", Date.current, "SCHEDULED").where(deleted: false) }
  scope :requires_followup, -> { where(followup_required: true, deleted: false) }
  
  scope :by_type, ->(type) { where(activity_type: type, deleted: false) }
  scope :by_user, ->(user_id) { where(related_user_id: user_id, deleted: false) }
  scope :by_date_range, ->(start_date, end_date) { where(activity_date: start_date..end_date, deleted: false) }
  scope :this_week, -> { where(activity_date: Date.current.beginning_of_week..Date.current.end_of_week, deleted: false) }
  scope :this_month, -> { where(activity_date: Date.current.beginning_of_month..Date.current.end_of_month, deleted: false) }
  
  scope :urgent, -> { where(priority: "URGENT", deleted: false) }
  scope :negative_sentiment, -> { where(customer_sentiment: "NEGATIVE", deleted: false) }
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  def is_overdue?
    activity_status == "SCHEDULED" && followup_date.present? && followup_date < Date.current
  end
  
  def mark_completed!(outcome_value = nil, notes = nil)
    update!(
      activity_status: "COMPLETED",
      outcome: outcome_value,
      description: [description, notes].compact.join("\n\n")
    )
  end
  
  def reschedule!(new_date)
    update!(
      followup_date: new_date,
      activity_status: "SCHEDULED",
      outcome: "RESCHEDULED"
    )
  end
  
  def contact_name
    customer_contact&.full_name || "General"
  end
  
  def user_name
    related_user&.email || created_by&.email || "System"
  end
  
  def status_badge_class
    case activity_status
    when "COMPLETED" then "success"
    when "SCHEDULED" then "primary"
    when "CANCELLED" then "secondary"
    when "OVERDUE" then "danger"
    else "secondary"
    end
  end
  
  def priority_badge_class
    case priority
    when "LOW" then "secondary"
    when "NORMAL" then "primary"
    when "HIGH" then "warning"
    when "URGENT" then "danger"
    else "secondary"
    end
  end
  
  def sentiment_badge_class
    case customer_sentiment
    when "POSITIVE" then "success"
    when "NEUTRAL" then "secondary"
    when "NEGATIVE" then "danger"
    when "URGENT" then "warning"
    else "secondary"
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
  
  def set_defaults
    self.activity_status ||= "COMPLETED"
    self.priority ||= "NORMAL"
    self.category ||= "GENERAL"
    self.activity_date ||= Time.current
  end
  
  def check_for_followup_reminder
    return unless saved_change_to_followup_date? && followup_required? && !reminder_sent?
    
    # TODO: Schedule reminder
    # FollowupReminderJob.set(wait_until: followup_date).perform_later(self.id)
  end
end
