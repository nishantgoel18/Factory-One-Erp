# frozen_string_literal: true

# ============================================================================
# FILE: app/helpers/rfqs_helper.rb
# Helper methods for RFQ views
# ============================================================================

module RfqsHelper
  
  # ============================================================================
  # STATUS BADGE HELPERS
  # ============================================================================
  def lowest_quote_class(item_id, current_quote)
    return '' unless current_quote.present?
    
    # Find all quotes for this item
    item_quotes = @vendor_quotes.select { |vq| vq.rfq_item_id == item_id && vq.unit_price.present? }
    
    return '' if item_quotes.empty?
    
    # Find minimum price
    min_price = item_quotes.map(&:unit_price).min
    
    # Highlight if this is the lowest
    current_quote.unit_price == min_price ? 'lowest-price' : ''
  end
  
  # Get badge class for RFQ status
  def rfq_status_badge_class(status)
    case status&.to_s&.upcase
    when 'DRAFT' then 'bg-secondary'
    when 'SENT' then 'bg-primary'
    when 'RESPONSES_RECEIVED' then 'bg-info'
    when 'UNDER_REVIEW' then 'bg-warning text-dark'
    when 'AWARDED' then 'bg-success'
    when 'CLOSED' then 'bg-dark'
    when 'CANCELLED' then 'bg-danger'
    else 'bg-secondary'
    end
  end
  
  # Get badge class for supplier invitation status
  def supplier_invitation_status_badge(status)
    case status&.to_s&.upcase
    when 'INVITED' then 'bg-primary'
    when 'VIEWED' then 'bg-info'
    when 'QUOTED' then 'bg-success'
    when 'DECLINED' then 'bg-danger'
    when 'NO_RESPONSE' then 'bg-warning text-dark'
    else 'bg-secondary'
    end
  end
  
  # Get badge class for quote status
  def quote_status_badge_class(status)
    case status&.to_s&.upcase
    when 'SUBMITTED' then 'bg-primary'
    when 'UNDER_REVIEW' then 'bg-warning text-dark'
    when 'ACCEPTED' then 'bg-success'
    when 'REJECTED' then 'bg-danger'
    when 'EXPIRED' then 'bg-secondary'
    else 'bg-secondary'
    end
  end
  
  # ============================================================================
  # RATING & SCORE HELPERS
  # ============================================================================
  
  # Get badge class for scores (0-100)
  def rating_badge_class(score)
    return 'bg-secondary text-white' unless score
    
    case score.to_i
    when 90..100 then 'bg-success text-white'
    when 80..89 then 'bg-primary text-white'
    when 70..79 then 'bg-info text-white'
    when 60..69 then 'bg-warning text-dark'
    else 'bg-danger text-white'
    end
  end
  
  # Get progress bar color
  def progress_bar_color_class(score)
    return 'bg-secondary' unless score
    
    case score.to_i
    when 90..100 then 'bg-success'
    when 80..89 then 'bg-primary'
    when 70..79 then 'bg-info'
    when 60..69 then 'bg-warning'
    else 'bg-danger'
    end
  end
  
  # ============================================================================
  # FORMATTING HELPERS
  # ============================================================================
  
  # Format currency
  def format_rfq_currency(amount, currency = 'USD')
    return '-' unless amount
    
    symbol = currency == 'USD' ? '$' : currency
    "#{symbol}#{number_with_delimiter(amount.round(2), delimiter: ',')}"
  end
  
  # Format percentage difference
  def format_percentage_diff(value)
    return '-' unless value
    
    if value > 0
      content_tag(:span, "+#{value.round(1)}%", class: 'text-danger')
    elsif value < 0
      content_tag(:span, "#{value.round(1)}%", class: 'text-success')
    else
      content_tag(:span, "0%", class: 'text-muted')
    end
  end
  
  # Format lead time
  def format_lead_time(days)
    return '-' unless days
    
    if days == 1
      "1 day"
    else
      "#{days} days"
    end
  end
  
  # ============================================================================
  # COMPARISON HELPERS
  # ============================================================================
  
  # Get highlight class for comparison cells
  def comparison_cell_class(is_best_price, is_fastest, is_best_value, is_selected)
    classes = []
    classes << 'bg-success bg-opacity-10' if is_best_price
    classes << 'bg-info bg-opacity-10' if is_fastest
    classes << 'bg-warning bg-opacity-10' if is_best_value
    classes << 'table-success' if is_selected
    classes.join(' ')
  end
  
  # Get indicator icons
  def quote_indicator_icons(quote)
    icons = []
    
    if quote.is_lowest_price
      icons << content_tag(:i, '', class: 'bi bi-currency-dollar text-success', 
                          title: 'Lowest Price')
    end
    
    if quote.is_fastest_delivery
      icons << content_tag(:i, '', class: 'bi bi-lightning text-info', 
                          title: 'Fastest Delivery')
    end
    
    if quote.is_best_value
      icons << content_tag(:i, '', class: 'bi bi-star-fill text-warning', 
                          title: 'Best Overall Value')
    end
    
    if quote.is_recommended
      icons << content_tag(:span, 'RECOMMENDED', class: 'badge bg-warning text-dark')
    end
    
    safe_join(icons, ' ')
  end
  
  # ============================================================================
  # DATE & TIME HELPERS
  # ============================================================================
  
  # Format date with days remaining
  def format_date_with_remaining(date, reference_date = Date.current)
    return '-' unless date
    
    days_diff = (date - reference_date).to_i
    
    formatted_date = date.strftime('%b %d, %Y')
    
    if days_diff < 0
      content_tag(:span, class: 'text-danger') do
        concat formatted_date
        concat content_tag(:br)
        concat content_tag(:small, "#{days_diff.abs} days overdue")
      end
    elsif days_diff == 0
      content_tag(:span, class: 'text-warning') do
        concat formatted_date
        concat content_tag(:br)
        concat content_tag(:small, 'Today!')
      end
    elsif days_diff <= 3
      content_tag(:span, class: 'text-warning') do
        concat formatted_date
        concat content_tag(:br)
        concat content_tag(:small, "#{days_diff} days left")
      end
    else
      content_tag(:span) do
        concat formatted_date
        concat content_tag(:br)
        concat content_tag(:small, "#{days_diff} days left", class: 'text-muted')
      end
    end
  end
  
  # ============================================================================
  # STATISTICS HELPERS
  # ============================================================================
  
  # Calculate response rate percentage
  def response_rate_percentage(quotes_received, suppliers_invited)
    return 0 unless suppliers_invited && suppliers_invited > 0
    
    ((quotes_received.to_f / suppliers_invited) * 100).round(0)
  end
  
  # Get response rate color
  def response_rate_color(percentage)
    case percentage
    when 90..100 then 'text-success'
    when 70..89 then 'text-primary'
    when 50..69 then 'text-warning'
    else 'text-danger'
    end
  end
  
  # ============================================================================
  # CHART DATA HELPERS
  # ============================================================================
  
  # Prepare chart colors based on selection
  def chart_colors_for_quotes(quotes)
    quotes.map do |quote|
      if quote.is_selected
        '#28a745' # Green for selected
      elsif quote.is_recommended
        '#ffc107' # Yellow for recommended
      else
        '#6c757d' # Gray for others
      end
    end
  end
  
  # ============================================================================
  # DISPLAY HELPERS
  # ============================================================================
  
  # Display variance with color
  def display_variance(variance_amount, variance_percentage)
    return content_tag(:span, '-', class: 'text-muted') unless variance_amount
    
    if variance_amount > 0
      content_tag(:span, class: 'text-danger') do
        concat "+#{number_to_currency(variance_amount)}"
        if variance_percentage
          concat " (#{variance_percentage.round(1)}%)"
        end
      end
    elsif variance_amount < 0
      content_tag(:span, class: 'text-success') do
        concat number_to_currency(variance_amount)
        if variance_percentage
          concat " (#{variance_percentage.round(1)}%)"
        end
      end
    else
      content_tag(:span, '$0.00', class: 'text-muted')
    end
  end
  
  # Display cost savings
  def display_cost_savings(rfq)
    return nil unless rfq.cost_savings && rfq.cost_savings > 0
    
    content_tag(:div, class: 'alert alert-success') do
      concat content_tag(:h6, 'Cost Savings', class: 'alert-heading')
      concat content_tag(:p, class: 'mb-0') do
        concat content_tag(:strong, number_to_currency(rfq.cost_savings))
        concat " (#{rfq.cost_savings_percentage}% below highest quote)"
      end
    end
  end
  
  # ============================================================================
  # WORKFLOW HELPERS
  # ============================================================================
  
  # Check if user can edit RFQ
  def can_edit_rfq?(rfq)
    rfq.draft? || rfq.sent?
  end
  
  # Check if user can send RFQ
  def can_send_rfq?(rfq)
    rfq.can_be_sent?
  end
  
  # Check if user can award RFQ
  def can_award_rfq?(rfq)
    rfq.can_be_awarded?
  end
  
  # Get available actions for RFQ
  def available_rfq_actions(rfq)
    actions = []
    
    actions << { label: 'Edit', path: edit_rfq_path(rfq), icon: 'pencil' } if can_edit_rfq?(rfq)
    actions << { label: 'Send', path: send_to_suppliers_rfq_path(rfq), icon: 'send', method: :post } if can_send_rfq?(rfq)
    actions << { label: 'Compare', path: comparison_rfq_path(rfq), icon: 'bar-chart' } if rfq.quotes_received_count > 0
    actions << { label: 'Award', path: award_rfq_path(rfq), icon: 'trophy', method: :post } if can_award_rfq?(rfq)
    
    actions
  end
  
  # ============================================================================
  # ICON HELPERS
  # ============================================================================
  
  # Get icon for RFQ status
  def rfq_status_icon(status)
    case status&.to_s&.upcase
    when 'DRAFT' then 'pencil-square'
    when 'SENT' then 'send'
    when 'RESPONSES_RECEIVED' then 'inbox'
    when 'UNDER_REVIEW' then 'eye'
    when 'AWARDED' then 'trophy'
    when 'CLOSED' then 'check-circle'
    when 'CANCELLED' then 'x-circle'
    else 'file-earmark-text'
    end
  end
  
  # ============================================================================
  # VALIDATION HELPERS
  # ============================================================================
  
  # Check if RFQ has minimum required data
  def rfq_has_minimum_data?(rfq)
    rfq.rfq_items.any? && rfq.rfq_suppliers.any?
  end
  
  # Get validation messages
  def rfq_validation_messages(rfq)
    messages = []
    
    messages << 'Add at least one item' if rfq.rfq_items.empty?
    messages << 'Invite at least one supplier' if rfq.rfq_suppliers.empty?
    messages << 'Set response deadline' unless rfq.response_deadline
    
    messages
  end
  
  # ===================================
  # CONVERSION STATUS HELPERS
  # ===================================
  
  # Display conversion status badge
  def rfq_conversion_status_badge(rfq)
    if rfq.converted_to_po?
      content_tag :span, class: "badge bg-success" do
        concat content_tag(:i, "", class: "bi bi-check-circle-fill me-1")
        concat "Converted to PO"
      end
    elsif rfq.can_convert_to_po?
      content_tag :span, class: "badge bg-warning text-dark" do
        concat content_tag(:i, "", class: "bi bi-hourglass-split me-1")
        concat "Ready for Conversion"
      end
    elsif rfq.status == 'AWARDED'
      content_tag :span, class: "badge bg-info" do
        concat content_tag(:i, "", class: "bi bi-trophy me-1")
        concat "Awarded"
      end
    else
      content_tag :span, class: "badge bg-secondary" do
        concat rfq.status.titleize
      end
    end
  end
  
  # Count items by supplier for conversion preview
  def rfq_items_by_supplier_count(rfq)
    rfq.items_by_supplier.keys.count
  end
  
  # Display conversion eligibility message
  def rfq_conversion_eligibility_message(rfq)
    return nil if rfq.converted_to_po?
    
    if rfq.can_convert_to_po?
      content_tag :div, class: "alert alert-success" do
        concat content_tag(:i, "", class: "bi bi-check-circle me-2")
        concat content_tag(:strong, "Ready: ")
        concat "This RFQ can be converted to Purchase Order(s)."
      end
    elsif rfq.status != 'AWARDED'
      content_tag :div, class: "alert alert-warning" do
        concat content_tag(:i, "", class: "bi bi-exclamation-triangle me-2")
        concat content_tag(:strong, "Not Ready: ")
        concat "RFQ must be AWARDED before conversion."
      end
    elsif rfq.selected_items.empty?
      content_tag :div, class: "alert alert-warning" do
        concat content_tag(:i, "", class: "bi bi-exclamation-triangle me-2")
        concat content_tag(:strong, "Not Ready: ")
        concat "No items have been selected/awarded to suppliers."
      end
    end
  end
  
  # ===================================
  # PRICE VARIANCE HELPERS
  # ===================================
  
  # Format price variance with badge color
  def price_variance_badge(actual_price, target_price)
    return content_tag(:span, "N/A", class: "badge bg-secondary") if target_price.blank? || target_price.zero?
    
    variance_pct = ((actual_price - target_price) / target_price * 100).round(1)
    
    badge_class = if variance_pct <= 0
                   "bg-success"
                 elsif variance_pct <= 5
                   "bg-warning text-dark"
                 else
                   "bg-danger"
                 end
    
    content_tag :span, class: "badge #{badge_class}" do
      "#{variance_pct > 0 ? '+' : ''}#{number_to_percentage(variance_pct, precision: 1)} vs target"
    end
  end
  
  # Display cost savings with icon
  def cost_savings_display(savings, percentage = nil)
    return nil if savings.blank? || savings <= 0
    
    content_tag :span, class: "text-success fw-bold" do
      concat content_tag(:i, "", class: "bi bi-piggy-bank me-1")
      concat number_to_currency(savings)
      if percentage.present?
        concat " "
        concat content_tag(:span, "(#{number_to_percentage(percentage, precision: 1)})", class: "text-muted")
      end
    end
  end
  
  # ===================================
  # CONVERSION PREVIEW HELPERS
  # ===================================
  
  # Calculate total for items group
  def items_group_total(items)
    items.sum { |item| (item.selected_unit_price || 0) * (item.quantity_requested || 0) }
  end
  
  # Display supplier info for conversion preview
  def supplier_conversion_summary(supplier, items)
    total = items_group_total(items)
    
    content_tag :div, class: "d-flex justify-content-between align-items-center" do
      concat content_tag(:div) do
        concat content_tag(:strong, supplier.name, class: "d-block")
        concat content_tag(:small, "#{items.count} items", class: "text-muted")
      end
      concat content_tag(:div, class: "text-end") do
        concat content_tag(:div, number_to_currency(total), class: "fw-bold text-success")
        concat content_tag(:small, supplier.supplier_code, class: "text-muted d-block")
      end
    end
  end
  
  # ===================================
  # RFQ ITEM STATUS HELPERS
  # ===================================
  
  # Check if RFQ item is selected for PO
  def rfq_item_selected?(rfq_item)
    rfq_item.selected_supplier_id.present?
  end
  
  # Display item selection status badge
  def rfq_item_selection_badge(rfq_item)
    if rfq_item_selected?(rfq_item)
      content_tag :span, class: "badge bg-success" do
        concat content_tag(:i, "", class: "bi bi-check-circle me-1")
        concat "Selected"
      end
    else
      content_tag :span, class: "badge bg-secondary" do
        concat "Not Selected"
      end
    end
  end
  
  # Display selected supplier name for item
  def rfq_item_selected_supplier(rfq_item)
    return content_tag(:em, "None", class: "text-muted") unless rfq_item_selected?(rfq_item)
    
    supplier = rfq_item.selected_supplier
    content_tag :span, class: "fw-bold text-primary" do
      concat content_tag(:i, "", class: "bi bi-building me-1")
      concat supplier.name
    end
  end
  
  # ===================================
  # PO REFERENCE HELPERS
  # ===================================
  
  # Display linked PO numbers from RFQ
  def rfq_linked_po_numbers(rfq)
    return nil unless rfq.po_numbers.present?
    
    po_numbers_array = rfq.po_numbers.split(',').map(&:strip)
    
    content_tag :div, class: "d-flex flex-wrap gap-2" do
      po_numbers_array.each do |po_num|
        po = PurchaseOrder.find_by(po_number: po_num)
        if po
          concat link_to(po_num, inventory_purchase_order_path(po), 
                        class: "badge bg-primary text-decoration-none fs-6")
        else
          concat content_tag(:span, po_num, class: "badge bg-secondary fs-6")
        end
      end
    end
  end
  
  # Display conversion timestamp
  def rfq_conversion_timestamp(rfq)
    return nil unless rfq.converted_to_po?
    
    content_tag :small, class: "text-muted" do
      concat "Converted on "
      concat content_tag(:strong, rfq.conversion_date.strftime('%B %d, %Y'))
      if rfq.converted_by.present?
        concat " by "
        concat content_tag(:strong, rfq.converted_by.email)
      end
    end
  end
  
  # ===================================
  # TRACEABILITY HELPERS
  # ===================================
  
  # Display traceability chain
  def traceability_chain(purchase_order_line)
    return nil unless purchase_order_line.from_rfq?
    
    content_tag :div, class: "text-muted small" do
      concat content_tag(:i, "", class: "bi bi-link-45deg me-1")
      concat "RFQ "
      concat content_tag(:code, purchase_order_line.purchase_order.rfq.rfq_number)
      concat " → Line "
      concat content_tag(:code, purchase_order_line.rfq_item.line_number)
      if purchase_order_line.vendor_quote.present?
        concat " → Quote #"
        concat content_tag(:code, purchase_order_line.vendor_quote.id)
      end
    end
  end
  
  # Check if full traceability exists
  def full_traceability_badge(purchase_order)
    if purchase_order.fully_traceable_to_rfq?
      content_tag :span, class: "badge bg-success" do
        concat content_tag(:i, "", class: "bi bi-check-circle-fill me-1")
        concat "Full Traceability"
      end
    else
      content_tag :span, class: "badge bg-warning text-dark" do
        concat content_tag(:i, "", class: "bi bi-exclamation-triangle me-1")
        concat "Partial Traceability"
      end
    end
  end
  
  # ===================================
  # ICON HELPERS
  # ===================================
  
  def rfq_status_icon(status)
    icons = {
      'DRAFT' => 'bi-pencil-square',
      'SENT' => 'bi-send',
      'QUOTING' => 'bi-chat-dots',
      'AWARDED' => 'bi-trophy',
      'CLOSED' => 'bi-check-circle',
      'CANCELLED' => 'bi-x-circle'
    }
    
    content_tag(:i, "", class: "bi #{icons[status] || 'bi-circle'} me-2")
  end
  
  def conversion_status_icon(rfq)
    if rfq.converted_to_po?
      content_tag(:i, "", class: "bi bi-arrow-right-circle-fill text-success me-2")
    elsif rfq.can_convert_to_po?
      content_tag(:i, "", class: "bi bi-arrow-right-circle text-warning me-2")
    else
      content_tag(:i, "", class: "bi bi-arrow-right-circle text-muted me-2")
    end
  end
end
