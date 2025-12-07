class DailyProductionSummaryJob < ApplicationJob
  queue_as :default
  
  def perform(date = Date.current)
    # Get all production managers/supervisors emails
    recipients = User.where(role: ['production_manager', 'supervisor']).pluck(:email)
    
    recipients.each do |email|
      WorkOrderMailer.daily_production_summary(date, email).deliver_now
    end
  end
end