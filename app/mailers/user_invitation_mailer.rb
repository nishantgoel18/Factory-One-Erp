# frozen_string_literal: true
# app/mailers/user_invitation_mailer.rb

class UserInvitationMailer < ApplicationMailer
  default from: 'noreply@factoryoneerp.com'
  
  # Send invitation email to new user
  def invite(user, custom_message = nil)
    @user = user
    @organization = user.organization
    @custom_message = custom_message
    @reset_password_url = edit_user_password_url(reset_password_token: user.send(:set_reset_password_token))
    
    mail(
      to: @user.email,
      subject: "You've been invited to #{@organization.name} on Factory-One ERP"
    )
  end
  
  # Welcome email after signup
  def welcome(user)
    @user = user
    @organization = user.organization
    
    mail(
      to: @user.email,
      subject: "Welcome to Factory-One ERP!"
    )
  end
end