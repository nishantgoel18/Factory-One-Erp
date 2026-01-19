class ProductSupplier < ApplicationRecord
  include OrganizationScoped
  belongs_to :product
  belongs_to :supplier
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  
  validates :product_id, uniqueness: { scope: :supplier_id }
  validates :current_unit_price, presence: true, numericality: { greater_than: 0 }
  validates :lead_time_days, presence: true, numericality: { greater_than: 0 }
  validates :minimum_order_quantity, numericality: { greater_than_or_equal_to: 1 }
  
  scope :active, -> { where(is_active: true) }
  scope :approved, -> { where(is_approved_supplier: true) }
  scope :preferred, -> { where(is_preferred_supplier: true) }
  scope :available, -> { where(available_for_order: true) }
  scope :by_price, -> { order(:current_unit_price) }
  scope :by_lead_time, -> { order(:lead_time_days) }
  scope :by_quality, -> { order(quality_rating: :desc) }
  scope :by_rank, -> { order(:supplier_rank) }
  
  # ============================================================================
  # VENDOR SELECTION LOGIC (FOR MRP!)
  # ============================================================================
  def selection_score(criteria = {})
    urgency = criteria[:urgency] || 'normal'
    
    case urgency.to_s.downcase
    when 'critical', 'urgent'
      # Speed is priority
      lead_time_score = (100 - lead_time_days * 2).clamp(0, 100)
      quality_weight = 0.3
      speed_weight = 0.5
      price_weight = 0.2
    when 'cost_sensitive'
      # Price is priority
      price_score = calculate_price_competitiveness
      quality_weight = 0.2
      speed_weight = 0.2
      price_weight = 0.6
    else
      # Balanced
      quality_weight = 0.4
      speed_weight = 0.3
      price_weight = 0.3
    end
    
    lead_time_score ||= (100 - lead_time_days * 2).clamp(0, 100)
    price_score ||= calculate_price_competitiveness
    
    (quality_rating * quality_weight) + (lead_time_score * speed_weight) + (price_score * price_weight)
  end
  
  def calculate_price_competitiveness
    # Compare with other suppliers for same product
    all_prices = product.product_suppliers.active.pluck(:current_unit_price)
    return 100 if all_prices.size <= 1
    
    min_price = all_prices.min
    max_price = all_prices.max
    range = max_price - min_price
    return 100 if range.zero?
    
    # Lower price = higher score
    ((max_price - current_unit_price) / range * 100).round(2)
  end
  
  def update_price!(new_price, effective_date = Date.current)
    self.previous_unit_price = current_unit_price
    self.current_unit_price = new_price
    self.price_effective_date = effective_date
    
    if previous_unit_price.present?
      change = ((new_price - previous_unit_price) / previous_unit_price * 100).round(2)
      self.price_change_percentage = change
      self.price_trend = change > 2 ? 'INCREASING' : (change < -2 ? 'DECREASING' : 'STABLE')
    end
    
    save!
  end
  
  def get_price_for_quantity(qty)
    return current_unit_price if qty < (price_break_1_qty || Float::INFINITY)
    return price_break_1_price if price_break_1_qty && qty >= price_break_1_qty && qty < (price_break_2_qty || Float::INFINITY)
    return price_break_2_price if price_break_2_qty && qty >= price_break_2_qty && qty < (price_break_3_qty || Float::INFINITY)
    return price_break_3_price if price_break_3_qty && qty >= price_break_3_qty
    current_unit_price
  end
  
  def record_purchase!(quantity, price, order_date = Date.current)
    self.last_purchase_date = order_date
    self.last_purchase_price = price
    self.last_purchase_quantity = quantity
    self.total_orders_count += 1
    self.total_quantity_purchased = (total_quantity_purchased || 0) + quantity
    self.total_value_purchased = (total_value_purchased || 0) + (quantity * price)
    self.average_purchase_price = total_value_purchased / total_quantity_purchased
    self.days_since_last_order = 0
    self.first_purchase_date ||= order_date
    save!
  end
end
