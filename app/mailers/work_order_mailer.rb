class WorkOrderMailer < ApplicationMailer
  # default from: 'noreply@yourcompany.com'
  
  # ========================================
  # WORK ORDER RELEASED NOTIFICATION
  # ========================================
  def work_order_released(work_order_id, recipient_email)
    @work_order = WorkOrder.find(work_order_id)
    @recipient = recipient_email
    
    mail(
      to: recipient_email,
      subject: "Work Order #{@work_order.wo_number} Released to Production"
    )
  end
  
  # ========================================
  # WORK ORDER COMPLETED NOTIFICATION
  # ========================================
  def work_order_completed(work_order_id, recipient_email)
    @work_order = WorkOrder.find(work_order_id)
    @recipient = recipient_email
    
    # Calculate summary stats
    @cost_variance = @work_order.cost_variance
    @quantity_completed = @work_order.quantity_completed
    @operations_count = @work_order.work_order_operations.count
    
    mail(
      to: recipient_email,
      subject: "Work Order #{@work_order.wo_number} Completed"
    )
  end
  
  # ========================================
  # OVERDUE WORK ORDER ALERT
  # ========================================
  def overdue_alert(work_order_id, recipient_email)
    @work_order = WorkOrder.find(work_order_id)
    @recipient = recipient_email
    @days_overdue = (Date.current - @work_order.scheduled_end_date).to_i
    
    mail(
      to: recipient_email,
      subject: "ALERT: Work Order #{@work_order.wo_number} is Overdue"
    )
  end
  
  # ========================================
  # MATERIAL SHORTAGE ALERT
  # ========================================
  def material_shortage_alert(work_order_id, shortage_details, recipient_email)
    @work_order = WorkOrder.find(work_order_id)
    @shortage_details = shortage_details
    @recipient = recipient_email
    
    mail(
      to: recipient_email,
      subject: "Material Shortage Alert for WO #{@work_order.wo_number}"
    )
  end
  
  # ========================================
  # DAILY PRODUCTION SUMMARY
  # ========================================
  def daily_production_summary(date, recipient_email)
    @date = date
    @recipient = recipient_email
    
    # Gather statistics
    @wos_completed = WorkOrder.non_deleted
                              .where(status: 'COMPLETED')
                              .where(completed_at: date.beginning_of_day..date.end_of_day)
    
    @wos_started = WorkOrder.non_deleted
                            .where(actual_start_date: date.beginning_of_day..date.end_of_day)
    
    @operations_completed = WorkOrderOperation.non_deleted
                                              .where(status: 'COMPLETED')
                                              .where(completed_at: date.beginning_of_day..date.end_of_day)
    
    @total_quantity_produced = @wos_completed.sum(:quantity_completed)
    @total_production_cost = @wos_completed.sum { |wo| wo.total_actual_cost }
    
    mail(
      to: recipient_email,
      subject: "Daily Production Summary - #{date.strftime('%B %d, %Y')}"
    )
  end
  
  # ========================================
  # WEEKLY PRODUCTION REPORT
  # ========================================
  def weekly_production_report(start_date, end_date, recipient_email)
    @start_date = start_date
    @end_date = end_date
    @recipient = recipient_email
    
    # Gather weekly statistics
    @wos_completed = WorkOrder.non_deleted
                              .where(status: 'COMPLETED')
                              .where(completed_at: start_date.beginning_of_day..end_date.end_of_day)
    
    @total_quantity_produced = @wos_completed.sum(:quantity_completed)
    @total_production_cost = @wos_completed.sum { |wo| wo.total_actual_cost }
    @avg_efficiency = calculate_avg_efficiency(@wos_completed)
    @on_time_rate = calculate_on_time_rate(@wos_completed)
    
    mail(
      to: recipient_email,
      subject: "Weekly Production Report - #{start_date.strftime('%b %d')} to #{end_date.strftime('%b %d, %Y')}"
    )
  end

  def work_order_cancelled(work_order_id, recipient_email)
    @work_order = WorkOrder.find(work_order_id)
    
    mail(
      to: recipient_email,
      subject: "Work Order #{@work_order.wo_number} Cancelled"
    )
  end
  
  private
  
  def calculate_avg_efficiency(work_orders)
    return 0 if work_orders.empty?
    
    total_planned = 0
    total_actual = 0
    
    work_orders.each do |wo|
      wo.work_order_operations.where(status: 'COMPLETED').each do |op|
        total_planned += op.planned_total_minutes
        total_actual += op.actual_total_minutes
      end
    end
    
    return 0 if total_actual.zero?
    ((total_planned.to_f / total_actual) * 100).round(2)
  end
  
  def calculate_on_time_rate(work_orders)
    return 0 if work_orders.empty?
    
    on_time = work_orders.select do |wo|
      wo.actual_end_date.to_date <= wo.scheduled_end_date
    end
    
    ((on_time.count.to_f / work_orders.count) * 100).round(2)
  end
end
