# frozen_string_literal: true

# ============================================================================
# FILE: app/mailers/rfq_mailer.rb
# RFQ Email Notifications
# ============================================================================

class RfqMailer < ApplicationMailer
  default from: 'procurement@yourcompany.com' # CHANGE THIS!
  
  # Email sent when RFQ is sent to suppliers
  # Called from: Rfq#send_to_suppliers!
  def rfq_notification(rfq, supplier, contact)
    @rfq = rfq
    @supplier = supplier
    @contact = contact
    @rfq_items = @rfq.rfq_items.includes(:product)
    @company_name = 'Your Company Name' # CHANGE THIS!
    
    mail(
      to: contact.email,
      subject: "RFQ #{@rfq.rfq_number} - #{@rfq.title}",
      reply_to: @rfq.buyer_assigned&.email || 'procurement@yourcompany.com'
    )
  end
  
  # Reminder email for suppliers who haven't responded
  def rfq_reminder(rfq, supplier, contact)
    @rfq = rfq
    @supplier = supplier
    @contact = contact
    @days_left = (rfq.response_deadline - Date.current).to_i
    
    mail(
      to: contact.email,
      subject: "Reminder: RFQ #{@rfq.rfq_number} - Response Due Soon",
      reply_to: @rfq.buyer_assigned&.email || 'procurement@yourcompany.com'
    )
  end
  
  # Email when quote is received (notification to buyer)
  def quote_received_notification(rfq, vendor_quote)
    @rfq = rfq
    @quote = vendor_quote
    @supplier = vendor_quote.supplier
    
    # Send to buyer and requester
    recipients = [@rfq.buyer_assigned&.email, @rfq.requester&.email].compact.uniq
    
    mail(
      to: recipients,
      subject: "Quote Received: RFQ #{@rfq.rfq_number} from #{@supplier.display_name}"
    )
  end
  
  # Email when RFQ is awarded
  def rfq_awarded_notification(rfq, supplier)
    @rfq = rfq
    @supplier = supplier
    @selected_quotes = @rfq.vendor_quotes.where(supplier: supplier, is_selected: true)
    
    mail(
      to: supplier.primary_email,
      subject: "Award Notification: RFQ #{@rfq.rfq_number}",
      reply_to: @rfq.buyer_assigned&.email || 'procurement@yourcompany.com'
    )
  end
  
  # Email to non-awarded suppliers (regret letter)
  def rfq_not_awarded_notification(rfq, supplier)
    @rfq = rfq
    @supplier = supplier
    
    mail(
      to: supplier.primary_email,
      subject: "RFQ #{@rfq.rfq_number} - Status Update",
      reply_to: @rfq.buyer_assigned&.email || 'procurement@yourcompany.com'
    )
  end
end