# app/models/labor_time_entry.rb

class LaborTimeEntry < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :work_order_operation
  belongs_to :operator, class_name: 'User', foreign_key: 'operator_id'
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :clock_in_at, presence: true
  validates :entry_type, presence: true, 
            inclusion: { in: %w[REGULAR BREAK OVERTIME] }
  
  validate :clock_out_after_clock_in, if: :clock_out_at?
  validate :no_overlapping_entries_for_operator
  
  # ========================================
  # SCOPES
  # ========================================
  scope :non_deleted, -> { where(deleted: false) }
  scope :active, -> { where(clock_out_at: nil) }
  scope :completed, -> { where.not(clock_out_at: nil) }
  scope :for_operator, ->(operator_id) { where(operator_id: operator_id) }
  scope :for_date, ->(date) { where('DATE(clock_in_at) = ?', date) }
  scope :regular, -> { where(entry_type: 'REGULAR') }
  scope :breaks, -> { where(entry_type: 'BREAK') }
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_save :calculate_hours_worked, if: :clock_out_at_changed?
  after_save :update_operation_actual_time, if: :saved_change_to_clock_out_at?
  
  # ========================================
  # CLASS METHODS
  # ========================================
  
  # Get current active clock-in for an operator
  def self.current_for_operator(operator_id)
    active.for_operator(operator_id).order(clock_in_at: :desc).first
  end
  
  # Check if operator is currently clocked in anywhere
  def self.operator_clocked_in?(operator_id)
    active.for_operator(operator_id).exists?
  end
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  # Clock out this entry
  def clock_out!(clock_out_time = Time.current)
    self.clock_out_at = clock_out_time
    calculate_hours_worked
    save!
  end
  
  # Calculate hours worked
  def calculate_hours_worked
    return unless clock_in_at.present? && clock_out_at.present?
    
    duration_seconds = clock_out_at - clock_in_at
    self.hours_worked = (duration_seconds / 3600.0).round(4)
  end
  
  # Get elapsed time in hours (for active entries)
  def elapsed_hours
    return hours_worked if clock_out_at.present?
    
    ((Time.current - clock_in_at) / 3600.0).round(2)
  end
  
  # Get elapsed time in minutes
  def elapsed_minutes
    (elapsed_hours * 60).round(0)
  end
  
  # Human readable elapsed time
  def elapsed_time_display
    total_minutes = elapsed_minutes
    hours = total_minutes / 60
    minutes = total_minutes % 60
    
    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end
  
  # Is this entry still active (not clocked out)?
  def active?
    clock_out_at.nil?
  end
  
  # Entry type labels
  def entry_type_label
    {
      'REGULAR' => 'Regular Work',
      'BREAK' => 'Break',
      'OVERTIME' => 'Overtime'
    }[entry_type] || entry_type
  end
  
  # Entry type badge class
  def entry_type_badge_class
    {
      'REGULAR' => 'primary',
      'BREAK' => 'warning',
      'OVERTIME' => 'info'
    }[entry_type] || 'secondary'
  end
  
  private
  
  def clock_out_after_clock_in
    if clock_out_at.present? && clock_out_at <= clock_in_at
      errors.add(:clock_out_at, "must be after clock in time")
    end
  end
  
  def no_overlapping_entries_for_operator
    return unless clock_in_at.present?
    
    overlapping = LaborTimeEntry.non_deleted
                                 .where(operator_id: operator_id)
                                 .where.not(id: id)
                                 .where('clock_in_at <= ? AND (clock_out_at IS NULL OR clock_out_at >= ?)', 
                                        clock_in_at, clock_in_at)
    
    if overlapping.exists?
      errors.add(:base, "Operator already has an active time entry during this period")
    end
  end
  
  def update_operation_actual_time
    work_order_operation.recalculate_actual_time_from_labor_entries
  end
end
