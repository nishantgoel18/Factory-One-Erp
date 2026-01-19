# frozen_string_literal: true
# app/controllers/settings/organizations_controller.rb

module Settings
  class OrganizationsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    
    # GET /settings/organization
    def show
      @organization = current_organization
      @setting = current_org_setting
    end
    
    # GET /settings/organization/edit
    def edit
      @organization = current_organization
      @setting = current_org_setting
    end
    
    # PATCH /settings/organization
    def update
      @organization = current_organization
      @setting = current_org_setting
      
      if @setting.update(organization_setting_params)
        redirect_to settings_organization_path, notice: "Organization settings updated successfully!"
      else
        render :edit
      end
    end
    
    private
    
    def organization_setting_params
      params.require(:organization_setting).permit(
        :company_name, :legal_name, :tax_id, :primary_address,
        :country, :currency, :fiscal_year_start_month,
        :time_zone, :date_format, :number_format,
        :working_hours_per_day, :company_logo,
        working_days: [], holiday_list: []
      )
    end
  end
end