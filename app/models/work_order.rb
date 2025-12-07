# app/models/work_order.rb

class WorkOrder < ApplicationRecord
  # ========================================
  # ASSOCIATIONS
  # ========================================
  belongs_to :product
  belongs_to :bom, class_name: "BillOfMaterial", optional: true
  belongs_to :routing, optional: true
  belongs_to :customer, optional: true
  belongs_to :warehouse
  belongs_to :uom, class_name: "UnitOfMeasure"
  
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :released_by, class_name: "User", optional: true
  belongs_to :completed_by, class_name: "User", optional: true
  
  has_many :work_order_operations, -> { where(deleted: false).order(:sequence_no) }, dependent: :destroy
  has_many :work_order_materials, -> { where(deleted: false) }, dependent: :destroy
  
  # ========================================
  # CONSTANTS
  # ========================================
  STATUSES = %w[NOT_STARTED RELEASED IN_PROGRESS COMPLETED CANCELLED].freeze
  PRIORITIES = %w[LOW NORMAL HIGH URGENT].freeze
  
  # ========================================
  # VALIDATIONS
  # ========================================
  validates :wo_number, presence: true, uniqueness: true
  validates :product_id, presence: true
  validates :quantity_to_produce, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }
  
  validates :scheduled_start_date, presence: true
  validates :scheduled_end_date, presence: true
  
  # Custom validations
  validate :product_must_have_bom_and_routing
  validate :end_date_after_start_date
  validate :valid_status_transition, on: :update
  validate :cannot_release_without_bom_and_routing
  validate :quantity_completed_cannot_exceed_to_produce
  
  # ========================================
  # CALLBACKS
  # ========================================
  before_validation :set_wo_number, on: :create
  before_validation :auto_fetch_bom_and_routing, on: :create
  before_create :calculate_planned_costs
  
  after_update :handle_status_change, if: :saved_change_to_status?
  
  # ========================================
  # SCOPES
  # ========================================
  scope :non_deleted, -> { where(deleted: false) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :scheduled_between, ->(start_date, end_date) { 
    where("scheduled_start_date >= ? AND scheduled_end_date <= ?", start_date, end_date) 
  }
  
  # ========================================
  # CUSTOM VALIDATIONS
  # ========================================
  
  def product_must_have_bom_and_routing
    return if product.blank?
    
    allowed_types = ["Finished Goods", "Semi-Finished Goods"]
    unless allowed_types.include?(product.product_type)
      errors.add(:product_id, "must be a Finished Goods or Semi-Finished Goods to create a Work Order")
    end
  end
  
  def end_date_after_start_date
    return if scheduled_start_date.blank? || scheduled_end_date.blank?
    
    if scheduled_end_date < scheduled_start_date
      errors.add(:scheduled_end_date, "must be after the start date")
    end
  end
  
  def valid_status_transition
    return if status_was.nil? || !status_changed? # New record
    
    valid_transitions = {
      'NOT_STARTED' => ['RELEASED', 'CANCELLED'],
      'RELEASED' => ['IN_PROGRESS', 'CANCELLED'],
      'IN_PROGRESS' => ['COMPLETED', 'CANCELLED'],
      'COMPLETED' => [],
      'CANCELLED' => []
    }
    
    allowed = valid_transitions[status_was] || []
    
    unless allowed.include?(status)
      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    end
  end
  
  def cannot_release_without_bom_and_routing
    return unless status == 'RELEASED' && status_was == 'NOT_STARTED'
    
    if bom.blank?
      errors.add(:base, "Cannot release Work Order without an active BOM")
    end
    
    if routing.blank?
      errors.add(:base, "Cannot release Work Order without an active Routing")
    end
  end
  
  def quantity_completed_cannot_exceed_to_produce
    return if quantity_completed.blank?
    
    if quantity_completed > quantity_to_produce
      errors.add(:quantity_completed, "cannot exceed quantity to produce")
    end
  end
  
  # ========================================
  # CALLBACKS METHODS
  # ========================================
  
  def set_wo_number
    return if wo_number.present?
    
    # Generate WO number: WO-YYYY-0001
    year = Date.current.year
    last_wo = WorkOrder.where("wo_number LIKE ?", "WO-#{year}-%")
                       .order(wo_number: :desc)
                       .first
    
    if last_wo && last_wo.wo_number =~ /WO-#{year}-(\d+)/
      next_number = $1.to_i + 1
    else
      next_number = 1
    end
    
    self.wo_number = "WO-#{year}-#{next_number.to_s.rjust(4, '0')}"
  end
  
  def auto_fetch_bom_and_routing
    return if product.blank?
    
    # Fetch active BOM (prefer default, otherwise get active)
    self.bom ||= product.bill_of_materials
                        .non_deleted
                        .where(status: 'ACTIVE')
                        .order(is_default: :desc, effective_from: :desc)
                        .first
    
    # Fetch active Routing (prefer default, otherwise get active)
    self.routing ||= product.routings
                            .non_deleted
                            .where(status: 'ACTIVE')
                            .order(is_default: :desc)
                            .first
  end
  
  def calculate_planned_costs
    calculate_planned_material_cost
    calculate_planned_labor_and_overhead_cost
  end
  
  def calculate_planned_material_cost
    return unless bom.present?
    
    total_material_cost = BigDecimal("0")
    
    bom.bom_items.where(deleted: false).includes(:component).each do |bom_item|
      component_cost = bom_item.component.standard_cost.to_d
      required_qty = bom_item.quantity.to_d * quantity_to_produce.to_d
      
      # Consider scrap percentage
      if bom_item.scrap_percent.to_d > 0
        scrap_factor = 1 + (bom_item.scrap_percent.to_d / 100)
        required_qty = required_qty * scrap_factor
      end
      
      total_material_cost += (required_qty * component_cost)
    end
    
    self.planned_material_cost = total_material_cost.round(2)
  end
  
  def calculate_planned_labor_and_overhead_cost
    return unless routing.present?
    
    total_labor = BigDecimal("0")
    total_overhead = BigDecimal("0")
    
    routing.routing_operations.where(deleted: false).includes(:work_center).each do |routing_op|
      wc = routing_op.work_center
      
      # Setup cost (one-time per batch)
      setup_hours = routing_op.setup_time_minutes.to_d / 60
      setup_labor = wc.labor_cost_per_hour.to_d * setup_hours
      setup_overhead = wc.overhead_cost_per_hour.to_d * setup_hours
      
      # Run cost (per unit × quantity)
      run_hours_per_unit = routing_op.run_time_per_unit_minutes.to_d / 60
      run_hours_total = run_hours_per_unit * quantity_to_produce.to_d
      run_labor = wc.labor_cost_per_hour.to_d * run_hours_total
      run_overhead = wc.overhead_cost_per_hour.to_d * run_hours_total
      
      total_labor += (setup_labor + run_labor)
      total_overhead += (setup_overhead + run_overhead)
    end
    
    self.planned_labor_cost = total_labor.round(2)
    self.planned_overhead_cost = total_overhead.round(2)
  end
  
  def handle_status_change
    case status
    when 'RELEASED'
      handle_release
    when 'IN_PROGRESS'
      handle_start_production
    when 'COMPLETED'
      handle_completion
    when 'CANCELLED'
      handle_cancellation
    end
  end
  
  def handle_release
    self.update_attribute(:released_at, Time.current)
    
    # Auto-create operations from routing
    create_operations_from_routing!
    
    # Auto-create materials from BOM
    create_materials_from_bom!

    if released_by.present?
      WorkOrderNotificationJob.perform_later('released', id, self.released_by.email)
    end
  end
  
  def handle_start_production
    self.update_attribute(:actual_start_date, Time.current)
  end
  
  def handle_completion
    self.update_attribute(:actual_end_date, Time.current)
    self.update_attribute(:quantity_completed, quantity_to_produce) unless quantity_completed.present?
    self.update_attribute(:completed_at, Time.current)

    # Calculate actual costs from child records
    recalculate_actual_costs
    
    # Create stock transaction for finished goods receipt
    receive_finished_goods_to_inventory

    # Send completion notification
    if self.completed_by.present?
      WorkOrderNotificationJob.perform_later('completed', id, self.completed_by.email)
    end
    
    # Notify production manager
    if self.created_by.present? && self.created_by != self.completed_by
      WorkOrderNotificationJob.perform_later('completed', id, self.created_by.email)
    end
  end
  
  def handle_cancellation
    # Return all allocated/issued materials back to inventory
    work_order_materials.where(status: ['ALLOCATED', 'ISSUED']).each do |wo_material|
      next unless wo_material.location_id.present?
      
      # Create stock transaction to return material
      if wo_material.quantity_issued.to_d > 0
        StockTransaction.create!(
          transaction_type: 'PRODUCTION_RETURN',
          product_id: wo_material.product_id,
          quantity: wo_material.quantity_issued,
          uom_id: wo_material.uom_id,
          to_location_id: wo_material.location_id,
          batch_number: wo_material.batch_number,
          reference_type: 'WorkOrder',
          reference_id: id,
          reference_number: wo_number,
          transaction_date: Date.current,
          notes: "Material returned due to Work Order cancellation",
          created_by_id: Current.user&.id || completed_by_id
        )
        
        # Update stock level
        stock_level = StockLevel.find_or_initialize_by(
          product_id: wo_material.product_id,
          location_id: wo_material.location_id,
          batch_number: wo_material.batch_number
        )
        stock_level.on_hand_qty = (stock_level.on_hand_qty.to_d + wo_material.quantity_issued.to_d)
        stock_level.save!
      end
      
      # Mark material as CANCELLED
      wo_material.update!(status: 'CANCELLED')
    end
    
    # Cancel all pending/in-progress operations
    work_order_operations.where(status: ['PENDING', 'IN_PROGRESS']).each do |operation|
      # Clock out any active labor entries
      operation.labor_time_entries.active.each do |entry|
        entry.clock_out!(Time.current)
      end
      
      operation.update!(status: 'CANCELLED')
    end
    
    # Send cancellation notification
    if created_by.present?
      WorkOrderNotificationJob.perform_later('cancelled', id, created_by.email)
    end
  end
  
  # ========================================
  # BUSINESS LOGIC METHODS
  # ========================================
  
  def create_operations_from_routing!
    return unless routing.present?
    
    routing.routing_operations.order(:operation_sequence).each do |routing_op|
      wc = routing_op.work_center
      
      # Calculate planned time
      setup_mins = routing_op.setup_time_minutes.to_i
      run_mins_per_unit = routing_op.run_time_per_unit_minutes.to_d
      total_run_mins = (run_mins_per_unit * quantity_to_produce.to_d).to_i
      total_mins = setup_mins + total_run_mins
      
      # Calculate planned cost
      setup_hours = setup_mins.to_d / 60
      run_hours = total_run_mins.to_d / 60
      operation_cost = (wc.total_cost_per_hour.to_d * (setup_hours + run_hours)).round(2)
      
      work_order_operations.create!(
        routing_operation_id: routing_op.id,
        work_center_id: routing_op.work_center_id,
        sequence_no: routing_op.operation_sequence,
        operation_name: routing_op.operation_name,
        operation_description: routing_op.description,
        quantity_to_process: quantity_to_produce,
        planned_setup_minutes: setup_mins,
        planned_run_minutes_per_unit: run_mins_per_unit,
        planned_total_minutes: total_mins,
        planned_cost: operation_cost,
        status: 'PENDING'
      )
    end
  end
  
  def create_materials_from_bom!
    return unless bom.present?
    
    bom.bom_items.where(deleted: false).includes(:component).each do |bom_item|
      required_qty = bom_item.quantity.to_d * quantity_to_produce.to_d
      
      # Consider scrap percentage
      if bom_item.scrap_percent.to_d > 0
        scrap_factor = 1 + (bom_item.scrap_percent.to_d / 100)
        required_qty = required_qty * scrap_factor
      end
      
      component_cost = bom_item.component.standard_cost.to_d
      total_cost = (required_qty * component_cost).round(2)
      
      work_order_materials.create!(
        bom_item_id: bom_item.id,
        product_id: bom_item.component_id,
        uom_id: bom_item.uom_id,
        quantity_required: required_qty.round(4),
        unit_cost: component_cost.round(4),
        total_cost: total_cost,
        status: 'REQUIRED'
      )
    end
  end
  
  def recalculate_actual_costs
    # Material cost from work_order_materials
    self.actual_material_cost = work_order_materials.sum(:total_cost).round(2)
    
    # Labor and overhead from work_order_operations
    self.actual_labor_cost = BigDecimal("0")
    self.actual_overhead_cost = BigDecimal("0")
    
    work_order_operations.where(status: 'COMPLETED').includes(:work_center).each do |op|
      wc = op.work_center
      actual_hours = op.actual_total_minutes.to_d / 60
      
      self.actual_labor_cost += (wc.labor_cost_per_hour.to_d * actual_hours)
      self.actual_overhead_cost += (wc.overhead_cost_per_hour.to_d * actual_hours)
    end
    
    self.actual_labor_cost = self.actual_labor_cost.round(2)
    self.actual_overhead_cost = self.actual_overhead_cost.round(2)
    
    save
  end
  
  def receive_finished_goods_to_inventory
    return unless quantity_completed.to_d > 0
    
    # Determine destination location
    # Priority: 1) Warehouse's FG location, 2) First active location, 3) Error
    fg_location = warehouse.locations.non_deleted
                          .where(location_type: 'FINISHED_GOODS')
                          .first
    
    fg_location ||= warehouse.locations.non_deleted.first
    
    unless fg_location
      raise "No valid location found in warehouse #{warehouse.name} to receive finished goods"
    end
    
    # Create stock transaction for finished goods receipt
    stock_transaction = StockTransaction.create!(
      transaction_type: 'PRODUCTION_OUTPUT',
      product_id: product_id,
      quantity: quantity_completed,
      uom_id: uom_id,
      to_location_id: fg_location.id,
      reference_type: 'WorkOrder',
      reference_id: id,
      reference_number: wo_number,
      transaction_date: Date.current,
      notes: "Finished goods received from Work Order #{wo_number}",
      created_by_id: completed_by_id || current_user&.id
    )
    
    # Update or create stock level for finished goods
    stock_level = StockLevel.find_or_initialize_by(
      product_id: product_id,
      location_id: fg_location.id,
      batch_number: nil  # FG typically don't have batch numbers unless you want to track by WO
    )
    
    stock_level.on_hand_qty = (stock_level.on_hand_qty.to_d + quantity_completed.to_d)
    stock_level.save!
    
    # Optional: Update product's last_cost based on actual production cost
    if total_actual_cost > 0
      unit_cost = (total_actual_cost / quantity_completed).round(4)
      product.update!(last_cost: unit_cost)
    end
    
    stock_transaction
  rescue => e
    Rails.logger.error "Failed to receive finished goods for WO #{wo_number}: #{e.message}"
    errors.add(:base, "Failed to receive finished goods: #{e.message}")
    raise ActiveRecord::Rollback
  end

  def check_material_shortages
    shortage_details = []
    
    return shortage_details unless bom.present?
    
    work_order_materials.each do |wo_material|
      # Calculate available stock across all locations in the warehouse
      available_qty = StockLevel.joins(:location)
                                .where(product_id: wo_material.product_id)
                                .where(locations: { warehouse_id: warehouse_id })
                                .sum(:on_hand_qty)
      
      required_qty = wo_material.quantity_required
      
      # Check if there's a shortage
      if available_qty < required_qty
        shortage_details << {
          material_code: wo_material.product.sku,
          material_name: wo_material.product.name,
          required_qty: required_qty,
          available_qty: available_qty,
          shortage_qty: required_qty - available_qty,
          uom: wo_material.uom.symbol
        }
      end
    end
    
    shortage_details
  end

  def previous_in_progress_operations_before(op)
    op.work_order.work_order_operations.where("sequence_no < ?", op.sequence_no).where(status: 'IN_PROGRESS')
  end
  
  # ========================================
  # HELPER METHODS
  # ========================================

  def total_planned_cost
    (planned_material_cost.to_d + planned_labor_cost.to_d + planned_overhead_cost.to_d).round(2)
  end
  
  def total_actual_cost
    (actual_material_cost.to_d + actual_labor_cost.to_d + actual_overhead_cost.to_d).round(2)
  end
  
  def cost_variance
    total_planned_cost - total_actual_cost
  end
  
  def cost_variance_percent
    return 0 if total_planned_cost.zero?
    ((cost_variance / total_planned_cost) * 100).round(2)
  end
  
  def progress_percentage
    return 0 if quantity_to_produce.zero?
    ((quantity_completed.to_d / quantity_to_produce.to_d) * 100).round(2)
  end
  
  def operations_completed_count
    work_order_operations.where(status: 'COMPLETED').count
  end
  
  def operations_total_count
    work_order_operations.count
  end
  
  def operations_progress_percentage
    return 0 if operations_total_count.zero?
    ((operations_completed_count.to_f / operations_total_count) * 100).round(2)
  end
  
  def can_be_released?
    status == 'NOT_STARTED' && bom.present? && routing.present?
  end
  
  def can_start_production?
    status == 'RELEASED'
  end
  
  def can_be_completed?
    status == 'IN_PROGRESS' && all_operations_completed?
  end
  
  def all_operations_completed?
    work_order_operations.where.not(status: 'COMPLETED').none?
  end
  
  def can_be_cancelled?
    ['NOT_STARTED', 'RELEASED', 'IN_PROGRESS'].include?(status)
  end
  
  def status_badge_class
    case status
    when 'NOT_STARTED' then 'secondary'
    when 'RELEASED' then 'info'
    when 'IN_PROGRESS' then 'warning'
    when 'COMPLETED' then 'success'
    when 'CANCELLED' then 'danger'
    else 'secondary'
    end
  end
  
  def priority_badge_class
    case priority
    when 'URGENT' then 'danger'
    when 'HIGH' then 'warning'
    when 'NORMAL' then 'info'
    when 'LOW' then 'secondary'
    else 'secondary'
    end
  end
  
  # ========================================
  # SOFT DELETE
  # ========================================
  def destroy!
    update_attribute(:deleted, true)
  end
end
