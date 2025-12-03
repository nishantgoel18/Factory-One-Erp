class Product < ApplicationRecord
  belongs_to :product_category
  belongs_to :unit_of_measure
  has_many :bill_of_materials
  has_many :stock_issue_lines

  has_many :routings, dependent: :restrict_with_error
  has_one :default_routing, -> { where(is_default: true, deleted: false, status: 'ACTIVE') }, 
          class_name: 'Routing'

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :reorder_point, numericality: {greater_than_or_equal_to: 0, message: "cannot be negative"}

  PRODUCT_TYPE_CHOICES = [
    'Raw Material',
    'Semi-Finished Goods',
    'Finished Goods',
    'Service',
    'Consumable'
  ]

  scope :bom_products, -> {where(product_type: ["Finished Goods", "Semi-Finished Goods"])}
  scope :bom_item_components, -> {where(product_type: ['Raw Material', 'Service', 'Consumable'])}


  validates :product_type, presence: true, inclusion: { in: PRODUCT_TYPE_CHOICES }
  # validate :validate_inventory_account
  validate :validate_batch_tracking
  validate :validate_serial_batch_conflict

  def validate_inventory_account
    if self.is_stocked && self.inventory_account.blank?
      errors.add(:inventory_account, "Stocked product must have an inventory account")
    end
  end

  def validate_batch_tracking
    if self.is_batch_tracked && !self.is_stocked
      errors.add(:is_batch_tracked, "Batch tracking allowed only for stocked products")
    end
  end

  def validate_serial_batch_conflict
    if self.is_serial_tracked && self.is_batch_tracked
      errors.add(:is_serial_tracked, "Enable either serial OR batch tracking, not both")
    end
  end

  def in_use_bill_of_material
    self.bill_of_materials.find_by(is_default: true, status: 'ACTIVE')
  end

  # show standard cost only for specific types
  def requires_standard_cost?
    ['Raw Material', 'Service', 'Consumable'].include?(self.product_type)
  end

  def can_have_bom?
    ['Finished Goods', 'Semi-Finished Goods'].include?(self.product_type)
  end

  # ========================================
  # NEW METHODS FOR ROUTING INTEGRATION
  # ========================================
  
  # Check if product has a routing
  def has_routing?
    routings.where(deleted: false).exists?
  end
  
  # Get active routings
  def active_routings
    routings.where(deleted: false, status: 'ACTIVE')
  end
  
  # Calculate total production cost (BOM + Routing)
  def total_production_cost
    material_cost = standard_cost.to_d  # From BOM
    routing_cost = default_routing&.total_cost_per_unit.to_d || 0
    
    material_cost + routing_cost
  end
  
  # Calculate production time for a quantity
  def calculate_production_time(quantity = 1)
    return 0 unless default_routing.present?
    
    default_routing.calculate_total_time_for_batch(quantity)
  end
  
  # Get production lead time in days
  def production_lead_time_days(quantity = 1)
    minutes = calculate_production_time(quantity)
    hours = minutes / 60.0
    
    # Assuming 8-hour workday
    (hours / 8.0).ceil
  end
  
  # Check if product is ready for production
  def ready_for_production?
    has_bom = bill_of_materials.where(deleted: false, status: 'ACTIVE').exists?
    has_routing = routings.where(deleted: false, status: 'ACTIVE').exists?
    
    has_bom && has_routing
  end
  
  # Get production readiness status
  def production_readiness
    {
      has_bom: bill_of_materials.where(deleted: false, status: 'ACTIVE').exists?,
      has_routing: routings.where(deleted: false, status: 'ACTIVE').exists?,
      has_default_bom: bill_of_materials.where(deleted: false, is_default: true).exists?,
      has_default_routing: routings.where(deleted: false, is_default: true).exists?,
      ready: ready_for_production?
    }
  end
end
