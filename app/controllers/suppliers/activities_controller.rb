module Suppliers
  class ActivitiesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_supplier
    before_action :set_activity, only: [:edit, :update, :destroy, :complete]
    
    def new
      @activity = @supplier.activities.build(
        activity_date: Time.current,
        activity_status: 'COMPLETED',
        priority: 'NORMAL'
      )
      @contacts = @supplier.contacts.active
    end
    
    def create
      @activity = @supplier.activities.build(activity_params)
      @activity.related_user = current_user
      @activity.created_by = current_user
      
      if @activity.save
        redirect_to @supplier, notice: "Contact was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
      @contacts = @supplier.contacts.active
      
    end
    
    def update
      if @activity.update(activity_params)
        redirect_to @supplier, notice: "Activity was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      @activity.destroy!
      rredirect_to @supplier, notice: 'Activity deleted successfully'
    end
    
    def complete
      @activity.mark_completed!(params[:outcome], current_user)
      redirect_to @supplier, notice: 'Activity marked as completed'
    end
    
    private
    
    def set_supplier
      @supplier = Supplier.non_deleted.find(params[:supplier_id])
    end
    
    def set_activity
      @activity = @supplier.activities.find(params[:id])
    end
    
    def activity_params
      params.require(:supplier_activity).permit(
        :supplier_contact_id, :activity_type, :activity_status, :subject,
        :description, :activity_date, :duration_minutes, :outcome,
        :action_items, :next_steps, :followup_required, :followup_date,
        :communication_method, :direction, :supplier_sentiment,
        :priority, :category, tags: []
      )
    end
  end
end