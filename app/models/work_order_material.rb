# app/models/work_order_material.rb

class WorkOrderMaterial < ApplicationRecord
  include OrganizationScoped
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :work_order
  belongs_to :bom_item, optional: true
  belongs_to :product  # The component/material
  belongs_to :uom, class_name: "UnitOfMeasure"
  belongs_to :batch, class_name: "StockBatch", optional: true
  belongs_to :location, optional: true
  belongs_to :issued_by, class_name: "User", optional: true
  
  # ========================================
  # CONSTANTS
  # ========================================
  STATUSES = %w[REQUIRED ALLOCATED ISSUED CONSUMED RETURNED].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :product_id, presence: true
  validates :quantity_required, numericality: { greater_than: 0 }
  validates :quantity_allocated, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_consumed, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  
  validate :consumed_cannot_exceed_required
  validate :allocated_cannot_exceed_available_stock
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_save :calculate_total_cost
  after_update :update_work_order_material_cost, if: :saved_change_to_quantity_consumed?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :non_deleted, -> { where(deleted: false) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :required, -> { where(status: 'REQUIRED') }
  scope :allocated, -> { where(status: 'ALLOCATED') }
  scope :issued, -> { where(status: 'ISSUED') }
  scope :consumed, -> { where(status: 'CONSUMED') }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  
  def consumed_cannot_exceed_required
    if quantity_consumed.to_d > quantity_required.to_d
      errors.add(:quantity_consumed, "cannot exceed quantity required")
    end
  end
  
  def allocated_cannot_exceed_available_stock
    return if location.blank? || product.blank?
    return unless status == 'ALLOCATED' && quantity_allocated_changed?
    
    # Check available stock at location
    available = StockLevel.where(
      product_id: product_id,
      location_id: location_id
    ).sum(:on_hand_qty)
    
    if quantity_allocated.to_d > available.to_d
      errors.add(:quantity_allocated, "exceeds available stock (#{available} available)")
    end
  end
  
  # ========================================
  # CALLBACK METHODS
  # ========================================
  
  def calculate_total_cost
    self.total_cost = (quantity_consumed.to_d * unit_cost.to_d).round(2)
  end
  
  def update_work_order_material_cost
    # When material consumption changes, update WO's actual material cost
    work_order.recalculate_actual_costs if work_order.present?
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  # Allocate material from inventory (reserve it)
  def allocate_material!(location_obj, batch_obj = nil, qty = nil)
    return false unless status == 'REQUIRED'
    allocation_qty = qty || quantity_required
    
    # Check if stock is available
    available = if batch_obj.present?
      StockLevel.where(
        product_id: product_id,
        location_id: location_obj.id,
        batch_id: batch_obj.id
      ).sum(:on_hand_qty)
    else
      StockLevel.where(
        product_id: product_id,
        location_id: location_obj.id
      ).sum(:on_hand_qty)
    end
    
    if available < allocation_qty
      errors.add(:base, "Insufficient stock available for allocation")
      return false
    end
    
    self.location = location_obj
    self.batch = batch_obj if batch_obj.present?
    self.quantity_allocated = allocation_qty
    self.status = 'ALLOCATED'
    self.allocated_at = Time.current
    
    save
  end
  
  # Issue material to production floor (create stock transaction)
  def issue_material!(issued_by_user, qty = nil)
    return false unless status == 'ALLOCATED'
    
    issue_qty = qty || quantity_allocated
    
    # Create StockTransaction for material issue
    transaction = StockTransaction.create!(
      txn_type: 'PRODUCTION_CONSUMPTION',
      product_id: product_id,
      quantity: issue_qty,  # Negative because it's going OUT
      uom_id: uom_id,
      from_location_id: location_id,
      batch_id: batch_id,
      reference_type: 'WorkOrder',
      reference_id: work_order_id,
      created_at: Date.current,
      created_by_id: issued_by_user.id,
      note: "Issued for WO: #{work_order.wo_number}"
    )
    
    if transaction.persisted?
      self.status = 'ISSUED'
      self.issued_at = Time.current
      self.issued_by = issued_by_user
      self.quantity_consumed = issue_qty  # Assume issued = consumed for now
      
      save
    else
      errors.add(:base, "Failed to create stock transaction")
      false
    end
  end
  
  # Record actual material consumption (if different from issued)
  def record_consumption!(qty_consumed)
    return false unless ['ISSUED', 'CONSUMED'].include?(status)
    
    self.quantity_consumed = qty_consumed
    self.status = 'CONSUMED'
    
    # Update cost based on actual consumption
    self.total_cost = (qty_consumed.to_d * unit_cost.to_d).round(2)
    
    save
  end
  
  # Return excess material to inventory
  def return_material!(qty_to_return, returned_by_user)
    return false unless status == 'CONSUMED'
    return false if qty_to_return > quantity_consumed
    
    # Create StockTransaction for material return
    transaction = StockTransaction.create!(
      txn_type: 'PRODUCTION_RETURN',
      product_id: product_id,
      quantity: qty_to_return,  # Positive because it's coming back
      uom_id: uom_id,
      to_location_id: location_id,
      batch_id: batch_id,
      reference_type: 'WorkOrder',
      reference_id: work_order_id,
      created_at: Date.current,
      created_by_id: returned_by_user.id,
      note: "Returned from WO: #{work_order.wo_number}"
    )
    
    if transaction.persisted?
      self.quantity_consumed -= qty_to_return
      self.total_cost = (quantity_consumed.to_d * unit_cost.to_d).round(2)
      self.status = 'RETURNED'
      
      save
    else
      errors.add(:base, "Failed to create return transaction")
      false
    end
  end
  
  # ========================================
  # HELPER METHODS
  # ========================================
  
  def quantity_variance
    quantity_required.to_d - quantity_consumed.to_d
  end
  
  def quantity_variance_percent
    return 0 if quantity_required.zero?
    ((quantity_variance / quantity_required.to_d) * 100).round(2)
  end
  
  def cost_variance
    planned_cost = (quantity_required.to_d * unit_cost.to_d)
    planned_cost - total_cost.to_d
  end
  
  def is_fully_consumed?
    quantity_consumed >= quantity_required
  end
  
  def is_over_consumed?
    quantity_consumed > quantity_required
  end
  
  def remaining_quantity
    (quantity_required.to_d - quantity_consumed.to_d).round(4)
  end
  
  def consumption_percentage
    return 0 if quantity_required.zero?
    ((quantity_consumed.to_d / quantity_required.to_d) * 100).round(2)
  end
  
  def status_badge_class
    case status
    when 'REQUIRED' then 'secondary'
    when 'ALLOCATED' then 'info'
    when 'ISSUED' then 'warning'
    when 'CONSUMED' then 'success'
    when 'RETURNED' then 'primary'
    else 'secondary'
    end
  end
  
  def display_name
    "#{product.sku} - #{product.name}"
  end
  
  # Soft delete
  def destroy!
    update_attribute(:deleted, true)
  end
end
