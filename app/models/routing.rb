# app/models/routing.rb

class Routing < ApplicationRecord
  include OrganizationScoped
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :product
  belongs_to :created_by, class_name: "User", optional: true
  
  has_many :routing_operations, -> { where(deleted: false).order(:operation_sequence) }, 
           dependent: :destroy,
           inverse_of: :routing
  
  accepts_nested_attributes_for :routing_operations, 
                                allow_destroy: true,
                                reject_if: :all_blank
  
  # ========================================
  # CONSTANTS
  # ========================================
  STATUS_CHOICES = %w[DRAFT ACTIVE INACTIVE ARCHIVED].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :code, presence: true, 
                   uniqueness: { case_sensitive: false },
                   length: { maximum: 20 }
  
  validates :name, presence: true, length: { maximum: 100 }
  
  validates :revision, length: { maximum: 16 }
  
  validates :status, presence: true, inclusion: { in: STATUS_CHOICES }
  
  validates :effective_from, presence: true
  
  validates :product_id, uniqueness: { 
    scope: :revision, 
    message: "already has a routing with this revision" 
  }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  validate :product_must_allow_routing
  validate :date_range_must_be_valid
  validate :only_one_default_per_product
  validate :default_routing_must_be_active
  validate :no_overlapping_active_ranges
  validate :active_routing_must_have_operations
  validate :archived_cannot_be_default
  validate :operation_sequences_must_be_unique
  
  def product_must_allow_routing
    allowed_types = ["Finished Goods", "Semi-Finished Goods"]
    
    unless allowed_types.include?(self.product.product_type)
      errors.add(:product_id, "can only have a routing if it is Finished or Semi-Finished Goods")
    end
  end
  
  def date_range_must_be_valid
    if effective_to.present? && effective_to < effective_from
      errors.add(:effective_to, "cannot be earlier than Effective From date")
    end
  end
  
  def only_one_default_per_product
    return unless is_default?
    conflict = Routing.where(deleted: false).where(product_id: product_id, is_default: true).where.not(id: id)
    
    if conflict.exists?
      errors.add(:is_default, "Only one default routing is allowed per product")
    end
  end
  
  def default_routing_must_be_active
    if is_default? && status != "ACTIVE"
      errors.add(:is_default, "Only an 'Active' routing can be set as default")
    end
  end
  
  def active_routing_must_have_operations
    return unless status == "ACTIVE"
    
    # Only one ACTIVE routing allowed per product
    if Routing.where(deleted: false)
              .where(product_id: product_id, status: "ACTIVE")
              .where.not(id: id)
              .exists?
      errors.add(:status, "Only one ACTIVE routing per product")
    end
    
    if routing_operations.empty?
      errors.add(:base, "An Active routing must contain at least one operation")
    end
  end
  
  def archived_cannot_be_default
    if status == "ARCHIVED" && is_default?
      errors.add(:is_default, "ARCHIVED routing cannot be marked as default")
    end
  end
  
  def no_overlapping_active_ranges
    return unless status == "ACTIVE"
    
    from = effective_from
    to   = effective_to || effective_from
    
    overlap_exists = Routing.where(deleted: false)
                            .where(product_id: product_id, status: "ACTIVE")
                            .where.not(id: id)
                            .where("effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)", to, from)
                            .exists?
    
    if overlap_exists
      errors.add(:base, "Another ACTIVE routing exists for this product within the same effective date range")
    end
  end
  
  def operation_sequences_must_be_unique
    sequences = routing_operations.reject(&:marked_for_destruction?).map(&:operation_sequence).compact
    
    if sequences.uniq.length != sequences.length
      errors.add(:base, "Operation sequences must be unique")
    end
  end
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :normalize_code
  before_save :handle_active_status
  before_save :ensure_single_default
  after_save :recalculate_totals
  
  def normalize_code
    self.code = code.to_s.upcase.strip if code.present?
  end
  
  def handle_active_status
    return unless status == "ACTIVE"
    
    # Archive other active routings
    Routing.where(deleted: false)
           .where(product_id: product_id, status: "ACTIVE")
           .where.not(id: id)
           .update_all(status: "ARCHIVED", is_default: false)
    
    # Auto-set default if not already
    self.is_default = true unless is_default?
  end
  
  def ensure_single_default
    return unless is_default?
    
    Routing.where(deleted: false)
           .where(product_id: product_id)
           .where.not(id: id)
           .update_all(is_default: false)
  end
  
  def recalculate_totals
    return if routing_operations.empty?
    
    setup_total = 0
    run_total = 0
    labor_cost_total = 0
    overhead_cost_total = 0
    
    routing_operations.where(deleted: false).each do |op|
      setup_total += op.setup_time_minutes.to_d
      run_total += op.run_time_per_unit_minutes.to_d
      labor_cost_total += op.labor_cost_per_unit.to_d
      overhead_cost_total += op.overhead_cost_per_unit.to_d
    end
    
    update_columns(
      total_setup_time_minutes: setup_total,
      total_run_time_per_unit_minutes: run_total,
      total_labor_cost_per_unit: labor_cost_total,
      total_overhead_cost_per_unit: overhead_cost_total
    )
  end
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(deleted: false, is_active: true) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_status, ->(status) { where(status: status) }
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Total cost per unit (labor + overhead)
  def total_cost_per_unit
    (total_labor_cost_per_unit.to_d + total_overhead_cost_per_unit.to_d).round(2)
  end
  
  # Calculate total time for a batch
  def calculate_total_time_for_batch(quantity)
    setup_time = total_setup_time_minutes.to_d
    run_time = total_run_time_per_unit_minutes.to_d * quantity
    
    setup_time + run_time
  end
  
  # Calculate total cost for a batch
  def calculate_total_cost_for_batch(quantity)
    # Setup costs (one-time)
    setup_costs = routing_operations.where(deleted: false).sum do |op|
      op.work_center.calculate_setup_cost(op.setup_time_minutes)
    end
    
    # Run costs (per unit × quantity)
    run_costs = total_cost_per_unit * quantity
    
    (setup_costs + run_costs).round(2)
  end
  
  # Get critical path (longest operation)
  def critical_operation
    routing_operations.where(deleted: false).max_by { |op| op.total_time_per_unit }
  end
  
  # Display name
  def display_name
    "#{code} - #{name}"
  end
  
  # Can be deleted?
  def can_be_deleted?
    # Future: check if used in production orders
    # production_orders.none?
    true
  end
  
  # Soft delete
  def destroy!
    if can_be_deleted?
      update_attribute(:deleted, true)
    else
      errors.add(:base, "Cannot delete routing that is being used in production orders")
      false
    end
  end
  
  # ========================================
  # CLASS METHODS
  # ========================================
  
  # Generate next code
  def self.generate_next_code
    last_routing = Routing.where("code LIKE 'RTG-%'")
                          .order(code: :desc)
                          .first
    
    if last_routing && last_routing.code =~ /RTG-(\d+)/
      next_number = $1.to_i + 1
      "RTG-#{next_number.to_s.rjust(4, '0')}"
    else
      "RTG-0001"
    end
  end
  
  # Get next operation sequence
  def next_operation_sequence
    last_seq = routing_operations.maximum(:operation_sequence) || 0
    last_seq + 10
  end
end
