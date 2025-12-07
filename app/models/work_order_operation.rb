# app/models/work_order_operation.rb

class WorkOrderOperation < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :work_order
  belongs_to :routing_operation
  belongs_to :work_center
  belongs_to :operator, class_name: "User", optional: true

  belongs_to :assigned_operator, class_name: 'User', foreign_key: 'assigned_operator_id', optional: true
  belongs_to :assigned_by, class_name: 'User', foreign_key: 'assigned_by_id', optional: true
  belongs_to :operator, class_name: 'User', foreign_key: 'operator_id', optional: true  # actual executor
  
  has_many :labor_time_entries, dependent: :destroy
  
  # ========================================
  # CONSTANTS
  # ========================================
  STATUSES = %w[PENDING IN_PROGRESS COMPLETED SKIPPED].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :sequence_no, presence: true
  validates :operation_name, presence: true
  validates :quantity_to_process, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  
  validates :quantity_completed, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_scrapped, numericality: { greater_than_or_equal_to: 0 }
  
  validate :total_quantity_cannot_exceed_to_process
  validate :valid_status_transition, on: :update
  validate :cannot_complete_without_time_tracking
  
  # ========================================
  # CALLBACKS
  # ========================================
  after_update :update_work_order_status, if: :saved_change_to_status?
  after_update :recalculate_actual_cost, if: :saved_change_to_actual_total_minutes?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :non_deleted, -> { where(deleted: false) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_work_center, ->(work_center_id) { where(work_center_id: work_center_id) }
  scope :pending, -> { where(status: 'PENDING') }
  scope :in_progress, -> { where(status: 'IN_PROGRESS') }
  scope :completed, -> { where(status: 'COMPLETED') }

  scope :assigned_to, ->(operator_id) { where(assigned_operator_id: operator_id) }
  scope :unassigned, -> { where(assigned_operator_id: nil) }
  scope :assigned, -> { where.not(assigned_operator_id: nil) }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  
  def total_quantity_cannot_exceed_to_process
    total = quantity_completed.to_d + quantity_scrapped.to_d
    if total > quantity_to_process.to_d
      errors.add(:base, "Total quantity (completed + scrapped) cannot exceed quantity to process")
    end
  end
  
  def valid_status_transition
    if status_changed?
      return if status_was.nil?
    
      valid_transitions = {
        'PENDING' => ['IN_PROGRESS', 'SKIPPED'],
        'IN_PROGRESS' => ['COMPLETED', 'PENDING'],
        'COMPLETED' => [],
        'SKIPPED' => ['PENDING']
      }
      
      allowed = valid_transitions[status_was] || []
      
      unless allowed.include?(status)
        errors.add(:status, "cannot transition from #{status_was} to #{status}")
      end
    end      
  end
  
  def cannot_complete_without_time_tracking
    return unless status == 'COMPLETED'
    
    if actual_total_minutes.to_i <= 0
      errors.add(:actual_total_minutes, "must be recorded before completing operation")
    end
  end
  
  # ========================================
  # CALLBACK METHODS
  # ========================================
  
  def update_work_order_status
    case status
    when 'IN_PROGRESS'
      # If this is first operation to start, update WO to IN_PROGRESS
      if work_order.status == 'RELEASED'
        work_order.update(status: 'IN_PROGRESS', actual_start_date: Time.current)
      end
      
      self.started_at ||= Time.current
      save if started_at_changed?
      
    when 'COMPLETED'
      self.completed_at = Time.current
      save if completed_at_changed?
      
      # If all operations completed, WO can be marked complete (manually by user)
      # work_order.check_for_completion
    end
  end
  
  def recalculate_actual_cost
    return if actual_total_minutes.to_i <= 0
    
    wc = work_center
    actual_hours = actual_total_minutes.to_d / 60
    
    self.actual_cost = (wc.total_cost_per_hour.to_d * actual_hours).round(2)
    save if actual_cost_changed?
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  def assign_to_operator!(operator, assigned_by:)
    self.assigned_operator = operator
    self.assigned_at = Time.current
    self.assigned_by = assigned_by
    save!
  end
  
  # Unassign operator
  def unassign_operator!
    self.assigned_operator = nil
    self.assigned_at = nil
    self.assigned_by = nil
    save!
  end
  
  # Check if assigned
  def assigned?
    assigned_operator_id.present?
  end
  
  # Can be assigned?
  def can_be_assigned?
    status.in?(['PENDING', 'IN_PROGRESS'])
  end

  def start_operation!(operator_user)
    return false unless status == 'PENDING'
    
    self.status = 'IN_PROGRESS'
    self.operator = operator_user
    self.started_at = Time.current
    save
  end
  
  def complete_operation!(actual_setup_mins, actual_run_mins, qty_completed, qty_scrapped = 0)
    return false unless status == 'IN_PROGRESS'
    
    self.actual_setup_minutes = actual_setup_mins
    self.actual_run_minutes = actual_run_mins
    self.actual_total_minutes = actual_setup_mins + actual_run_mins
    
    self.quantity_completed = qty_completed
    self.quantity_scrapped = qty_scrapped
    
    self.status = 'COMPLETED'
    self.completed_at = Time.current
    
    save
  end

  def current_clock_in
    labor_time_entries.active.order(clock_in_at: :desc).first
  end
  
  # Check if anyone is currently clocked in
  def has_active_clock_in?
    labor_time_entries.active.exists?
  end
  
  # Get total labor hours from all entries
  def total_labor_hours
    labor_time_entries.non_deleted.sum(:hours_worked)
  end
  
  # Get total labor minutes
  def total_labor_minutes
    (total_labor_hours * 60).round(0)
  end
  
  # Recalculate actual time from labor entries
  def recalculate_actual_time_from_labor_entries
    return unless status == 'COMPLETED'
    
    total_minutes = total_labor_minutes
    
    # Update actual times
    # Note: This assumes labor time includes both setup and run
    # You might want to track these separately
    self.actual_total_minutes = total_minutes
    
    # For now, we'll keep the manually entered setup time
    # and adjust run time
    if actual_setup_minutes.present?
      self.actual_run_minutes = total_minutes - actual_setup_minutes
    else
      self.actual_run_minutes = total_minutes
    end
    
    save if changed?
  end
  
  # Check if operation can be clocked into
  def can_clock_in?(operator)
    return false unless status.in?(['PENDING', 'IN_PROGRESS'])
    
    # Check if this operator is already clocked in to THIS operation
    return false if has_active_clock_in_by?(operator)
    
    # Check if operator is clocked in ANYWHERE else
    if LaborTimeEntry.operator_clocked_in?(operator.id)
      other_entry = LaborTimeEntry.current_for_operator(operator.id)
      return false if other_entry.work_order_operation_id != self.id
    end
    
    true
  end

  def has_active_clock_in_by?(operator)
    labor_time_entries.active.for_operator(operator.id).exists?
  end

  def can_be_completed?
    return false unless status == 'IN_PROGRESS'
    
    # Must not have any active clock-ins
    !has_active_clock_in?
  end

  def show_complete_button?(operator)
    return false unless status == 'IN_PROGRESS'
    return false if self.work_order.previous_in_progress_operations_before(self).present?
    # If operator is clocked in to THIS operation, don't show complete
    # They must clock out first
    return false if operator_clocked_in?(operator)
    
    true
  end

  # Should show clock in button?
  def show_clock_in_button?(operator)
    return false if self.assigned_operator != operator
    return false unless status.in?(['PENDING', 'IN_PROGRESS'])
    
    # Don't show if already clocked in to this operation
    return false if operator_clocked_in?(operator)
    
    # Don't show if clocked in elsewhere
    return false if LaborTimeEntry.operator_clocked_in?(operator.id)
    
    true
  end
  
  # Should show clock out button?
  def show_clock_out_button?(operator)
    return false if self.assigned_operator != operator
    operator_clocked_in?(operator)
  end
  
  # Get operator's current entry for this operation
  def current_entry_for_operator(operator)
    labor_time_entries.active.for_operator(operator.id).last
  end

  def operator_clocked_in?(operator)
    has_active_clock_in_by?(operator)
  end
  
  # Clock in an operator
  def clock_in_operator!(operator, entry_type: 'REGULAR', notes: nil)
    # Check if operator is already clocked in elsewhere
    if LaborTimeEntry.operator_clocked_in?(operator.id)
      existing = LaborTimeEntry.current_for_operator(operator.id)
      raise "Operator is already clocked in to Operation ##{existing.work_order_operation.sequence_no}"
    end
    
    # Start the operation if it's still pending
    if status == 'PENDING'
      self.status = 'IN_PROGRESS'
      self.started_at = Time.current
      self.operator = operator
      save!
    end
    
    # Create labor time entry
    labor_time_entries.create!(
      operator: operator,
      clock_in_at: Time.current,
      entry_type: entry_type,
      notes: notes
    )
  end
  
  # Clock out current operator
  def clock_out_operator!(operator)
    active_entry = labor_time_entries.active.for_operator(operator.id).last
    
    unless active_entry
      raise "No active clock-in found for this operator"
    end
    
    active_entry.clock_out!
    active_entry
  end
  
  # Get labor summary for display
  def labor_summary
    {
      total_entries: labor_time_entries.non_deleted.count,
      total_hours: total_labor_hours.round(2),
      regular_hours: labor_time_entries.non_deleted.regular.sum(:hours_worked).round(2),
      break_hours: labor_time_entries.non_deleted.breaks.sum(:hours_worked).round(2),
      unique_operators: labor_time_entries.non_deleted.distinct.count(:operator_id)
    }
  end
  
  # ========================================
  # HELPER METHODS
  # ========================================
  
  def time_variance_minutes
    planned_total_minutes - actual_total_minutes.to_i
  end
  
  def cost_variance
    planned_cost.to_d - actual_cost.to_d
  end
  
  def efficiency_percentage
    return 0 if actual_total_minutes.to_i.zero?
    ((planned_total_minutes.to_d / actual_total_minutes.to_d) * 100).round(2)
  end
  
  def progress_percentage
    return 0 if quantity_to_process.zero?
    ((quantity_completed.to_d / quantity_to_process.to_d) * 100).round(2)
  end
  
  def status_badge_class
    case status
    when 'PENDING' then 'secondary'
    when 'IN_PROGRESS' then 'warning'
    when 'COMPLETED' then 'success'
    when 'SKIPPED' then 'info'
    else 'secondary'
    end
  end
  
  # Soft delete
  def destroy!
    update_attribute(:deleted, true)
  end
end
