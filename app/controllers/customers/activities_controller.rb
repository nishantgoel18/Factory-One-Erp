module Customers
  class ActivitiesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer
    before_action :set_activity, only: [:show, :edit, :update, :destroy, :complete, :reschedule]
    
    # GET /customers/:customer_id/activities
    def index
      @activities = @customer.activities.order(activity_date: :desc).page(params[:page]).per(20)
      
      respond_to do |format|
        format.html { render partial: "customers/activities/list", locals: { activities: @activities } }
        format.json { render json: @activities }
      end
    end
    
    # GET /customers/:customer_id/activities/new
    def new
      @activity = @customer.activities.build(activity_date: Time.current)
      @contacts = @customer.contacts.active
      render partial: "customers/activities/form", locals: { customer: @customer, activity: @activity, contacts: @contacts }
    end
    
    # POST /customers/:customer_id/activities
    def create
      @activity = @customer.activities.build(activity_params)
      @activity.related_user = current_user
      @activity.created_by = current_user
      
      if @activity.save
        render json: { success: true, message: "Activity logged successfully", activity: @activity }
      else
        render json: { success: false, errors: @activity.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # GET /customers/:customer_id/activities/:id
    def show
      render partial: "customers/activities/detail", locals: { activity: @activity }
    end
    
    # GET /customers/:customer_id/activities/:id/edit
    def edit
      @contacts = @customer.contacts.active
      render partial: "customers/activities/form", locals: { customer: @customer, activity: @activity, contacts: @contacts }
    end
    
    # PATCH /customers/:customer_id/activities/:id
    def update
      if @activity.update(activity_params)
        render json: { success: true, message: "Activity updated successfully" }
      else
        render json: { success: false, errors: @activity.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    # DELETE /customers/:customer_id/activities/:id
    def destroy
      @activity.destroy!
      render json: { success: true, message: "Activity deleted successfully" }
    end
    
    # POST /customers/:customer_id/activities/:id/complete
    def complete
      @activity.mark_completed!(params[:outcome], params[:notes])
      render json: { success: true, message: "Activity marked as completed" }
    end
    
    # POST /customers/:customer_id/activities/:id/reschedule
    def reschedule
      @activity.reschedule!(params[:new_date])
      render json: { success: true, message: "Activity rescheduled" }
    end
    
    private
    
    def set_customer
      @customer = Customer.non_deleted.find(params[:customer_id])
    end
    
    def set_activity
      @activity = @customer.activities.find(params[:id])
    end
    
    def activity_params
      params.require(:customer_activity).permit(
        :customer_contact_id, :activity_type, :activity_status, :subject, :description,
        :activity_date, :duration_minutes, :outcome, :next_action,
        :followup_date, :followup_required, :communication_method, :direction,
        :customer_sentiment, :priority, :category, tags: []
      )
    end
  end
end