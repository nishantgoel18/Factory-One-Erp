module SuppliersHelper
  
  # ============================================================================
  # RATING & SCORE HELPERS
  # ============================================================================
  
  # Get Bootstrap color class based on rating (0-100)
  def rating_color_class(rating)
    return 'bg-secondary' unless rating
    
    case rating.to_i
    when 90..100 then 'bg-success'
    when 80..89 then 'bg-primary'
    when 70..79 then 'bg-info'
    when 60..69 then 'bg-warning'
    else 'bg-danger'
    end
  end
  
  # Get rating label text
  def rating_label(rating)
    return 'Not Rated' unless rating
    
    case rating.to_i
    when 90..100 then 'Excellent'
    when 80..89 then 'Very Good'
    when 70..79 then 'Good'
    when 60..69 then 'Satisfactory'
    when 50..59 then 'Needs Improvement'
    else 'Poor'
    end
  end
  
  # Get badge class for performance scores
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
  
  # Get progress bar color class
  def progress_bar_color_class(value)
    return 'bg-secondary' unless value
    
    case value.to_i
    when 90..100 then 'bg-success'
    when 80..89 then 'bg-primary'
    when 70..79 then 'bg-info'
    when 60..69 then 'bg-warning'
    else 'bg-danger'
    end
  end
  
  # ============================================================================
  # QUALITY ISSUE HELPERS
  # ============================================================================
  
  # Get severity badge class
  def severity_badge_class(severity)
    case severity&.to_s&.upcase
    when 'CRITICAL' then 'bg-danger text-white'
    when 'MAJOR' then 'bg-warning text-dark'
    when 'MINOR' then 'bg-info text-white'
    else 'bg-secondary text-white'
    end
  end
  
  # Get severity icon
  def severity_icon(severity)
    case severity&.to_s&.upcase
    when 'CRITICAL' then 'exclamation-triangle-fill'
    when 'MAJOR' then 'exclamation-circle-fill'
    when 'MINOR' then 'info-circle-fill'
    else 'circle'
    end
  end
  
  # ============================================================================
  # STATUS HELPERS
  # ============================================================================
  
  # Get status badge class for quality issues
  def status_badge_class(status)
    case status&.to_s&.upcase
    when 'OPEN' then 'bg-danger text-white'
    when 'IN_PROGRESS' then 'bg-warning text-dark'
    when 'RESOLVED' then 'bg-info text-white'
    when 'CLOSED' then 'bg-success text-white'
    else 'bg-secondary text-white'
    end
  end
  
  # Get supplier status badge class
  def supplier_status_badge_class(status)
    case status&.to_s&.upcase
    when 'ACTIVE' then 'bg-success'
    when 'APPROVED' then 'bg-primary'
    when 'PENDING_APPROVAL' then 'bg-warning'
    when 'SUSPENDED' then 'bg-danger'
    when 'BLACKLISTED' then 'bg-dark'
    else 'bg-secondary'
    end
  end
  
  # ============================================================================
  # FORMATTING HELPERS
  # ============================================================================
  
  # Format currency with symbol
  def format_currency(amount, currency = 'USD')
    return '$0.00' unless amount
    
    symbol = currency == 'USD' ? '$' : currency
    "#{symbol}#{number_with_delimiter(amount.round(2), delimiter: ',')}"
  end
  
  # Format percentage with symbol
  def format_percentage(value)
    return '0%' unless value
    "#{value.round(1)}%"
  end
  
  # Format rating as X/100
  def format_rating(rating)
    return 'N/A' unless rating
    "#{rating.to_i}/100"
  end
  
  # ============================================================================
  # TREND HELPERS
  # ============================================================================
  
  # Get trend icon and color
  def trend_indicator(current, previous)
    return { icon: 'dash', color: 'secondary', text: 'No change' } unless current && previous
    
    if current > previous
      { icon: 'arrow-up', color: 'success', text: 'Improving' }
    elsif current < previous
      { icon: 'arrow-down', color: 'danger', text: 'Declining' }
    else
      { icon: 'dash', color: 'secondary', text: 'Stable' }
    end
  end
  
  # Calculate percentage change
  def percentage_change(current, previous)
    return 0 unless current && previous && previous != 0
    
    ((current - previous) / previous.to_f * 100).round(1)
  end
  
  # ============================================================================
  # ICON HELPERS
  # ============================================================================
  
  # Get icon for document type
  def document_type_icon(doc_type)
    case doc_type&.to_s&.upcase
    when 'CERTIFICATE' then 'file-earmark-check'
    when 'CONTRACT' then 'file-earmark-text'
    when 'INSURANCE' then 'shield-check'
    when 'LICENSE' then 'award'
    when 'QUALITY_DOC' then 'clipboard-check'
    when 'COMPLIANCE' then 'file-earmark-ruled'
    when 'FINANCIAL' then 'currency-dollar'
    when 'W9' then 'file-earmark-medical'
    when 'NDA' then 'file-earmark-lock'
    else 'file-earmark'
    end
  end
  
  # Get icon for supplier type
  def supplier_type_icon(type)
    case type&.to_s&.upcase
    when 'MANUFACTURER' then 'building'
    when 'DISTRIBUTOR' then 'truck'
    when 'WHOLESALER' then 'boxes'
    when 'SERVICE_PROVIDER' then 'tools'
    when 'CONTRACTOR' then 'hammer'
    else 'box-seam'
    end
  end
  
  # ============================================================================
  # DISPLAY HELPERS
  # ============================================================================
  
  # Display supplier rating with visual indicator
  def display_rating_with_badge(rating)
    return content_tag(:span, 'Not Rated', class: 'badge bg-secondary') unless rating
    
    content_tag(:span, class: 'rating-display') do
      concat content_tag(:span, rating.to_i, class: "badge #{rating_badge_class(rating)} me-1")
      concat content_tag(:small, rating_label(rating), class: 'text-muted')
    end
  end
  
  # Display price trend indicator
  def display_price_trend(current_price, previous_price)
    return content_tag(:span, '-', class: 'text-muted') unless current_price && previous_price
    
    change = percentage_change(current_price, previous_price)
    trend = trend_indicator(current_price, previous_price)
    
    content_tag(:span, class: "text-#{trend[:color]}") do
      concat content_tag(:i, '', class: "bi bi-#{trend[:icon]} me-1")
      concat "#{change.abs}%"
    end
  end
  
  # Display days until expiry with warning
  def display_expiry_warning(expiry_date)
    return '' unless expiry_date
    
    days_until = (expiry_date - Date.current).to_i
    
    if days_until < 0
      content_tag(:span, 'EXPIRED', class: 'badge bg-danger')
    elsif days_until <= 30
      content_tag(:span, "Expires in #{days_until} days", class: 'badge bg-warning text-dark')
    else
      content_tag(:span, "Expires #{expiry_date.strftime('%b %d, %Y')}", class: 'text-muted small')
    end
  end
  
  # ============================================================================
  # RECOMMENDATION HELPERS
  # ============================================================================
  
  # Get recommendation badge
  def recommendation_badge(recommendation)
    case recommendation&.to_s&.upcase
    when 'CONTINUE_PREFERRED' then { class: 'bg-success', text: 'Continue as Preferred' }
    when 'CONTINUE_APPROVED' then { class: 'bg-primary', text: 'Continue as Approved' }
    when 'PROBATION' then { class: 'bg-warning', text: 'Probation' }
    when 'IMPROVEMENT_PLAN' then { class: 'bg-info', text: 'Improvement Plan' }
    when 'REDUCE_BUSINESS' then { class: 'bg-danger', text: 'Reduce Business' }
    when 'DISCONTINUE' then { class: 'bg-dark', text: 'Discontinue' }
    else { class: 'bg-secondary', text: 'Not Set' }
    end
  end
  
  # ============================================================================
  # AGGREGATE HELPERS
  # ============================================================================
  
  # Calculate supplier health score (0-100)
  def supplier_health_score(supplier)
    scores = []
    
    scores << supplier.overall_rating if supplier.overall_rating
    scores << supplier.on_time_delivery_rate if supplier.on_time_delivery_rate
    scores << supplier.quality_acceptance_rate if supplier.quality_acceptance_rate
    
    return 0 if scores.empty?
    
    (scores.sum / scores.size.to_f).round(0)
  end
  
  # Get health score color
  def health_score_color(score)
    case score.to_i
    when 90..100 then 'success'
    when 80..89 then 'primary'
    when 70..79 then 'info'
    when 60..69 then 'warning'
    else 'danger'
    end
  end
  
end