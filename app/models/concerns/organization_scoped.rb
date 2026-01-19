# frozen_string_literal: true

# ============================================================================
# CONCERN: OrganizationScoped (ENHANCED VERSION)
# ============================================================================
# Complete organization functionality in one place
# Just include this concern in any business model
# ============================================================================

module OrganizationScoped
  extend ActiveSupport::Concern
  
  included do
    # ========================================
    # ASSOCIATIONS
    # ========================================
    belongs_to :organization
    
    # ========================================
    # VALIDATIONS
    # ========================================
    validates :organization_id, presence: true
    
    # ========================================
    # SCOPES
    # ========================================
    
    # Default scope: Auto-filter by current organization
    default_scope { where(organization_id: Current.organization_id) if Current.organization_id.present? }
    
    # Unscoped scope (for admin/system operations)
    scope :unscoped_all, -> { unscope(where: :organization_id) }
    
    # Specific organization scope
    scope :for_organization, ->(org_id) { unscope(where: :organization_id).where(organization_id: org_id) }
    
    # Active records for current org (combines with non_deleted scope)
    scope :active_for_org, -> { non_deleted.where(organization_id: Current.organization_id) if Current.organization_id.present? }
    
    # ========================================
    # CALLBACKS
    # ========================================
    before_validation :set_organization_id, on: :create
    before_validation :prevent_organization_change, on: :update
    
    # ========================================
    # INSTANCE METHODS
    # ========================================
    
    # Check if record belongs to current organization
    def belongs_to_current_organization?
      organization_id == Current.organization_id
    end
    
    # Get organization setting
    def org_setting
      organization.organization_setting
    end
    
    # Get MRP configuration
    def mrp_config
      organization.mrp_configuration
    end
    
    # Check if user can access this record
    def accessible_by?(user)
      user.present? && user.organization_id == organization_id
    end
    
    # Format date according to org preference
    def format_date(date)
      return nil unless date
      org_setting&.format_date(date) || date.strftime('%m/%d/%Y')
    end
    
    # Format number according to org preference
    def format_number(number, decimals: 2)
      return nil unless number
      org_setting&.format_number(number, decimals: decimals) || number.round(decimals)
    end
    
    # Get currency symbol
    def currency_symbol
      org_setting&.currency_symbol || '$'
    end
    
    # Format currency
    def format_currency(amount)
      return nil unless amount
      "#{currency_symbol}#{format_number(amount, decimals: 2)}"
    end
    
    private
    
    # Auto-set organization_id from Current context
    def set_organization_id
      self.organization_id ||= Current.organization_id if Current.organization_id.present?
    end
    
    # Prevent changing organization_id after creation (data security)
    def prevent_organization_change
      if organization_id_changed? && persisted?
        errors.add(:organization_id, "cannot be changed after creation")
        throw(:abort)
      end
    end
  end
  
  # ========================================
  # CLASS METHODS
  # ========================================
  class_methods do
    # Find without organization scope (use carefully! Admin only)
    def find_unscoped(id)
      unscoped_all.find(id)
    end
    
    # Find by ID ensuring it belongs to current org
    def find_for_current_org(id)
      find(id) # Uses default_scope automatically
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Record not found or doesn't belong to your organization"
    end
    
    # Count across all organizations (admin only)
    def count_all_organizations
      unscoped_all.count
    end
    
    # Get records for specific organization (admin use)
    def all_for_organization(org_id)
      unscope(where: :organization_id).where(organization_id: org_id)
    end
    
    # Create with automatic organization assignment
    def create_for_current_org(attributes = {})
      attributes[:organization_id] = Current.organization_id
      create(attributes)
    end
    
    # Build with automatic organization assignment
    def build_for_current_org(attributes = {})
      attributes[:organization_id] = Current.organization_id
      new(attributes)
    end
  end
end