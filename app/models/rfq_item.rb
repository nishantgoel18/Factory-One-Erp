# frozen_string_literal: true

# ============================================================================
# ALL REMAINING RFQ MODELS
# Split into separate files during implementation
# ============================================================================

# ============================================================================
# MODEL: RfqItem
# ============================================================================
class RfqItem < ApplicationRecord
  belongs_to :rfq
  belongs_to :product
  belongs_to :selected_supplier, class_name: 'Supplier', optional: true
  belongs_to :last_purchased_from, class_name: 'Supplier', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  
  has_many :vendor_quotes, dependent: :destroy
  
  validates :line_number, presence: true, uniqueness: { scope: :rfq_id }
  validates :quantity_requested, presence: true, numericality: { greater_than: 0 }
  
  scope :critical, -> { where(is_critical_item: true) }
  scope :long_lead, -> { where(is_long_lead_item: true) }
  scope :by_line_number, -> { order(:line_number) }
  
  before_validation :set_line_number, on: :create
  before_save :calculate_target_total
  
  def display_name
     product&.name_with_sku.presence || item_description.presence
  end
  
  def calculate_quote_statistics!
    return if vendor_quotes.empty?
    
    prices = vendor_quotes.pluck(:unit_price)
    lead_times = vendor_quotes.pluck(:lead_time_days)
    
    update_columns(
      quotes_received_count: vendor_quotes.count,
      lowest_quoted_price: prices.min,
      highest_quoted_price: prices.max,
      average_quoted_price: (prices.sum / prices.size.to_f).round(4),
      best_delivery_days: lead_times.min
    )
  end
  
  def select_quote!(quote, selected_by_user, reason: nil)
    transaction do
      update!(
        selected_supplier: quote.supplier,
        selected_unit_price: quote.unit_price,
        selected_total_price: quote.total_price,
        selected_lead_time_days: quote.lead_time_days,
        selection_reason: reason
      )
      
      quote.update!(is_selected: true, selected_by: selected_by_user, selected_date: Date.current)
      calculate_variance!
    end
  end
  
  def calculate_variance!
    if selected_unit_price && target_unit_price
      variance = selected_unit_price - target_unit_price
      percentage = (variance / target_unit_price * 100).round(2)
      
      update_columns(
        price_variance_vs_target: variance * quantity_requested,
        price_variance_percentage: percentage
      )
    end
    
    if selected_unit_price && last_purchase_price
      variance = (selected_unit_price - last_purchase_price) * quantity_requested
      update_column(:price_variance_vs_last, variance)
    end
    
    if selected_total_price && highest_quoted_price
      savings = (highest_quoted_price - selected_unit_price) * quantity_requested
      update_column(:savings_vs_highest_quote, savings)
    end
  end
  
  private
  
  def set_line_number
    self.line_number ||= (rfq.rfq_items.maximum(:line_number) || 0) + 10
  end
  
  def calculate_target_total
    if target_unit_price && quantity_requested
      self.target_total_price = target_unit_price * quantity_requested
    end
  end
end

