module ApplicationHelper
	def link_to_add_association(*args, &block)
    if block_given?
      link_to_add_association(capture(&block), *args)
    elsif args.first.respond_to?(:object)
      association = args.second
      name = I18n.translate("cocoon.#{association}.add", default: I18n.translate('cocoon.defaults.add'))

      link_to_add_association(name, *args)
    else
      name, f, association, html_options = *args
      html_options ||= {}

      render_options   = html_options.delete(:render_options)
      render_options ||= {}
      override_partial = html_options.delete(:partial)
      wrap_object = html_options.delete(:wrap_object)
      force_non_association_create = html_options.delete(:force_non_association_create) || false
      form_parameter_name = html_options.delete(:form_name) || 'f'
      count = html_options.delete(:count).to_i

      html_options[:class] = [html_options[:class], "add_fields"].compact.join(' ')
      html_options[:'data-association'] = association.to_s.singularize
      html_options[:'data-associations'] = association.to_s.pluralize

      new_object = create_object(f, association, force_non_association_create)
      new_object = wrap_object.call(new_object) if wrap_object.respond_to?(:call)

      html_options[:'data-association-insertion-template'] = CGI.escapeHTML(render_association(association, f, new_object, form_parameter_name, render_options, override_partial).to_str).html_safe

      html_options[:'data-count'] = count if count > 0

      link_to(name, '#', html_options)
    end
  end

  # Get current organization
  def current_organization
    Current.organization
  end
  
  # Get organization settings
  def current_org_setting
    Current.organization_setting
  end
  
  # Get MRP configuration
  def current_mrp_config
    Current.mrp_configuration
  end
  
  # ========================================
  # FORMATTING HELPERS
  # ========================================
  
  # Format date according to org preference
  def format_date(date)
    return nil unless date
    current_org_setting&.format_date(date) || date.strftime('%m/%d/%Y')
  end
  
  # Format datetime
  def format_datetime(datetime)
    return nil unless datetime
    date_str = format_date(datetime.to_date)
    time_str = datetime.strftime('%I:%M %p')
    "#{date_str} #{time_str}"
  end
  
  # Format number according to org preference
  def format_number(number, decimals: 2)
    return nil unless number
    current_org_setting&.format_number(number, decimals: decimals) || number_with_precision(number, precision: decimals, delimiter: ',')
  end
  
  # Format currency
  def format_currency(amount, decimals: 2)
    return nil unless amount
    symbol = current_org_setting&.currency_symbol || '$'
    formatted_number = format_number(amount, decimals: decimals)
    "#{symbol}#{formatted_number}"
  end
  
  # Format percentage
  def format_percentage(number, decimals: 1)
    return nil unless number
    "#{format_number(number, decimals: decimals)}%"
  end
  
  # ========================================
  # STATUS BADGE HELPERS
  # ========================================
  
  # Generic status badge
  def status_badge(status, custom_class: nil)
    badge_class = custom_class || status_badge_class(status)
    content_tag(:span, status.to_s.humanize, class: "badge bg-#{badge_class}")
  end
  
  # Determine badge class from status
  def status_badge_class(status)
    case status.to_s.upcase
    when 'ACTIVE', 'COMPLETED', 'APPROVED', 'CONFIRMED', 'POSTED', 'SUCCESS'
      'success'
    when 'PENDING', 'IN_PROGRESS', 'PROCESSING', 'WARNING'
      'warning'
    when 'DRAFT', 'NEW'
      'secondary'
    when 'CANCELLED', 'REJECTED', 'FAILED', 'INACTIVE', 'DELETED'
      'danger'
    when 'ON_HOLD', 'PAUSED'
      'info'
    else
      'secondary'
    end
  end
  
  # ========================================
  # ICON HELPERS
  # ========================================
  
  # Bootstrap icon
  def bs_icon(icon_name, options = {})
    css_class = options[:class] || ''
    content_tag(:i, '', class: "bi bi-#{icon_name} #{css_class}")
  end
  
  # Status icon
  def status_icon(status)
    icon = case status.to_s.upcase
    when 'ACTIVE', 'COMPLETED', 'APPROVED'
      'check-circle-fill'
    when 'PENDING', 'IN_PROGRESS'
      'clock-fill'
    when 'DRAFT'
      'file-earmark'
    when 'CANCELLED', 'REJECTED'
      'x-circle-fill'
    else
      'circle'
    end
    
    bs_icon(icon, class: "text-#{status_badge_class(status)}")
  end
  
  # ========================================
  # PAGE TITLE HELPERS
  # ========================================
  
  # Set page title
  def page_title(title)
    content_for(:title) { "#{title} | #{current_organization&.name || 'Factory-One ERP'}" }
  end
  
  # Breadcrumb helper
  def breadcrumb(*crumbs)
    content_tag(:nav, 'aria-label': 'breadcrumb') do
      content_tag(:ol, class: 'breadcrumb') do
        crumbs.map do |crumb|
          if crumb.is_a?(Array)
            content_tag(:li, class: 'breadcrumb-item') do
              link_to crumb[0], crumb[1]
            end
          else
            content_tag(:li, crumb, class: 'breadcrumb-item active', 'aria-current': 'page')
          end
        end.join.html_safe
      end
    end
  end
  
  # ========================================
  # FLASH MESSAGE HELPERS
  # ========================================
  
  # Flash message icon
  def flash_icon(type)
    case type.to_s
    when 'notice', 'success'
      bs_icon('check-circle')
    when 'alert', 'error'
      bs_icon('exclamation-triangle')
    when 'warning'
      bs_icon('exclamation-circle')
    when 'info'
      bs_icon('info-circle')
    else
      bs_icon('info-circle')
    end
  end
  
  # Flash CSS class
  def flash_class(type)
    case type.to_s
    when 'notice'
      'alert-success'
    when 'alert'
      'alert-danger'
    when 'error'
      'alert-danger'
    when 'warning'
      'alert-warning'
    when 'info'
      'alert-info'
    else
      'alert-info'
    end
  end
  
  # ========================================
  # AUTHORIZATION HELPERS
  # ========================================
  
  # Check if user can perform action
  def can?(action, resource = nil)
    return false unless current_user
    
    case action
    when :manage_organization
      current_user.org_owner?
    when :manage_users
      current_user.admin?
    when :manage_settings
      current_user.admin?
    when :manage_mrp
      current_user.admin? || current_user.planner?
    when :approve_pos
      current_user.admin? || current_user.manager? || current_user.buyer?
    when :create_work_orders
      current_user.admin? || current_user.manager? || current_user.planner?
    when :view_reports
      !current_user.operator?
    when :manage_inventory
      current_user.admin? || current_user.manager?
    else
      current_user.admin?
    end
  end
  
  # ========================================
  # UTILITY HELPERS
  # ========================================
  
  # Active nav link helper
  def active_link(path, exact: false)
    if exact
      'active' if current_page?(path)
    else
      'active' if request.path.start_with?(path)
    end
  end
  
  # Truncate with tooltip
  def truncate_with_tooltip(text, length: 50)
    return text if text.blank? || text.length <= length
    
    content_tag(:span, title: text, data: { bs_toggle: 'tooltip' }) do
      truncate(text, length: length)
    end
  end
  
  # Yes/No badge
  def yes_no_badge(value)
    if value
      content_tag(:span, 'Yes', class: 'badge bg-success')
    else
      content_tag(:span, 'No', class: 'badge bg-secondary')
    end
  end
  
  # Empty state helper
  def empty_state(icon:, title:, message:, action_text: nil, action_path: nil)
    content_tag(:div, class: 'text-center py-5') do
      concat content_tag(:i, '', class: "bi bi-#{icon} display-1 text-muted")
      concat content_tag(:h5, title, class: 'mt-3 fw-bold')
      concat content_tag(:p, message, class: 'text-muted')
      if action_text && action_path
        concat link_to(action_text, action_path, class: 'btn btn-primary')
      end
    end
  end
  
  # Loading spinner
  def loading_spinner(text: 'Loading...')
    content_tag(:div, class: 'text-center py-5') do
      concat content_tag(:div, '', class: 'spinner-border text-primary mb-3', role: 'status')
      concat content_tag(:p, text, class: 'text-muted')
    end
  end
  
  # ========================================
  # CALCULATION HELPERS
  # ========================================
  
  # Calculate percentage
  def calculate_percentage(part, whole)
    return 0 if whole.to_f.zero?
    ((part.to_f / whole.to_f) * 100).round(2)
  end
  
  # Variance helper (actual vs planned)
  def variance_badge(actual, planned)
    return content_tag(:span, 'N/A', class: 'badge bg-secondary') if planned.to_f.zero?
    
    variance = ((actual.to_f - planned.to_f) / planned.to_f * 100).round(1)
    
    badge_class = if variance.abs < 5
      'success'
    elsif variance.abs < 10
      'warning'
    else
      'danger'
    end
    
    prefix = variance > 0 ? '+' : ''
    content_tag(:span, "#{prefix}#{variance}%", class: "badge bg-#{badge_class}")
  end
  
  # ========================================
  # TIME HELPERS
  # ========================================
  
  # Relative time
  def relative_time(time)
    return 'Never' unless time
    time_ago_in_words(time) + ' ago'
  end
  
  # Working days between dates
  def working_days_between(start_date, end_date)
    return 0 unless current_org_setting
    current_org_setting.working_days_between(start_date, end_date)
  end
end
