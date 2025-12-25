class VendorQuote < ApplicationRecord
  belongs_to :rfq
  belongs_to :rfq_item
  belongs_to :supplier
  belongs_to :rfq_supplier
  belongs_to :selected_by, class_name: 'User', optional: true
  belongs_to :reviewed_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  belongs_to :superseded_by, class_name: 'VendorQuote', optional: true
  
  validates :quote_date, :unit_price, :total_price, :lead_time_days, presence: true
  validates :unit_price, :total_price, numericality: { greater_than: 0 }
  validates :lead_time_days, numericality: { greater_than: 0 }
  
  scope :latest, -> { where(is_latest_revision: true) }
  scope :selected, -> { where(is_selected: true) }
  scope :lowest_price, -> { where(is_lowest_price: true) }
  scope :fastest_delivery, -> { where(is_fastest_delivery: true) }
  scope :best_value, -> { where(is_best_value: true) }
  scope :recommended, -> { where(is_recommended: true) }
  scope :by_rank, -> { order(:overall_rank) }
  scope :by_price, -> { order(:unit_price) }
  scope :by_delivery, -> { order(:lead_time_days) }
  
  before_save :calculate_total_cost
  after_create :update_rfq_item_statistics
  after_save :calculate_rankings, if: :saved_change_to_unit_price?
  
  def calculate_scores!(rfq)
    # Get all competing quotes for this item
    competing_quotes = rfq_item.vendor_quotes.latest
    
    # 1. PRICE SCORE (0-100, lower price = higher score)
    prices = competing_quotes.pluck(:unit_price)
    min_price = prices.min
    max_price = prices.max
    price_range = max_price - min_price
    
    if price_range.zero?
      self.price_score = 100
    else
      # Inverse scoring: lowest price gets 100, highest gets 0
      self.price_score = ((max_price - unit_price) / price_range * 100).round(2)
    end
    
    # 2. DELIVERY SCORE (0-100, faster = higher score)
    lead_times = competing_quotes.pluck(:lead_time_days)
    min_lead_time = lead_times.min
    max_lead_time = lead_times.max
    lead_time_range = max_lead_time - min_lead_time
    
    if lead_time_range.zero?
      self.delivery_score = 100
    else
      # Inverse scoring: shortest lead time gets 100
      self.delivery_score = ((max_lead_time - lead_time_days) / lead_time_range * 100).round(2)
    end
    
    # 3. QUALITY SCORE (from supplier's overall rating)
    self.quality_score = supplier.overall_rating || 75
    
    # 4. SERVICE SCORE (from supplier's service rating)
    self.service_score = supplier.service_score || 75
    
    # 5. OVERALL WEIGHTED SCORE
    weights = rfq.weights
    self.overall_score = (
      (price_score * weights[:price] / 100) +
      (delivery_score * weights[:delivery] / 100) +
      (quality_score * weights[:quality] / 100) +
      (service_score * weights[:service] / 100)
    ).round(2)
    
    save if changed?
  end
  
  def calculate_total_price!(quote)
    # Base price
    base = unit_price × quantity_requested
    
    # Additional costs
    additional = tooling_cost + 
                 setup_cost + 
                 shipping_cost + 
                 other_charges
    
    total_price = base + additional
  end

  def generate_quote_number(supplier)
    # Format: QT-SUP001-20241223-001
    prefix = supplier.supplier_code || supplier.id.to_s.rjust(3, '0')
    date_part = Date.current.strftime('%Y%m%d')
    sequence = VendorQuote.where(supplier: supplier).count + 1
    
    "QT-#{prefix}-#{date_part}-#{sequence.to_s.rjust(3, '0')}"
  end

  def calculate_rankings
    # Rank among all quotes for this RFQ item
    quotes = rfq_item.vendor_quotes.latest.order(:unit_price)
    
    # Price rankings
    quotes.each_with_index do |quote, index|
      quote.update_column(:price_rank, index + 1)
      quote.update_column(:is_lowest_price, index.zero?)
    end
    
    # Delivery rankings
    quotes_by_delivery = rfq_item.vendor_quotes.latest.order(:lead_time_days)
    quotes_by_delivery.each_with_index do |quote, index|
      quote.update_column(:delivery_rank, index + 1)
      quote.update_column(:is_fastest_delivery, index.zero?)
    end
    
    # Total cost rankings
    quotes_by_cost = rfq_item.vendor_quotes.latest.order(:total_cost)
    quotes_by_cost.each_with_index do |quote, index|
      quote.update_column(:total_cost_rank, index + 1)
    end
    
    # Overall rankings (by score)
    quotes_by_score = rfq_item.vendor_quotes.latest.order(overall_score: :desc)
    quotes_by_score.each_with_index do |quote, index|
      quote.update_column(:overall_rank, index + 1)
      quote.update_column(:is_best_value, index.zero?)
    end
  end
  
  def calculate_price_comparisons!
    # Compare with lowest price
    lowest = rfq_item.lowest_quoted_price
    if lowest && lowest > 0
      diff = ((unit_price - lowest) / lowest * 100).round(2)
      update_column(:price_vs_lowest_percentage, diff)
    end
    
    # Compare with average
    average = rfq_item.average_quoted_price
    if average && average > 0
      diff = ((unit_price - average) / average * 100).round(2)
      update_column(:price_vs_average_percentage, diff)
    end
    
    # Compare with target
    if rfq_item.target_unit_price && rfq_item.target_unit_price > 0
      diff = ((unit_price - rfq_item.target_unit_price) / rfq_item.target_unit_price * 100).round(2)
      update_column(:price_vs_target_percentage, diff)
    end
    
    # Compare with last purchase
    if rfq_item.last_purchase_price && rfq_item.last_purchase_price > 0
      diff = ((unit_price - rfq_item.last_purchase_price) / rfq_item.last_purchase_price * 100).round(2)
      update_column(:price_vs_last_purchase_percentage, diff)
    end
  end
  
  # ============================================================================
  # QUOTE MANAGEMENT
  # ============================================================================
  def create_revision!(attributes, updated_by_user)
    new_quote = self.class.new(
      attributes.merge(
        rfq: rfq,
        rfq_item: rfq_item,
        supplier: supplier,
        rfq_supplier: rfq_supplier,
        quote_revision: quote_revision + 1,
        created_by: updated_by_user,
        superseded_by: nil,
        is_latest_revision: true
      )
    )
    
    if new_quote.save
      update!(is_latest_revision: false, superseded_by: new_quote)
      new_quote
    end
  end
  
  def select!(selected_by_user, reason: nil)
    update!(
      is_selected: true,
      selected_by: selected_by_user,
      selected_date: Date.current,
      selection_reason: reason,
      quote_status: 'ACCEPTED'
    )
    
    rfq_item.select_quote!(self, selected_by_user, reason: reason)
  end
  
  def reject!(reviewed_by_user, reason: nil)
    update!(
      quote_status: 'REJECTED',
      reviewed_by: reviewed_by_user,
      reviewed_at: Time.current,
      review_notes: reason
    )
  end
  
  # ============================================================================
  # DISPLAY HELPERS
  # ============================================================================
  def price_difference_from_lowest
    return 0 unless rfq_item.lowest_quoted_price
    unit_price - rfq_item.lowest_quoted_price
  end
  
  def is_competitive?
    price_vs_average_percentage && price_vs_average_percentage <= 5
  end
  
  def delivery_status
    if can_meet_required_date
      'On Time'
    else
      "#{days_after_required_date} days late"
    end
  end
  
  def highlight_class
    return 'best-value' if is_best_value
    return 'lowest-price' if is_lowest_price
    return 'fastest-delivery' if is_fastest_delivery
    nil
  end
  
  private
  
  def calculate_total_cost
    self.total_cost = total_price + 
                      (tooling_cost || 0) + 
                      (setup_cost || 0) + 
                      (shipping_cost || 0) + 
                      (other_charges || 0)
  end
  
  def update_rfq_item_statistics
    rfq_item.calculate_quote_statistics!
    rfq_supplier.calculate_quote_summary!
  end
end
