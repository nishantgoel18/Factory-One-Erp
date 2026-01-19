every 1.day, at: '8:00 am' do
  rake 'work_orders:send_overdue_alerts'
end

every 1.day, at: '6:00 pm' do
  rake 'work_orders:send_daily_summary'
end