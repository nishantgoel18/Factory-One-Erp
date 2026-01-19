# app/models/work_center.rb

class WorkCenter < ApplicationRecord
  include OrganizationScoped
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :location, optional: true
  belongs_to :warehouse, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  has_many :routing_operations
  
  # Future: routing operations will belong to work centers
  # has_many :routing_operations
  
  # ========================================
  # CONSTANTS & ENUMS
  # ========================================
  WORK_CENTER_TYPES = {
    "MACHINE"        => "Machine/Equipment",
    "ASSEMBLY"       => "Assembly Station",
    "QUALITY_CHECK"  => "Quality Control",
    "PACKING"        => "Packing Station",
    "PAINTING"       => "Painting/Coating",
    "WELDING"        => "Welding Station",
    "CUTTING"        => "Cutting/Sawing",
    "DRILLING"       => "Drilling Station",
    "FINISHING"      => "Finishing/Polish",
    "INSPECTION"     => "Inspection Point",
    "STORAGE"        => "Staging/Storage",
    "MANUAL"         => "Manual Labor",
    "OTHER"          => "Other"
  }.freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :code, presence: true, 
                   uniqueness: { case_sensitive: false },
                   length: { maximum: 20 },
                   format: { 
                     with: /\A[A-Z0-9\-_]+\z/i, 
                     message: "only allows letters, numbers, hyphens and underscores" 
                   }
  
  validates :name, presence: true, length: { maximum: 100 }
  
  validates :work_center_type, presence: true, 
                               inclusion: { in: WORK_CENTER_TYPES.keys }
  
  validates :capacity_per_hour, 
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: false
  
  validates :efficiency_percent,
            numericality: { 
              only_integer: true,
              greater_than: 0, 
              less_than_or_equal_to: 100 
            }
  
  validates :labor_cost_per_hour,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :overhead_cost_per_hour,
            numericality: { greater_than_or_equal_to: 0 }
  
  validates :setup_time_minutes,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  validates :queue_time_minutes,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  validate :location_belongs_to_warehouse
  
  def location_belongs_to_warehouse
    return if location.blank? || warehouse.blank?
    
    if location.warehouse_id != warehouse_id
      errors.add(:location, "must belong to the selected warehouse")
    end
  end
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  scope :by_type, ->(type) { where(work_center_type: type) }
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :normalize_code
  
  def normalize_code
    self.code = code.to_s.upcase.strip if code.present?
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Total cost per hour (labor + overhead)
  def total_cost_per_hour
    (labor_cost_per_hour.to_d + overhead_cost_per_hour.to_d).round(2)
  end
  
  # Effective capacity considering efficiency
  def effective_capacity_per_hour
    (capacity_per_hour.to_d * (efficiency_percent.to_d / 100)).round(2)
  end
  
  # Calculate cost for a given run time (in minutes)
  def calculate_run_cost(run_time_minutes, quantity = 1)
    hours = run_time_minutes.to_d / 60
    (total_cost_per_hour * hours * quantity).round(2)
  end
  
  # Calculate setup cost
  def calculate_setup_cost(setup_minutes = nil)
    setup_mins = setup_minutes || setup_time_minutes
    hours = setup_mins.to_d / 60
    (total_cost_per_hour * hours).round(2)
  end
  
  # Total time for a job (queue + setup + run)
  def calculate_total_time(setup_mins, run_mins_per_unit, quantity)
    queue_time_minutes + setup_mins + (run_mins_per_unit * quantity)
  end
  
  # Display name for dropdowns
  def display_name
    "#{code} - #{name}"
  end
  
  # Work center type label
  def type_label
    WORK_CENTER_TYPES[work_center_type] || work_center_type
  end
  
  # Check if work center can be deleted
  def can_be_deleted?
    # Future: check if used in any routing operations
    # routing_operations.none?
    true
  end
  
  # Soft delete
  def destroy!
    if can_be_deleted?
      update_attribute(:deleted, true)
    else
      errors.add(:base, "Cannot delete work center that is being used in routings")
      false
    end
  end
  
  # ========================================
  # CLASS METHODS
  # ========================================
  
  # Generate next code
  def self.generate_next_code
    last_wc = WorkCenter.where("code LIKE 'WC-%'")
                        .order(code: :desc)
                        .first
    
    if last_wc && last_wc.code =~ /WC-(\d+)/
      next_number = $1.to_i + 1
      "WC-#{next_number.to_s.rjust(3, '0')}"
    else
      "WC-001"
    end
  end
end