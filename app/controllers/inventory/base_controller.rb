# app/controllers/inventory/base_controller.rb

module Inventory
  class BaseController < ApplicationController
    before_action :authenticate_user!
    # layout 'inventory'
    
    private
    
    # Common flash messages
    def set_success_message(message)
      flash[:success] = message
    end
    
    def set_error_message(message)
      flash[:error] = message
    end
    
    def set_warning_message(message)
      flash[:warning] = message
    end
    
    # Common redirects
    def redirect_back_or_to(default_path)
      redirect_to request.referer || default_path
    end
    
    # Pagination
    def per_page
      params[:per_page] || 25
    end
    
    # Common filters
    def apply_date_filters(relation)
      relation = relation.where('created_at >= ?', params[:from_date]) if params[:from_date].present?
      relation = relation.where('created_at <= ?', params[:to_date]) if params[:to_date].present?
      relation
    end
    
    # Check permissions (add your authorization logic)
    def authorize_inventory_access!
      # Example: unless current_user.can?(:access_inventory)
      #   redirect_to root_path, alert: "Access denied"
      # end
    end
  end
end
