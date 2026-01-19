# frozen_string_literal: true

# ============================================================================
# MODEL: Organization (Multi-Tenant Root)
# ============================================================================
# Parent entity for all business data
# Each signup creates a new organization with org_owner
# ============================================================================

class Organization < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  has_many :users, dependent: :destroy
  has_one :organization_setting, dependent: :destroy
  has_one :mrp_configuration, dependent: :destroy
  
  # Business entities
  has_many :products, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :work_orders, dependent: :destroy
  has_many :purchase_orders, class_name: 'PurchaseOrder', dependent: :destroy
  has_many :rfqs, dependent: :destroy
  has_many :work_centers, dependent: :destroy
  has_many :routings, dependent: :destroy
  has_many :warehouses, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :product_categories, dependent: :destroy
  has_many :unit_of_measures, dependent: :destroy
  has_many :tax_codes, dependent: :destroy
  has_many :accounts, dependent: :destroy
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :name, presence: true, length: { maximum: 100 }
  validates :subdomain, presence: true, 
                        uniqueness: { case_sensitive: false },
                        format: { 
                          with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/i, 
                          message: "only allows lowercase letters, numbers, and hyphens" 
                        },
                        length: { minimum: 3, maximum: 30 }
  
  validates :industry, inclusion: { 
    in: %w[
      Automotive Electronics Food Pharmaceutical 
      Aerospace Machinery Furniture Plastics 
      Textiles Chemicals Other
    ],
    allow_nil: true
  }
  
  # ========================================
  # CALLBACKS
  # ========================================
  after_create :create_default_settings
  after_create :create_default_data
  
  before_validation :normalize_subdomain
  
  # ========================================
  # SCOPES
  # ========================================
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  # ========================================
  # STATUS MANAGEMENT
  # ========================================
  def activate!
    update!(active: true)
  end
  
  def deactivate!
    update!(active: false)
  end
  
  def suspended?
    !active?
  end
  
  # ========================================
  # USER MANAGEMENT
  # ========================================
  def owner
    users.find_by(role: 'org_owner')
  end
  
  def admins
    users.where(role: ['org_owner', 'org_admin'])
  end
  
  def total_users
    users.count
  end
  
  # ========================================
  # BUSINESS METRICS
  # ========================================
  def total_products
    products.non_deleted.count
  end
  
  def total_customers
    customers.non_deleted.count
  end
  
  def total_suppliers
    suppliers.non_deleted.count
  end
  
  def total_work_orders
    work_orders.non_deleted.count
  end
  
  # ========================================
  # SETUP STATUS
  # ========================================
  def setup_complete?
    organization_setting.present? && 
    mrp_configuration.present? &&
    warehouses.exists? &&
    users.count > 0
  end
  
  def setup_progress_percentage
    steps_completed = 0
    total_steps = 5
    
    steps_completed += 1 if organization_setting&.company_name.present?
    steps_completed += 1 if mrp_configuration.present?
    steps_completed += 1 if warehouses.exists?
    steps_completed += 1 if products.exists?
    steps_completed += 1 if users.count > 1
    
    (steps_completed.to_f / total_steps * 100).round(0)
  end
  
  private
  
  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip if subdomain.present?
  end
  
  def create_default_settings
    create_organization_setting!(
      company_name: name,
      country: 'US',
      currency: 'USD',
      date_format: 'MM/DD/YYYY',
      fiscal_year_start_month: 1,
      time_zone: ActiveSupport::TimeZone.all.map(&:name).first,
      working_days: %w[Monday Tuesday Wednesday Thursday Friday]
    )
    
    create_mrp_configuration!(
      planning_horizon_days: 90,
      safety_stock_days: 7,
      default_purchase_lead_time: 14,
      default_manufacturing_lead_time: 7
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create default settings: #{e.message}"
  end
  
  def create_default_data
    # Create default warehouse
    warehouses.create!(
      code: 'WH-001',
      name: 'Main Warehouse',
      warehouse_type: 'DISTRIBUTION'
    )
    
    # Create default UOMs
    uom_data = [
      { code: 'EA', name: 'Each', is_decimal: false },
      { code: 'PC', name: 'Piece', is_decimal: false },
      { code: 'KG', name: 'Kilogram', is_decimal: true },
      { code: 'LB', name: 'Pound', is_decimal: true },
      { code: 'HR', name: 'Hour', is_decimal: true }
    ]
    
    uom_data.each do |uom|
      unit_of_measures.create!(uom)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to create default data: #{e.message}"
  end
end