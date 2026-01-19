# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
    
    # GET /users/sign_up
  def new
    build_resource({})
    @organization = Organization.new
    respond_with resource
  end
    
    # POST /users
  def create
    ActiveRecord::Base.transaction do
      # Create organization first
      @organization = Organization.new(organization_params)
      
      unless @organization.save
        build_resource(sign_up_params)
        render :new and return
      end
      
      # Create user with org_owner role
      build_resource(sign_up_params)
      resource.organization = @organization
      resource.role = :org_owner
      
      unless resource.save
        @organization.destroy
        render :new and return
      end
      
      # Sign in the user
      sign_up(resource_name, resource)
      
      # Redirect to setup wizard
      respond_with resource, location: after_sign_up_path_for(resource)
    end
  rescue => e
    Rails.logger.error "Registration failed: #{e.message}"
    flash[:alert] = "Registration failed: #{e.message}"
    @organization ||= Organization.new(organization_params)
    build_resource(sign_up_params)
    render :new
  end
    
  protected
  
  def after_sign_up_path_for(resource)
    setup_wizard_path # We'll create this route
  end
  
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:full_name])
  end
  
  private
  
  def organization_params
    params.require(:organization).permit(:name, :subdomain, :industry)
  end
  
  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :full_name)
  end
end
