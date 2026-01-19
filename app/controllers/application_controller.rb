# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  
  # ========================================
  # ORGANIZATION CONTEXT (ADD THESE)
  # ========================================
  before_action :set_current_organization
  before_action :check_organization_active
  
  # ========================================
  # HELPER METHODS (ADD THESE)
  # ========================================
  helper_method :current_organization, :current_org_setting, :current_mrp_config
  
  private
  
  # Set Current.organization and Current.user for the request
  def set_current_organization
    if user_signed_in?
      Current.user = current_user
      Current.organization = current_user.organization
    end
  end
  
  # Check if organization is active
  def check_organization_active
    return unless user_signed_in?
    
    unless current_user.organization&.active?
      sign_out current_user
      redirect_to new_user_session_path, alert: "Your organization account has been suspended. Please contact support."
    end
  end
  
  # Get current organization
  def current_organization
    Current.organization
  end
  
  # Get organization settings
  def current_org_setting
    Current.organization_setting || current_user.organization.organization_setting
  end
  
  # Get MRP configuration
  def current_mrp_config
    Current.mrp_configuration
  end
  
  # Require admin access
  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "You don't have permission to access this page."
    end
  end
  
  # Require owner access
  def require_owner
    unless current_user&.org_owner?
      redirect_to root_path, alert: "Only organization owners can access this page."
    end
  end
end
