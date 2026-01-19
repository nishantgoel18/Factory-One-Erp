# frozen_string_literal: true
# app/helpers/authorization_helper.rb

module AuthorizationHelper
  # Check if current user can perform action
  def can?(action, resource = nil)
    return false unless current_user
    
    case action
    when :manage_organization
      current_user.org_owner?
    when :manage_users
      current_user.admin?
    when :manage_settings
      current_user.admin?
    when :manage_mrp
      current_user.admin? || current_user.planner?
    when :approve_pos
      current_user.admin? || current_user.manager? || current_user.buyer?
    when :create_work_orders
      current_user.admin? || current_user.manager? || current_user.planner?
    when :view_reports
      !current_user.operator? # Everyone except operators
    when :manage_inventory
      current_user.admin? || current_user.manager?
    else
      current_user.admin? # Default to admin only
    end
  end
  
  # Check if user can access specific record
  def can_access?(record)
    return false unless current_user
    return true if current_user.admin?
    
    # Check if record belongs to same organization
    if record.respond_to?(:organization_id)
      record.organization_id == current_user.organization_id
    else
      true
    end
  end
  
  # Require specific permission or redirect
  def authorize!(action, resource = nil)
    unless can?(action, resource)
      redirect_to root_path, alert: "You don't have permission to perform this action."
    end
  end
end