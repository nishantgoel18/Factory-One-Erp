# app/jobs/work_order_notification_job.rb

class WorkOrderNotificationJob < ApplicationJob
  queue_as :default
  
  def perform(notification_type, work_order_id, recipient_email, additional_params = {})
    case notification_type
    when 'released'
      WorkOrderMailer.work_order_released(work_order_id, recipient_email).deliver_now
    when 'completed'
      WorkOrderMailer.work_order_completed(work_order_id, recipient_email).deliver_now
    when 'overdue_alert'
      WorkOrderMailer.overdue_alert(work_order_id, recipient_email).deliver_now
    when 'material_shortage'
      WorkOrderMailer.material_shortage_alert(work_order_id, additional_params[:shortage_details], recipient_email).deliver_now
    when 'cancelled'  # NEW
      WorkOrderMailer.work_order_cancelled(work_order_id, recipient_email).deliver_now
      
    else
      Rails.logger.warn "Unknown notification type: #{notification_type}"
    end
  rescue => e
    Rails.logger.error "Failed to send #{notification_type} notification: #{e.message}"
    end
  end
end

# app/jobs/daily_production_summary_job.rb

