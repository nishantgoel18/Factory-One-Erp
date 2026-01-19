# ============================================================================
# MODEL: ItemPlanningParameter
# ============================================================================
# Stores MRP planning parameters for each product/item
# Controls how MRP calculates requirements for this specific item

class ItemPlanningParameter < ApplicationRecord
  include OrganizationScoped
  
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :product
  belongs_to :mrp_planner, class_name: 'User', optional: true
  
  # ========================================
  # CONSTANTS
  # ========================================
  PLANNING_METHODS = %w[
    MRP
    REORDER_POINT
    MANUAL
    NONE
  ].freeze
  
  LOT_SIZING_RULES = %w[
    LOT_FOR_LOT
    FIXED_ORDER_QTY
    EOQ
    PERIOD_ORDER_QTY
    MIN_MAX
  ].freeze
  
  TIME_BUCKETS = %w[
    DAILY
    WEEKLY
    MONTHLY
  ].freeze
  
  MAKE_OR_BUY_OPTIONS = %w[
    MAKE
    BUY
    MAKE_AND_BUY
  ].freeze
  
  ABC_CLASSIFICATIONS = %w[A B C].freeze
  XYZ_CLASSIFICATIONS = %w[X Y Z].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :product_id, presence: true
  validates :product_id, uniqueness: { 
    scope: :organization_id,
    conditions: -> { where(deleted: false) },
    message: 'already has planning parameters defined'
  }
  
  validates :planning_method, presence: true, inclusion: { in: PLANNING_METHODS }
  validates :lot_sizing_rule, inclusion: { in: LOT_SIZING_RULES }
  validates :time_bucket, inclusion: { in: TIME_BUCKETS }
  validates :make_or_buy, inclusion: { in: MAKE_OR_BUY_OPTIONS }
  
  # Quantity validations
  validates :safety_stock_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :reorder_point, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :minimum_stock_level, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :maximum_stock_level, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Lead time validations
  validates :purchasing_lead_time_days, numericality: { 
    greater_than_or_equal_to: 0, 
    only_integer: true 
  }
  validates :manufacturing_lead_time_days, numericality: { 
    greater_than_or_equal_to: 0, 
    only_integer: true 
  }
  validates :safety_lead_time_days, numericality: { 
    greater_than_or_equal_to: 0, 
    only_integer: true 
  }
  
  # Lot sizing validations
  validates :minimum_order_quantity, numericality: { greater_than: 0 }
  validates :order_multiple, numericality: { greater_than: 0 }
  
  validates :fixed_order_quantity, numericality: { greater_than: 0 }, 
    if: -> { lot_sizing_rule == 'FIXED_ORDER_QTY' }
  
  validates :annual_demand, :ordering_cost_per_order, :carrying_cost_percent,
    presence: true,
    if: -> { lot_sizing_rule == 'EOQ' }
  
  validates :periods_of_supply, numericality: { 
    greater_than: 0, 
    only_integer: true 
  }, if: -> { lot_sizing_rule == 'PERIOD_ORDER_QTY' }
  
  # Percentage validations
  validates :shrinkage_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }
  validates :yield_percent, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 100 
  }
  validates :carrying_cost_percent, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100 
  }, allow_nil: true
  
  # Planning horizon validations
  validates :planning_horizon_days, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 730,  # Max 2 years
    only_integer: true 
  }
  validates :planning_time_fence_days, numericality: { 
    greater_than_or_equal_to: 0, 
    only_integer: true 
  }
  
  # Classification validations
  validates :abc_classification, inclusion: { in: ABC_CLASSIFICATIONS }, allow_nil: true
  validates :xyz_classification, inclusion: { in: XYZ_CLASSIFICATIONS }, allow_nil: true
  
  # Custom validations
  validate :maximum_must_be_greater_than_minimum
  validate :time_fence_within_horizon
  validate :make_or_buy_alignment_with_product
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_defaults
  before_validation :calculate_reorder_point
  after_save :sync_product_planning_data
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(is_active: true, deleted: false) }
  scope :included_in_mrp, -> { where(include_in_mrp: true) }
  scope :by_planning_method, ->(method) { where(planning_method: method) }
  scope :critical_items, -> { where(is_critical_item: true) }
  scope :abc_class, ->(classification) { where(abc_classification: classification) }
  scope :make_items, -> { where(make_or_buy: ['MAKE', 'MAKE_AND_BUY']) }
  scope :buy_items, -> { where(make_or_buy: ['BUY', 'MAKE_AND_BUY']) }
  
  # ========================================
  # CLASS METHODS
  # ========================================
  
  # Create default planning parameters for a product
  def self.create_default_for_product(product)
    return if product.item_planning_parameter.present?
    
    create!(
      product: product,
      planning_method: determine_planning_method(product),
      make_or_buy: determine_make_or_buy(product),
      safety_stock_quantity: 0,
      planning_horizon_days: 90,
      lot_sizing_rule: 'LOT_FOR_LOT',
      minimum_order_quantity: 1,
      order_multiple: 1
    )
  end
  
  def self.determine_planning_method(product)
    case product.product_type
    when 'Finished Goods', 'Semi-Finished Goods'
      'MRP'
    when 'Raw Material'
      'REORDER_POINT'
    else
      'MANUAL'
    end
  end
  
  def self.determine_make_or_buy(product)
    case product.product_type
    when 'Finished Goods', 'Semi-Finished Goods'
      'MAKE'
    when 'Raw Material', 'Consumable'
      'BUY'
    else
      'BUY'
    end
  end
  
  # ========================================
  # INSTANCE METHODS
  # ========================================
  
  # Get total lead time (purchasing + safety OR manufacturing + safety)
  def total_lead_time_days
    if make_or_buy == 'MAKE'
      manufacturing_lead_time_days + safety_lead_time_days
    else
      purchasing_lead_time_days + safety_lead_time_days
    end
  end
  
  # Calculate Economic Order Quantity (EOQ)
  def calculate_eoq
    return nil unless lot_sizing_rule == 'EOQ'
    return nil unless annual_demand.to_f > 0 && ordering_cost_per_order.to_f > 0
    
    # EOQ = sqrt((2 * D * S) / H)
    # D = Annual demand
    # S = Ordering cost per order
    # H = Holding cost per unit per year
    
    unit_cost = product.standard_cost.to_f
    holding_cost_per_unit = unit_cost * (carrying_cost_percent.to_f / 100)
    
    return nil if holding_cost_per_unit <= 0
    
    eoq = Math.sqrt(
      (2 * annual_demand.to_f * ordering_cost_per_order.to_f) / holding_cost_per_unit
    )
    
    eoq.round(2)
  end
  
  # Apply lot sizing rule to a requirement
  def apply_lot_sizing(net_requirement)
    quantity = case lot_sizing_rule
    when 'LOT_FOR_LOT'
      net_requirement
    when 'FIXED_ORDER_QTY'
      # Always order fixed quantity (or multiples if requirement is higher)
      [(net_requirement / fixed_order_quantity.to_f).ceil * fixed_order_quantity.to_f, fixed_order_quantity.to_f].max
    when 'EOQ'
      eoq = calculate_eoq || net_requirement
      [(net_requirement / eoq).ceil * eoq, eoq].max
    when 'MIN_MAX'
      # Order up to max if below min
      maximum_stock_level.to_f
    when 'PERIOD_ORDER_QTY'
      # For now, just use net requirement
      # In full implementation, would calculate demand for X periods
      net_requirement
    else
      net_requirement
    end
    
    # Apply minimum order quantity
    quantity = [quantity, minimum_order_quantity.to_f].max
    
    # Apply order multiple (round up to nearest multiple)
    if order_multiple.to_f > 1
      quantity = (quantity / order_multiple.to_f).ceil * order_multiple.to_f
    end
    
    # Apply maximum if set
    if maximum_order_quantity.present? && quantity > maximum_order_quantity.to_f
      quantity = maximum_order_quantity.to_f
    end
    
    quantity.round(4)
  end
  
  # Check if item needs planning
  def needs_planning?
    is_active && include_in_mrp && planning_method == 'MRP'
  end
  
  # Get planning time fence date
  def planning_time_fence_date
    Date.today + planning_time_fence_days.days
  end
  
  # Get planning horizon end date
  def planning_horizon_end_date
    Date.today + planning_horizon_days.days
  end
  
  # Check if date is within time fence (frozen zone)
  def within_time_fence?(date)
    date <= planning_time_fence_date
  end
  
  private
  
  # Set default values
  def set_defaults
    self.planning_method ||= 'MRP'
    self.lot_sizing_rule ||= 'LOT_FOR_LOT'
    self.time_bucket ||= 'DAILY'
    self.minimum_order_quantity ||= 1.0
    self.order_multiple ||= 1.0
    self.yield_percent ||= 100.0
    self.planning_horizon_days ||= 90
    self.planning_time_fence_days ||= 7
  end
  
  # Calculate reorder point if not set
  def calculate_reorder_point
    return if reorder_point.present?
    return unless purchasing_lead_time_days.to_i > 0
    
    # Simple reorder point calculation
    # ROP = (Average daily demand × Lead time) + Safety stock
    # For now, just use safety stock if available
    self.reorder_point = safety_stock_quantity if safety_stock_quantity.to_f > 0
  end
  
  # Validation: Maximum stock must be greater than minimum
  def maximum_must_be_greater_than_minimum
    return unless maximum_stock_level.present? && minimum_stock_level.present?
    
    if maximum_stock_level <= minimum_stock_level
      errors.add(:maximum_stock_level, 'must be greater than minimum stock level')
    end
  end
  
  # Validation: Time fence must be within planning horizon
  def time_fence_within_horizon
    return unless planning_time_fence_days.present? && planning_horizon_days.present?
    
    if planning_time_fence_days > planning_horizon_days
      errors.add(:planning_time_fence_days, 'cannot be greater than planning horizon')
    end
  end
  
  # Validation: Make/Buy must align with product type
  def make_or_buy_alignment_with_product
    return unless product.present?
    
    if make_or_buy == 'MAKE' && !['Finished Goods', 'Semi-Finished Goods'].include?(product.product_type)
      errors.add(:make_or_buy, 'MAKE option only valid for Finished Goods or Semi-Finished Goods')
    end
  end
  
  # Sync key data back to product
  def sync_product_planning_data
    return unless product.present?
    
    # You might want to sync some key fields back to product
    # product.update_columns(
    #   safety_stock: safety_stock_quantity,
    #   reorder_point: reorder_point
    # )
  end
end
