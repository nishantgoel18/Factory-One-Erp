# app/models/routing_operation.rb

class RoutingOperation < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :routing, inverse_of: :routing_operations
  belongs_to :work_center
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :operation_sequence, presence: true,
                                 numericality: { only_integer: true, greater_than: 0 }
  
  validates :operation_name, presence: true, length: { maximum: 100 }
  
  validates :work_center_id, presence: true
  
  validates :setup_time_minutes,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :run_time_per_unit_minutes,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :wait_time_minutes,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :move_time_minutes,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :labor_hours_per_unit,
            numericality: { greater_than_or_equal_to: 0 }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  validate :work_center_must_be_active
  validate :sequence_must_be_unique_within_routing
  
  def work_center_must_be_active
    if work_center.present? && !work_center.is_active?
      errors.add(:work_center_id, "must be active")
    end
  end
  
  def sequence_must_be_unique_within_routing
    return if routing.blank? || operation_sequence.blank?
    
    duplicate = routing.routing_operations
                       .where(operation_sequence: operation_sequence)
                       .where(deleted: false)
                       .where.not(id: id)
    
    if duplicate.exists?
      errors.add(:operation_sequence, "already exists in this routing")
    end
  end
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_default_times
  before_save :calculate_costs
  after_save :update_routing_totals
  after_destroy :update_routing_totals
  
  def set_default_times
    if work_center.present?
      # If setup time not provided, use work center default
      self.setup_time_minutes ||= work_center.setup_time_minutes
      
      # If wait time not provided, use work center queue time
      self.wait_time_minutes ||= work_center.queue_time_minutes if wait_time_minutes.nil?
    end
  end
  
  def calculate_costs
    return unless work_center.present?
    
    # Calculate labor cost per unit
    # labor_hours_per_unit × work_center labor rate
    labor_hours = labor_hours_per_unit.to_d
    if labor_hours.zero?
      # If not specified, use run time as labor time
      labor_hours = run_time_per_unit_minutes.to_d / 60
    end
    
    self.labor_cost_per_unit = (labor_hours * work_center.labor_cost_per_hour).round(2)
    
    # Calculate overhead cost per unit
    # run_time (in hours) × overhead rate
    run_hours = run_time_per_unit_minutes.to_d / 60
    self.overhead_cost_per_unit = (run_hours * work_center.overhead_cost_per_hour).round(2)
  end
  
  def update_routing_totals
    routing.recalculate_totals if routing.present?
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Total time per unit (run + wait + move)
  def total_time_per_unit
    run_time_per_unit_minutes.to_d + 
    wait_time_minutes.to_d + 
    move_time_minutes.to_d
  end
  
  # Total time for a batch
  def calculate_total_time_for_batch(quantity)
    setup_time_minutes.to_d + 
    (run_time_per_unit_minutes.to_d * quantity) +
    wait_time_minutes.to_d +
    move_time_minutes.to_d
  end
  
  # Total cost per unit (labor + overhead)
  def total_cost_per_unit
    (labor_cost_per_unit.to_d + overhead_cost_per_unit.to_d).round(2)
  end
  
  # Calculate setup cost
  def calculate_setup_cost
    return 0 if work_center.blank?
    work_center.calculate_setup_cost(setup_time_minutes)
  end
  
  # Display name with sequence
  def display_name
    "#{operation_sequence} - #{operation_name}"
  end
  
  # Next operation in sequence
  def next_operation
    routing.routing_operations
           .where("operation_sequence > ?", operation_sequence)
           .where(deleted: false)
           .order(:operation_sequence)
           .first
  end
  
  # Previous operation in sequence
  def previous_operation
    routing.routing_operations
           .where("operation_sequence < ?", operation_sequence)
           .where(deleted: false)
           .order(operation_sequence: :desc)
           .first
  end
  
  # Is this the first operation?
  def first_operation?
    routing.routing_operations
           .where(deleted: false)
           .minimum(:operation_sequence) == operation_sequence
  end
  
  # Is this the last operation?
  def last_operation?
    routing.routing_operations
           .where(deleted: false)
           .maximum(:operation_sequence) == operation_sequence
  end
end