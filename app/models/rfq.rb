# frozen_string_literal: true

# ============================================================================
# MODEL: Rfq (Request for Quote)
# Complete RFQ management with vendor selection algorithm
# ============================================================================
class Rfq < ApplicationRecord
  include OrganizationScoped
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  # Line Items
  has_many :rfq_items, dependent: :destroy
  has_many :products, through: :rfq_items
  
  # Supplier Invitations
  has_many :rfq_suppliers, dependent: :destroy
  has_many :suppliers, through: :rfq_suppliers
  
  # Quotes
  has_many :vendor_quotes, dependent: :destroy
  
  # Awarded/Selected
  belongs_to :awarded_supplier, class_name: 'Supplier', optional: true
  belongs_to :recommended_supplier, class_name: 'Supplier', optional: true
  
  # Users
  belongs_to :created_by, class_name: 'User'
  belongs_to :requester, class_name: 'User', optional: true
  belongs_to :buyer_assigned, class_name: 'User', optional: true
  belongs_to :approver, class_name: 'User', optional: true
  belongs_to :cancelled_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true
  
  # Future: Purchase Order
  has_many :purchase_orders, dependent: :nullify
  belongs_to :converted_by, class_name: "User", optional: true
  
  # ============================================================================
  # NESTED ATTRIBUTES
  # ============================================================================
  accepts_nested_attributes_for :rfq_items, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :rfq_suppliers, allow_destroy: true
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :rfq_number, presence: true, uniqueness: { case_sensitive: false }
  validates :title, presence: true, length: { maximum: 255 }
  validates :rfq_date, :due_date, :response_deadline, presence: true
  validates :status, presence: true, inclusion: { 
    in: %w[DRAFT SENT RESPONSES_RECEIVED UNDER_REVIEW AWARDED CLOSED CANCELLED],
    message: "%{value} is not a valid status"
  }
  validate :due_date_after_rfq_date
  validate :response_deadline_valid
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :generate_rfq_number, on: :create
  before_validation :set_defaults
  after_create :initialize_scoring_weights
  before_save :calculate_totals
  after_update :update_supplier_counts, if: :saved_change_to_status?

  before_save :set_items_line_numbers
  before_create :set_supplier_invited_date_stamps

  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :non_deleted, -> { where(is_deleted: false) }
  scope :active, -> { non_deleted.where.not(status: ['CLOSED', 'CANCELLED']) }
  scope :draft, -> { where(status: 'DRAFT') }
  scope :sent, -> { where(status: 'SENT') }
  scope :with_responses, -> { where(status: 'RESPONSES_RECEIVED') }
  scope :under_review, -> { where(status: 'UNDER_REVIEW') }
  scope :awarded, -> { where(status: 'AWARDED') }
  scope :closed, -> { where(status: 'CLOSED') }
  scope :urgent, -> { where(is_urgent: true) }
  scope :overdue, -> { where('response_deadline < ? AND status NOT IN (?)', Date.current, ['CLOSED', 'CANCELLED']) }
  scope :recent, -> { order(rfq_date: :desc) }
  scope :by_number, -> { order(rfq_number: :desc) }
  
  scope :converted, -> { where(converted_to_po: true) }
  scope :not_converted, -> { where(converted_to_po: false) }
  scope :ready_for_conversion, -> { 
    awarded.not_converted.where.not(awarded_supplier_id: nil) 
  }

  # ============================================================================
  # SERIALIZATION
  # ============================================================================
  store_accessor :scoring_weights, :price_weight, :delivery_weight, :quality_weight, :service_weight


  # ============================================================================
  # CLASS METHODS
  # ============================================================================


  def self.generate_next_number
    this_year_rfqs = Rfq.where(
      "created_at >= ? AND created_at < ?",
      Time.current.beginning_of_year,
      Time.current.beginning_of_year.next_year
    )
    "RFQ-#{Date.current.strftime('%Y')}-#{(this_year_rfqs.count+1).to_s.rjust(5, '0')}"
  end
  
  def self.statuses
    %w[DRAFT SENT RESPONSES_RECEIVED UNDER_REVIEW AWARDED CLOSED CANCELLED]
  end
  
  def self.comparison_bases
    %w[PRICE_ONLY DELIVERY_WEIGHTED QUALITY_WEIGHTED BALANCED]
  end
  
  # ============================================================================
  # DISPLAY METHODS
  # ============================================================================
  def display_name
    "#{rfq_number} - #{title}"
  end
  
  def to_s
    display_name
  end
  
  def status_badge_class
    case status
    when 'DRAFT' then 'secondary'
    when 'SENT' then 'primary'
    when 'RESPONSES_RECEIVED' then 'info'
    when 'UNDER_REVIEW' then 'warning'
    when 'AWARDED' then 'success'
    when 'CLOSED' then 'dark'
    when 'CANCELLED' then 'danger'
    else 'secondary'
    end
  end
  
  # ============================================================================
  # STATUS WORKFLOW METHODS
  # ============================================================================
  def can_convert_to_po?
    return false unless status == 'AWARDED'
    return false if converted_to_po?
    return false unless awarded_supplier_id.present?
    return false unless selected_items.any?
    
    true
  end

  def can_compare_quotes?
    ['RESPONSES_RECEIVED', 'UNDER_REVIEW', 'AWARDED', 'CLOSED'].include?(status)
  end
  
  def can_cancel_rfq?
    case status
    when 'DRAFT', 'SENT', 'RESPONSES_RECEIVED', 'UNDER_REVIEW'
      true  # Can cancel anytime before award
      
    when 'AWARDED'
      # Check if any POs have been created
      purchase_orders = PurchaseOrder.where(rfq_id: id)
      
      if purchase_orders.none?
        true  # Awarded but no POs yet - can cancel
      elsif purchase_orders.all? { |po| po.status == 'DRAFT' }
        true  # All POs still in draft - can cancel (will delete draft POs)
      else
        false  # POs confirmed/received - cannot cancel
      end
      
    when 'CLOSED', 'CANCELLED'
      false  # Already closed/cancelled
    end
  end

  def selected_items
    rfq_items.where.not(selected_supplier_id: nil)
  end

  def items_by_supplier
    selected_items
      .includes(:product, :vendor_quotes, :selected_supplier)
      .group_by(&:selected_supplier_id)
  end

  def convert_to_purchase_orders!(user:, warehouse_id:, **options)
    raise "Cannot convert - RFQ is not ready" unless can_convert_to_po?
    
    created_pos = []
    po_numbers = []
    
    ActiveRecord::Base.transaction do
      # Group items by supplier
      items_by_supplier.each do |supplier_id, items|
        supplier = Supplier.find(supplier_id)
        
        # Create PO for this supplier
        po = create_po_for_supplier(
          supplier: supplier,
          items: items,
          warehouse_id: warehouse_id,
          user: user,
          options: options
        )
        
        if po.persisted?
          created_pos << po
          po_numbers << po.po_number
          
          # Mark items as converted
          items.each do |item|
            item.update_column(:converted_to_po, true) if item.respond_to?(:converted_to_po)
          end
        else
          raise "Failed to create PO for #{supplier.name}: #{po.errors.full_messages.join(', ')}"
        end
      end
      
      # Update RFQ conversion tracking
      update!(
        converted_to_po: true,
        po_numbers: po_numbers.join(', '),
        po_created_date: Date.current,
        conversion_date: Date.current,
        converted_by: user
      )
    end
    
    created_pos
  rescue => e
    Rails.logger.error "RFQ to PO conversion failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise ActiveRecord::Rollback
    []
  end

  def winning_quote_for_item(rfq_item)
    vendor_quotes
      .where(rfq_item_id: rfq_item.id)
      .where(is_selected: true)
      .first
  end

  def send_to_suppliers!(user = nil)
    # Validation
    raise "Cannot send RFQ without items" if rfq_items.empty?
    raise "Cannot send RFQ without suppliers" if rfq_suppliers.empty?
    raise "Cannot send RFQ that is not in DRAFT status" unless draft?
    
    # Update status
    self.status = 'SENT'
    self.sent_at = Time.current
    self.requester = user
    
    # Mark all suppliers as invited
    rfq_suppliers.each do |rfq_supplier|
      rfq_supplier.update!(
        invitation_status: 'INVITED',
        invited_at: Time.current,
        invited_by: user
      )
      
      # Send email notification if auto_email_enabled
      if auto_email_enabled?
        begin
          supplier = rfq_supplier.supplier
          contact = rfq_supplier.supplier_contact || supplier.primary_contact
          
          if contact && contact.email.present?
            # Send email asynchronously
            RfqMailer.rfq_notification(self, supplier, contact).deliver_now
            
            # Update email tracking
            rfq_supplier.update!(
              email_sent_at: Time.current,
              contact_email_used: contact.email
            )
            
            Rails.logger.info "RFQ #{rfq_number}: Email sent to #{supplier.display_name} (#{contact.email})"
          else
            Rails.logger.warn "RFQ #{rfq_number}: No email for supplier #{supplier.display_name}"
          end
        rescue => e
          Rails.logger.error "RFQ #{rfq_number}: Failed to send email to #{supplier.display_name}: #{e.message}"
          # Don't raise - continue with other suppliers
        end
      end
    end
    
    save!
    
    Rails.logger.info "RFQ #{rfq_number} sent to #{rfq_suppliers.count} suppliers"
    true
  end

  def send_reminders!(user = nil)
    return unless sent?
    
    # Find suppliers who haven't responded yet
    non_responding_suppliers = rfq_suppliers.where(invitation_status: ['INVITED', 'VIEWED'])
    
    non_responding_suppliers.each do |rfq_supplier|
      supplier = rfq_supplier.supplier
      contact = rfq_supplier.supplier_contact || supplier.primary_contact
      
      if contact && contact.email.present?
        begin
          RfqMailer.rfq_reminder(self, supplier, contact).deliver_now
          
          # Track reminder
          self.increment!(:reminder_count)
          self.update!(last_reminder_sent_at: Time.current)
          
          Rails.logger.info "RFQ #{rfq_number}: Reminder sent to #{supplier.display_name}"
        rescue => e
          Rails.logger.error "RFQ #{rfq_number}: Failed to send reminder to #{supplier.display_name}: #{e.message}"
        end
      end
    end
    
    true
  end
  
  def mark_response_received!(updated_by_user)
    update!(
      status: 'RESPONSES_RECEIVED',
      updated_by: updated_by_user
    ) if sent? && quotes_received_count > 0
  end
  
  def mark_under_review!(updated_by_user)
    update!(
      status: 'UNDER_REVIEW',
      updated_by: updated_by_user
    )
  end
  
  def award_to_supplier!(supplier, awarded_by_user, reason: nil)
    transaction do
      update!(
        status: 'AWARDED',
        awarded_supplier: supplier,
        award_date: Date.current,
        award_reason: reason,
        updated_by: awarded_by_user
      )
      
      # Mark supplier as selected
      rfq_suppliers.find_by(supplier: supplier)&.update!(is_selected: true, selected_date: Date.current)
      
      # ✅ FIRST: Mark all quotes from this supplier as selected
      vendor_quotes.where(supplier: supplier).update_all(is_selected: true)
      
      # ✅ Mark quotes from other suppliers as NOT selected
      vendor_quotes.where.not(supplier: supplier).update_all(is_selected: false)

      # ✅ UPDATE INDIVIDUAL RFQ ITEMS WITH SELECTED SUPPLIER
      # Find all winning quotes for this supplier
      winning_quotes = vendor_quotes.where(supplier: supplier, is_selected: true)
      
      winning_quotes.each do |quote|
        rfq_item = quote.rfq_item
        
        # Update the RFQ item with selected supplier and pricing
        rfq_item.update!(
          selected_supplier_id: supplier.id,
          selected_unit_price: quote.unit_price,
          selected_total_price: quote.unit_price * rfq_item.quantity_requested,
          awarded_at: Time.current
        )
      end

      # Calculate awarded amount
      calculate_awarded_amount!
    end
  end
  
  def close!(closed_by_user, reason: nil)
    update!(
      status: 'CLOSED',
      closed_at: Time.current,
      internal_notes: [internal_notes, "Closed: #{reason}"].compact.join("\n"),
      updated_by: closed_by_user
    )
  end
  
  def cancel!(cancelled_by_user, reason: nil)
    update!(
      status: 'CANCELLED',
      internal_notes: [internal_notes, "Cancelled: #{reason}"].compact.join("\n"),
      updated_by: cancelled_by_user
    )
  end
  
  def draft?
    status == 'DRAFT'
  end
  
  def sent?
    status == 'SENT'
  end
  
  def can_be_sent?
    draft? && rfq_items.any? && rfq_suppliers.any?
  end
  
  def can_be_awarded?
    ['RESPONSES_RECEIVED', 'UNDER_REVIEW'].include?(status) && vendor_quotes.any?
  end
  
  # ============================================================================
  # SUPPLIER INVITATION METHODS
  # ============================================================================
  def invite_supplier!(supplier, invited_by_user, contact: nil)
    rfq_suppliers.create!(
      supplier: supplier,
      invited_by: invited_by_user,
      invited_at: Time.current,
      supplier_contact: contact || supplier.primary_contact,
      contact_email_used: (contact || supplier.primary_contact)&.email
    )
    
    increment!(:suppliers_invited_count)
  end
  
  def invite_multiple_suppliers!(supplier_ids, invited_by_user)
    supplier_ids.each do |supplier_id|
      supplier = Supplier.find(supplier_id)
      invite_supplier!(supplier, invited_by_user) unless rfq_suppliers.exists?(supplier_id: supplier_id)
    end
  end
  
  def remove_supplier!(supplier)
    rfq_suppliers.find_by(supplier: supplier)&.destroy
    decrement!(:suppliers_invited_count)
  end
  
  # ============================================================================
  # QUOTE MANAGEMENT METHODS
  # ============================================================================
  def record_quote_received!(rfq_supplier)
    increment!(:quotes_received_count)
    decrement!(:quotes_pending_count) if quotes_pending_count > 0
    
    rfq_supplier.update!(
      invitation_status: 'QUOTED',
      quoted_at: Time.current,
      response_time_hours: ((Time.current - rfq_supplier.invited_at) / 1.hour).to_i
    )
    
    mark_response_received!(updated_by) if quotes_received_count == suppliers_invited_count
  end
  
  def all_responses_received?
    quotes_received_count == suppliers_invited_count
  end
  
  def response_rate
    return 0 if suppliers_invited_count.zero?
    (quotes_received_count.to_f / suppliers_invited_count * 100).round(2)
  end
  
  # ============================================================================
  # COMPARISON & ANALYSIS METHODS
  # ============================================================================
  def calculate_quote_statistics!
    return if vendor_quotes.empty?
    
    amounts = vendor_quotes.group(:supplier_id).sum(:total_price).values
    
    update_columns(
      lowest_quote_amount: amounts.min,
      highest_quote_amount: amounts.max,
      average_quote_amount: (amounts.sum / amounts.size.to_f).round(2)
    )
  end
  
  def calculate_cost_savings!
    return unless awarded_total_amount && highest_quote_amount
    
    savings = highest_quote_amount - awarded_total_amount
    percentage = (savings / highest_quote_amount * 100).round(2)
    
    update_columns(
      cost_savings: savings,
      cost_savings_percentage: percentage
    )
  end
  
  # ============================================================================
  # SCORING & RECOMMENDATION ALGORITHM
  # ============================================================================
  def calculate_recommendations!
    return if vendor_quotes.empty?
    
    # Calculate scores for each quote
    vendor_quotes.includes(:supplier).find_each do |quote|
      quote.calculate_scores!(self)
    end
    
    # Find best overall score
    best_quote = vendor_quotes.order(overall_score: :desc).first
    
    if best_quote
      update!(
        recommended_supplier: best_quote.supplier,
        recommended_supplier_score: best_quote.overall_score
      )
      
      best_quote.update!(is_recommended: true)
    end
  end
  
  def weights
    {
      price: (price_weight || 40).to_f,
      delivery: (delivery_weight || 20).to_f,
      quality: (quality_weight || 25).to_f,
      service: (service_weight || 15).to_f
    }
  end
  
  def set_weights(price:, delivery:, quality:, service:)
    total = price + delivery + quality + service
    raise ArgumentError, "Weights must sum to 100" unless total == 100
    
    update!(
      scoring_weights: {
        price_weight: price,
        delivery_weight: delivery,
        quality_weight: quality,
        service_weight: service
      }
    )
  end
  
  # ============================================================================
  # COMPARISON VIEW
  # ============================================================================
  def comparison_matrix
    # Returns structured data for comparison dashboard
    items = rfq_items.includes(:product, vendor_quotes: :supplier).order(:line_number)
    
    items.map do |item|
      {
        item: item,
        quotes: item.vendor_quotes.includes(:supplier).order(:overall_rank).map do |quote|
          {
            supplier: quote.supplier,
            unit_price: quote.unit_price,
            total_price: quote.total_price,
            lead_time: quote.lead_time_days,
            total_cost: quote.total_cost,
            overall_score: quote.overall_score,
            is_lowest_price: quote.is_lowest_price,
            is_fastest_delivery: quote.is_fastest_delivery,
            is_best_value: quote.is_best_value,
            is_recommended: quote.is_recommended
          }
        end
      }
    end
  end
  
  # ============================================================================
  # ANALYTICS & REPORTING
  # ============================================================================
  def days_open
    if closed_at
      (closed_at.to_date - rfq_date).to_i
    else
      (Date.current - rfq_date).to_i
    end
  end
  
  def days_until_deadline
    (response_deadline - Date.current).to_i
  end
  
  def is_overdue?
    response_deadline < Date.current && !['CLOSED', 'CANCELLED'].include?(status)
  end
  
  def completion_percentage
    return 100 if closed? || awarded?
    return 0 if draft?
    
    steps = {
      'SENT' => 25,
      'RESPONSES_RECEIVED' => 50,
      'UNDER_REVIEW' => 75
    }
    
    steps[status] || 0
  end
  
  # ============================================================================
  # CONVERSION TO PO
  # ============================================================================
  def convert_to_purchase_order!(converted_by_user)
    # Will implement when PO module exists
    # Creates PO from awarded quotes
    transaction do
      # po = PurchaseOrder.create_from_rfq!(self, converted_by_user)
      update!(
        converted_to_po: true,
        po_created_date: Date.current
        # purchase_order: po
      )
      # po
    end
  end
  
  # ============================================================================
  # SOFT DELETE
  # ============================================================================
  def soft_delete!(deleted_by_user)
    update!(
      is_deleted: true,
      deleted_at: Time.current,
      deleted_by: deleted_by_user
    )
  end
  
  private
  
  # ============================================================================
  # PRIVATE CALLBACK METHODS
  # ============================================================================
  def calculate_expected_delivery_date(supplier, items)
    # Use the latest required delivery date from items
    latest_required = items.map(&:required_delivery_date).compact.max
    
    # Use supplier lead time
    lead_time_days = supplier.lead_time_days || 14
    supplier_expected = Date.current + lead_time_days.days
    
    # Return the later of the two
    [latest_required, supplier_expected].compact.max || (Date.current + 14.days)
  end

  def build_line_note(rfq_item, vendor_quote)
    notes = []
    
    if rfq_item.buyer_notes.present?
      notes << "RFQ Notes: #{rfq_item.buyer_notes}"
    end
    
    if vendor_quote.present?
      notes << "Lead Time: #{vendor_quote.lead_time_days} days" if vendor_quote.lead_time_days
      notes << "Payment Terms: #{vendor_quote.payment_terms}" if vendor_quote.payment_terms.present?
      
      if vendor_quote.delivery_notes.present?
        notes << "Delivery Notes: #{vendor_quote.delivery_notes}"
      end
      
      # Add certifications info
      if vendor_quote.certifications_included? && vendor_quote.certifications_list.present?
        notes << "Certifications: #{vendor_quote.certifications_list}"
      end
    end
    
    notes.join("\n")
  end

  def build_po_notes(additional_notes = nil)
    notes = []
    notes << "Generated from RFQ: #{rfq_number}"
    notes << "RFQ Description: #{description}" if description.present?
    notes << "Delivery Terms: #{delivery_terms}" if delivery_terms.present?
    notes << "Incoterms: #{incoterms}" if incoterms.present?
    notes << "Quality Requirements: #{quality_requirements}" if quality_requirements.present?
    notes << additional_notes if additional_notes.present?
    
    notes.join("\n\n")
  end

  def create_po_for_supplier(supplier:, items:, warehouse_id:, user:, options:)
    # Calculate expected date
    expected_date = options[:expected_date] || calculate_expected_delivery_date(supplier, items)
    
    # Determine payment terms (from options, supplier, or RFQ)
    payment_terms = options[:payment_terms] || 
                   supplier.payment_terms || 
                   self.payment_terms
    
    # Build PO notes
    po_notes = build_po_notes(options[:notes])
    
    # Create the PO
    po = PurchaseOrder.new(
      rfq: self,
      supplier: supplier,
      warehouse_id: warehouse_id,
      order_date: Date.current,
      expected_date: expected_date,
      payment_terms: payment_terms,
      currency: supplier.currency || 'USD',
      notes: po_notes,
      internal_notes: "Auto-generated from RFQ #{rfq_number}",
      created_by: user,
      status: 'DRAFT'
    )
    
    # Add line items
    items.each_with_index do |rfq_item, index|
      winning_quote = winning_quote_for_item(rfq_item)
      
      po.lines.build(
        rfq_item: rfq_item,
        vendor_quote: winning_quote,
        product_id: rfq_item.product_id,
        ordered_qty: rfq_item.quantity_requested,
        unit_price: rfq_item.selected_unit_price || winning_quote&.unit_price || 0,
        uom_id: rfq_item.product.unit_of_measure_id,
        expected_delivery_date: rfq_item.required_delivery_date || expected_date,
        line_note: build_line_note(rfq_item, winning_quote),
        line_status: 'OPEN'
      )
    end
    
    # Calculate totals
    po.recalculate_totals
    
    # Save PO
    po.save
    po
  end

  def set_items_line_numbers
    self.rfq_items.each_with_index do |item, i|
      item.line_number = (i+1)*10
    end
  end

  def set_supplier_invited_date_stamps
    self.rfq_suppliers.each do |rs| 
      rs.invited_at = DateTime.now
    end
    self.suppliers_invited_count = self.rfq_suppliers.length
  end  

  def generate_rfq_number
    self.rfq_number ||= self.class.generate_next_number
  end
  
  def set_defaults
    self.rfq_date ||= Date.current
    self.due_date ||= 14.days.from_now.to_date
    self.response_deadline ||= due_date
    self.status ||= 'DRAFT'
    self.priority ||= 'NORMAL'
  end
  
  def initialize_scoring_weights
    return if scoring_weights.present?
    
    self.scoring_weights = {
      price_weight: 40,
      delivery_weight: 20,
      quality_weight: 25,
      service_weight: 15
    }
    save if persisted?
  end
  
  def calculate_totals
    self.total_items_count = rfq_items.count
    self.total_quantity_requested = rfq_items.sum(:quantity_requested)
  end
  
  def update_supplier_counts
    self.suppliers_invited_count = rfq_suppliers.count
    self.quotes_pending_count = suppliers_invited_count - quotes_received_count
  end
  
  def calculate_awarded_amount!
    if awarded_supplier
      awarded_amount = vendor_quotes.where(supplier: awarded_supplier, is_selected: true).sum(:total_price)
      update_column(:awarded_total_amount, awarded_amount)
      calculate_cost_savings!
    end
  end
  
  def due_date_after_rfq_date
    return if rfq_date.blank? || due_date.blank?
    errors.add(:due_date, "must be after RFQ date") if due_date < rfq_date
  end
  
  def response_deadline_valid
    return if response_deadline.blank?
    errors.add(:response_deadline, "cannot be in the past") if response_deadline < Date.current && new_record?
  end
end
