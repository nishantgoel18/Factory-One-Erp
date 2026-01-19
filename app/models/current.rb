# frozen_string_literal: true

# ============================================================================
# MODEL: Current (Thread-safe context storage)
# ============================================================================
# Stores current user and organization for the request lifecycle
# Thread-safe and request-scoped
# ============================================================================

class Current < ActiveSupport::CurrentAttributes
  # ========================================
  # ATTRIBUTES
  # ========================================
  attribute :user, :organization
  
  # ========================================
  # HELPER METHODS
  # ========================================
  
  # Get current organization ID
  def organization_id
    organization&.id
  end
  
  # Get current user ID
  def user_id
    user&.id
  end
  
  # Check if user is organization owner
  def org_owner?
    user&.role == 'org_owner'
  end
  
  # Check if user is admin (owner or admin)
  def admin?
    user&.role.in?(['org_owner', 'org_admin'])
  end
  
  # Get organization setting
  def organization_setting
    organization&.organization_setting
  end
  
  # Get MRP configuration
  def mrp_configuration
    organization&.mrp_configuration
  end
  
  # Reset all attributes
  def reset_all
    self.user = nil
    self.organization = nil
  end
end