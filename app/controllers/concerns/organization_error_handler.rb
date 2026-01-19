# frozen_string_literal: true
# app/controllers/concerns/organization_error_handler.rb

module OrganizationErrorHandler
  extend ActiveSupport::Concern
  
  included do
    rescue_from OrganizationNotFound, with: :handle_organization_not_found
    rescue_from OrganizationSuspended, with: :handle_organization_suspended
    rescue_from UnauthorizedAccess, with: :handle_unauthorized_access
  end
  
  private
  
  def handle_organization_not_found
    sign_out current_user if user_signed_in?
    redirect_to new_user_session_path, alert: "Organization not found. Please contact support."
  end
  
  def handle_organization_suspended
    sign_out current_user if user_signed_in?
    redirect_to new_user_session_path, alert: "This organization account has been suspended. Please contact support."
  end
  
  def handle_unauthorized_access
    redirect_to root_path, alert: "You don't have permission to access this resource."
  end
end

# Custom exceptions
class OrganizationNotFound < StandardError; end
class OrganizationSuspended < StandardError; end
class UnauthorizedAccess < StandardError; end