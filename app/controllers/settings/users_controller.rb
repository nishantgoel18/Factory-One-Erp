# frozen_string_literal: true
# app/controllers/settings/users_controller.rb

module Settings
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_user, only: [:show, :edit, :update, :destroy, :change_role, :toggle_active]
    
    # GET /settings/users
    def index
      @users = current_organization.users
                                   .order(role: :asc, created_at: :desc)
                                   .page(params[:page])
                                   .per(20)
      
      # Filter by role if specified
      @users = @users.where(role: params[:role]) if params[:role].present?
      
      # Search by name or email
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @users = @users.where("email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?", 
                              search_term, search_term, search_term)
      end
      
      @stats = {
        total: current_organization.users.count,
        active: current_organization.users.where(deleted: [false, nil]).count,
        admins: current_organization.users.where(role: [:org_owner, :org_admin]).count,
        operators: current_organization.users.where(role: :operator).count
      }
    end
    
    # GET /settings/users/:id
    def show
      @activities = @user.created_work_orders.limit(10) rescue []
    end
    
    # GET /settings/users/new
    def new
      @user = current_organization.users.build
    end
    
    # POST /settings/users
    def create
      @user = current_organization.users.build(user_params)
      @user.password = SecureRandom.hex(16) # Temporary password
      
      if @user.save
        # Send invitation email (we'll create this mailer)
        UserInvitationMailer.invite(@user, params[:user][:invitation_message]).deliver_later rescue nil
        
        redirect_to settings_users_path, notice: "User invited successfully! Invitation email sent to #{@user.email}"
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    # GET /settings/users/:id/edit
    def edit
    end
    
    # PATCH /settings/users/:id
    def update
      # Prevent self-demotion from org_owner
      if @user == current_user && @user.org_owner? && user_params[:role] != 'org_owner'
        redirect_to settings_users_path, alert: "You cannot change your own role as the organization owner."
        return
      end
      
      if @user.update(user_params)
        redirect_to settings_users_path, notice: "User updated successfully!"
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    # DELETE /settings/users/:id
    def destroy
      # Prevent self-deletion
      if @user == current_user
        redirect_to settings_users_path, alert: "You cannot delete your own account."
        return
      end
      
      # Prevent deleting last owner
      if @user.org_owner? && current_organization.users.where(role: :org_owner).count <= 1
        redirect_to settings_users_path, alert: "Cannot delete the last organization owner."
        return
      end
      
      @user.update(deleted: true)
      redirect_to settings_users_path, notice: "User deleted successfully."
    end
    
    # PATCH /settings/users/:id/change_role
    def change_role
      new_role = params[:role]
      
      # Prevent self-demotion from org_owner
      if @user == current_user && @user.org_owner? && new_role != 'org_owner'
        render json: { error: "You cannot change your own role" }, status: :unprocessable_entity
        return
      end
      
      if @user.update(role: new_role)
        render json: { success: true, message: "Role updated to #{new_role.humanize}" }
      else
        render json: { error: @user.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    end
    
    # PATCH /settings/users/:id/toggle_active
    def toggle_active
      # Prevent self-deactivation
      if @user == current_user
        render json: { error: "You cannot deactivate your own account" }, status: :unprocessable_entity
        return
      end
      
      new_status = !@user.deleted?
      @user.update(deleted: new_status)
      
      status_text = new_status ? "deactivated" : "activated"
      render json: { success: true, message: "User #{status_text} successfully", deleted: new_status }
    end
    
    private
    
    def set_user
      @user = current_organization.users.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to settings_users_path, alert: "User not found."
    end
    
    def user_params
      params.require(:user).permit(:email, :full_name, :role, :phone_number)
    end
  end
end