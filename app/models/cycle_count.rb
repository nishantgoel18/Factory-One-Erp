class CycleCount < ApplicationRecord
  # ===================================
  # ASSOCIATIONS
  # ===================================
  belongs_to :warehouse
  belongs_to :scheduled_by, class_name: "User", optional: true
  belongs_to :counted_by, class_name: "User", optional: true
  belongs_to :posted_by, class_name: "User", optional: true
  
  has_many :lines,
           -> { where(deleted: false) },
           class_name: "CycleCountLine",
           foreign_key: "cycle_count_id",
           dependent: :destroy, :inverse_of  => :cycle_count
           
  accepts_nested_attributes_for :lines, allow_destroy: true
  
  # ===================================
  # CONSTANTS
  # ===================================
  STATUS_SCHEDULED   = 'SCHEDULED'
  STATUS_IN_PROGRESS = 'IN_PROGRESS'
  STATUS_COMPLETED   = 'COMPLETED'
  STATUS_POSTED      = 'POSTED'
  STATUS_CANCELLED   = 'CANCELLED'
  
  STATUSES = [
    STATUS_SCHEDULED,
    STATUS_IN_PROGRESS,
    STATUS_COMPLETED,
    STATUS_POSTED,
    STATUS_CANCELLED
  ].freeze
  
  COUNT_TYPES = {
    'FULL'       => 'Full Warehouse Count',
    'PARTIAL'    => 'Partial Count',
    'ABC_A'      => 'ABC Analysis - Class A',
    'ABC_B'      => 'ABC Analysis - Class B',
    'ABC_C'      => 'ABC Analysis - Class C',
    'SPOT_CHECK' => 'Random Spot Check',
    'LOCATION'   => 'Specific Location Count'
  }.freeze
  
  # ===================================
  # VALIDATIONS
  # ===================================
  validates :reference_no, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :scheduled_at, presence: true
  validates :warehouse_id, presence: true
  validates :count_type, inclusion: { in: COUNT_TYPES.keys }, allow_blank: true
  
  validate :must_have_lines
  validate :all_lines_must_be_counted_before_completion
  
  # ===================================
  # SCOPES
  # ===================================
  scope :active, -> { where(deleted: false) }
  scope :scheduled, -> { where(status: STATUS_SCHEDULED, deleted: false) }
  scope :in_progress, -> { where(status: STATUS_IN_PROGRESS, deleted: false) }
  scope :completed, -> { where(status: STATUS_COMPLETED, deleted: false) }
  scope :cancelled, -> { where(status: STATUS_CANCELLED, deleted: false) }

  scope :posted, -> { where(status: STATUS_POSTED, deleted: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  scope :upcoming, -> { where('scheduled_at > ?', Time.current).order(:scheduled_at) }
  scope :overdue, -> { where('scheduled_at < ? AND status = ?', Time.current, STATUS_SCHEDULED) }
  
  # ===================================
  # CALLBACKS
  # ===================================
  before_validation :generate_reference_no, on: :create
  before_validation :capture_system_quantities, if: :status_changed_to_in_progress?
  after_save :update_summary_stats, if: :saved_change_to_status?
  
  # ===================================
  # INSTANCE METHODS
  # ===================================
  
  def can_start_counting?
    status == STATUS_SCHEDULED
  end
  
  def can_complete?
    status == STATUS_IN_PROGRESS && all_lines_counted?
  end
  
  def can_post?
    status == STATUS_COMPLETED && has_variances?
  end
  
  def can_edit?
    [STATUS_SCHEDULED, STATUS_IN_PROGRESS].include?(status)
  end
  
  # Start the counting process
  def start_counting!(user:)
    raise "Cannot start - Count is not scheduled" unless can_start_counting?
    
    update!(
      status: STATUS_IN_PROGRESS,
      count_started_at: Time.current,
      counted_by: user
    )
  end
  
  # Mark as completed (all lines counted)
  def complete!(user:)
    raise "Cannot complete - Not all lines are counted" unless can_complete?
    
    CycleCount.transaction do
      # Calculate variances for all lines
      lines.each(&:calculate_variance!)
      
      update!(
        status: STATUS_COMPLETED,
        count_completed_at: Time.current
      )
    end
  end
  
  # Post count results - create adjustments for variances
  def post!(user:)
    raise "Cannot post - Count is not completed" unless can_post?
    
    CycleCount.transaction do
      lines.where(deleted: false).where.not(variance: 0).find_each do |line|
        # Create stock transaction for COUNT_CORRECTION
        txn_type = "COUNT_CORRECTION"
        
        # Determine from/to location based on variance
        if line.variance > 0
          # Positive variance = system mein kam tha, actual mein zyada hai
          # ADD stock to location
          from_loc = line.location  # ✅ Same location
          to_loc = line.location    # ✅ Same location
          qty = line.variance       # ✅ POSITIVE quantity (e.g., +20)
          
        else
          # Negative variance = system mein zyada tha, actual mein kam hai
          # REMOVE stock from location
          from_loc = line.location  # ✅ Same location
          to_loc = line.location    # ✅ Same location
          qty = line.variance       # ✅ NEGATIVE quantity (e.g., -15)
        end
        
        StockTransaction.create!(
          product: line.product,
          uom: line.uom,
          txn_type: txn_type,
          quantity: qty,
          from_location: from_loc,
          to_location: to_loc,
          batch: line.batch_if_applicable,
          reference_type: "CYCLE_COUNT",
          reference_id: id.to_s,
          note: "Cycle Count: #{reference_no} - Variance: #{line.variance}",
          created_by: user
        )
        
        # Mark line as adjusted
        line.update!(line_status: 'ADJUSTED')
      end
      
      # Update cycle count status
      update!(
        status: STATUS_POSTED,
        posted_at: Time.current,
        posted_by: user
      )
    end
    
    true
  rescue => e
    errors.add(:base, "Posting failed: #{e.message}")
    false
  end
  
  def all_lines_counted?
    lines.where(deleted: false).where("counted_qty IS NULL").empty?
  end
  
  def has_variances?
    lines.where(deleted: false).where.not(variance: 0).exists?
  end
  
  def total_variance_value
    lines.where(deleted: false).sum(:variance)
  end
  
  def accuracy_percentage
    return 100.0 if total_lines_count.zero?
    
    accurate_lines = total_lines_count - lines_with_variance_count
    (accurate_lines.to_f / total_lines_count * 100).round(2)
  end
  
  private
  
  def generate_reference_no
    return if reference_no.present?
    
    date_part = scheduled_at.strftime('%Y%m%d')
    random_part = SecureRandom.hex(3).upcase
    
    self.reference_no = "CC-#{date_part}-#{random_part}"
    
    # Ensure uniqueness
    counter = 1
    while CycleCount.where(reference_no: reference_no).exists?
      self.reference_no = "CC-#{date_part}-#{random_part}-#{counter}"
      counter += 1
    end
  end
  
  def status_changed_to_in_progress?
    status == STATUS_IN_PROGRESS && status_changed?
  end
  
  def capture_system_quantities
    lines.where(deleted: false).each do |line|
      line.capture_system_qty!
    end
  end
  
  def update_summary_stats
    self.total_lines_count = lines.where(deleted: false).count
    self.lines_with_variance_count = lines.where(deleted: false).where.not(variance: 0).count
    save if changed?
  end
  
  def must_have_lines
    if lines.where(deleted: false).empty? && !new_record?
      errors.add(:base, "Cycle count must have at least one line")
    end
  end
  
  def all_lines_must_be_counted_before_completion
    return unless status == STATUS_COMPLETED
    
    unless all_lines_counted?
      errors.add(:base, "All lines must be counted before marking as completed")
    end
  end
end