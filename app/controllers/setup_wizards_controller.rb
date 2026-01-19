# frozen_string_literal: true
# app/controllers/setup_wizard_controller.rb

class SetupWizardsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_owner
  before_action :redirect_if_setup_complete, except: [:show]
  
  # GET /setup_wizard
  def show
    @organization = current_organization

    @setting = current_org_setting || current_user.organization.build_organization_setting
    @mrp_config = current_mrp_config
    @step = params[:step]&.to_i || 1
  end
  
  # PATCH /setup_wizard/update_company
  def update_company
    @setting = current_org_setting || current_user.organization.build_organization_setting
    
    if @setting.update(company_params)
      redirect_to setup_wizard_path(step: 2), notice: "Company information saved!"
    else
      @step = 1
      render :show
    end
  end
  
  # PATCH /setup_wizard/update_fiscal
  def update_fiscal
    @setting = current_org_setting
    
    if @setting.update(fiscal_params)
      redirect_to setup_wizard_path(step: 3), notice: "Fiscal settings saved!"
    else
      @step = 2
      render :show
    end
  end
  
  # PATCH /setup_wizard/update_mrp
  def update_mrp
    @mrp_config = current_mrp_config
    
    if @mrp_config.update(mrp_params)
      redirect_to setup_wizard_path(step: 4), notice: "MRP settings saved!"
    else
      @step = 3
      render :show
    end
  end
  
  # POST /setup_wizard/complete
  def complete
    if current_organization.setup_complete?
      redirect_to root_path, notice: "Setup complete! Welcome to your ERP system."
    else
      redirect_to setup_wizard_path, alert: "Please complete all setup steps."
    end
  end
  
  # GET /setup_wizard/skip
  def skip
    redirect_to root_path, notice: "You can complete setup later from Settings."
  end
  
  private
  
  def redirect_if_setup_complete
    if current_organization.setup_complete? && action_name == 'show' && params[:step].blank?
      redirect_to root_path, notice: "Setup already completed!"
    end
  end
  
  def company_params
    params.require(:organization_setting).permit(
      :company_name, :legal_name, :tax_id, :primary_address,
      :country, :currency, :time_zone, :company_logo
    )
  end
  
  def fiscal_params
    params.require(:organization_setting).permit(
      :fiscal_year_start_month, :date_format, :number_format,
      :working_hours_per_day, working_days: []
    )
  end
  
  def mrp_params
    params.require(:mrp_configuration).permit(
      :planning_horizon_days, :safety_stock_days, 
      :default_purchase_lead_time, :default_manufacturing_lead_time,
      :default_lot_sizing_method, :safety_stock_calculation_method,
      :reorder_point_calculation_method, :default_costing_method
    )
  end
end
