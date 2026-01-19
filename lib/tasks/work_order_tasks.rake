namespace :work_orders do
  desc "Send overdue alerts for work orders"
  task send_overdue_alerts: :environment do
    overdue_wos = WorkOrder.non_deleted
                          .where(status: ['RELEASED', 'IN_PROGRESS'])
                          .where('scheduled_end_date < ?', Date.current)
    
    overdue_wos.each do |wo|
      # Send to created_by user
      if wo.created_by.present?
        WorkOrderNotificationJob.perform_later('overdue_alert', wo.id, wo.created_by.email)
      end
    end
    
    puts "Sent overdue alerts for #{overdue_wos.count} work orders"
  end
  
  desc "Send daily production summary"
  task send_daily_summary: :environment do
    DailyProductionSummaryJob.perform_later(Date.current)
    puts "Daily production summary scheduled"
  end
end

# Add to config/schedule.rb (if using whenever gem)
# every 1.day, at: '8:00 am' do
#   rake 'work_orders:send_overdue_alerts'
# end
#
# every 1.day, at: '6:00 pm' do
#   rake 'work_orders:send_daily_summary'
# end