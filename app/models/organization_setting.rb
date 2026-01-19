# frozen_string_literal: true

# ============================================================================
# MODEL: OrganizationSetting (Module 4.1)
# ============================================================================
# General company settings: name, address, fiscal year, formats, holidays
# One setting record per organization
# ============================================================================

class OrganizationSetting < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :organization
  
  # ActiveStorage for logo
  has_one_attached :company_logo
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :company_name, presence: true, length: { maximum: 200 }
  validates :country, presence: true, inclusion: { in: %w[US CA] }
  validates :currency, presence: true, inclusion: { in: %w[USD CAD] }
  validates :fiscal_year_start_month, presence: true, 
                                      numericality: { 
                                        only_integer: true, 
                                        greater_than_or_equal_to: 1, 
                                        less_than_or_equal_to: 12 
                                      }
  
  validates :working_hours_per_day, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 24 
  }, allow_nil: true
  
  validates :date_format, inclusion: { 
    in: %w[MM/DD/YYYY DD/MM/YYYY YYYY-MM-DD],
    message: "%{value} is not a valid date format" 
  }, allow_nil: true
  
  validates :time_zone, inclusion: { 
    in: ActiveSupport::TimeZone.all.map(&:name) 
  }, allow_nil: true
  
  # ========================================
  # DEFAULTS
  # ========================================
  after_initialize :set_defaults, if: :new_record?
  
  # ========================================
  # CONSTANTS
  # ========================================
  COUNTRY_CHOICES = {
    'US' => 'United States',
    'CA' => 'Canada'
  }.freeze
  
  CURRENCY_CHOICES = {
    'USD' => 'US Dollar ($)',
    'CAD' => 'Canadian Dollar (C$)'
  }.freeze
  
  DATE_FORMAT_CHOICES = {
    'MM/DD/YYYY' => 'MM/DD/YYYY (US)',
    'DD/MM/YYYY' => 'DD/MM/YYYY (International)',
    'YYYY-MM-DD' => 'YYYY-MM-DD (ISO)'
  }.freeze
  
  NUMBER_FORMAT_CHOICES = {
    '1,234.56' => '1,234.56 (US)',
    '1.234,56' => '1.234,56 (European)',
    '1 234,56' => '1 234,56 (French)'
  }.freeze
  
  WEEKDAY_CHOICES = %w[
    Monday Tuesday Wednesday Thursday Friday Saturday Sunday
  ].freeze
  
  # ========================================
  # BUSINESS LOGIC
  # ========================================
  
  # Format date according to org preference
  def format_date(date)
    return nil unless date
    
    case date_format
    when 'MM/DD/YYYY'
      date.strftime('%m/%d/%Y')
    when 'DD/MM/YYYY'
      date.strftime('%d/%m/%Y')
    when 'YYYY-MM-DD'
      date.strftime('%Y-%m-%d')
    else
      date.strftime('%m/%d/%Y')
    end
  end
  
  # Format number according to org preference
  def format_number(number, decimals: 2)
    return nil unless number
    
    case number_format
    when '1,234.56'
      number_to_currency(number, precision: decimals, unit: '', separator: '.', delimiter: ',')
    when '1.234,56'
      number_to_currency(number, precision: decimals, unit: '', separator: ',', delimiter: '.')
    when '1 234,56'
      number_to_currency(number, precision: decimals, unit: '', separator: ',', delimiter: ' ')
    else
      number.round(decimals)
    end
  end
  
  # Check if a date is a working day
  def working_day?(date)
    return false unless date
    day_name = date.strftime('%A')
    working_days.include?(day_name) && !holiday?(date)
  end
  
  # Check if a date is a holiday
  def holiday?(date)
    return false unless date
    return false if holiday_list.blank?
    
    holiday_list.any? { |h| h['date'] == date.to_s }
  end
  
  # Get next working day
  def next_working_day(from_date = Date.current)
    candidate = from_date + 1.day
    
    while !working_day?(candidate)
      candidate += 1.day
    end
    
    candidate
  end
  
  # Calculate working days between two dates
  def working_days_between(start_date, end_date)
    count = 0
    current = start_date
    
    while current <= end_date
      count += 1 if working_day?(current)
      current += 1.day
    end
    
    count
  end
  
  # Get fiscal year for a given date
  def fiscal_year_for(date)
    if date.month >= fiscal_year_start_month
      date.year
    else
      date.year - 1
    end
  end
  
  # Fiscal year start date
  def fiscal_year_start(year = Date.current.year)
    Date.new(year, fiscal_year_start_month, 1)
  end
  
  # Fiscal year end date
  def fiscal_year_end(year = Date.current.year)
    start_date = fiscal_year_start(year)
    (start_date + 1.year - 1.day)
  end
  
  # Currency symbol
  def currency_symbol
    case currency
    when 'USD' then '$'
    when 'CAD' then 'C$'
    else '$'
    end
  end
  
  private
  
  def set_defaults
    self.country ||= 'US'
    self.currency ||= 'USD'
    self.date_format ||= 'MM/DD/YYYY'
    self.number_format ||= '1,234.56'
    self.fiscal_year_start_month ||= 1
    self.time_zone ||= 'America/New_York'
    self.working_days ||= %w[Monday Tuesday Wednesday Thursday Friday]
    self.working_hours_per_day ||= 8.0
    self.holiday_list ||= []
  end
end
