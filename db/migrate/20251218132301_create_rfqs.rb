# frozen_string_literal: true

class CreateRfqs < ActiveRecord::Migration[8.1]
  def change
    create_table :rfqs do |t|
      # ============================================================================
      # BASIC INFORMATION
      # ============================================================================
      t.string :rfq_number, null: false, index: { unique: true }
      t.string :title, null: false
      t.text :description
      t.date :rfq_date, null: false
      t.date :due_date, null: false
      t.date :required_delivery_date
      
      # ============================================================================
      # STATUS & WORKFLOW
      # ============================================================================
      t.string :status, default: 'DRAFT', null: false # DRAFT, SENT, RESPONSES_RECEIVED, UNDER_REVIEW, AWARDED, CLOSED, CANCELLED
      t.datetime :sent_at
      t.datetime :closed_at
      t.date :response_deadline
      t.boolean :is_urgent, default: false
      t.string :priority, default: 'NORMAL' # LOW, NORMAL, HIGH, URGENT
      
      # ============================================================================
      # TERMS & CONDITIONS
      # ============================================================================
      t.text :terms_and_conditions
      t.text :payment_terms # Requested payment terms
      t.text :delivery_terms # Delivery requirements/terms
      t.text :quality_requirements
      t.text :special_instructions
      t.string :incoterms # FOB, CIF, EXW, etc.
      
      # ============================================================================
      # VENDOR MANAGEMENT
      # ============================================================================
      t.integer :suppliers_invited_count, default: 0
      t.integer :quotes_received_count, default: 0
      t.integer :quotes_pending_count, default: 0
      
      # ============================================================================
      # SELECTION & AWARD
      # ============================================================================
      t.references :awarded_supplier, foreign_key: { to_table: :suppliers }
      t.date :award_date
      t.text :award_reason
      t.decimal :awarded_total_amount, precision: 15, scale: 2
      
      # ============================================================================
      # FINANCIAL TRACKING
      # ============================================================================
      t.decimal :estimated_budget, precision: 15, scale: 2
      t.decimal :lowest_quote_amount, precision: 15, scale: 2
      t.decimal :highest_quote_amount, precision: 15, scale: 2
      t.decimal :average_quote_amount, precision: 15, scale: 2
      t.decimal :selected_quote_amount, precision: 15, scale: 2
      t.decimal :cost_savings, precision: 15, scale: 2 # vs budget or highest quote
      t.decimal :cost_savings_percentage, precision: 5, scale: 2
      
      # ============================================================================
      # COMPARISON & ANALYSIS
      # ============================================================================
      t.string :comparison_basis # PRICE_ONLY, DELIVERY_WEIGHTED, QUALITY_WEIGHTED, BALANCED
      t.jsonb :scoring_weights # Configurable weights for automatic scoring
      # Default: { price: 40, delivery: 20, quality: 25, service: 15 }
      t.references :recommended_supplier, foreign_key: { to_table: :suppliers }
      t.decimal :recommended_supplier_score, precision: 5, scale: 2
      
      # ============================================================================
      # EMAIL & NOTIFICATIONS
      # ============================================================================
      t.boolean :auto_email_enabled, default: true
      t.datetime :last_reminder_sent_at
      t.integer :reminder_count, default: 0
      t.boolean :send_to_all_contacts, default: false # Send to all contacts or just primary
      
      # ============================================================================
      # CONVERSION TO PO
      # ============================================================================
      # t.references :purchase_order, foreign_key: true # Will add when PO module exists
      t.boolean :converted_to_po, default: false
      t.date :po_created_date
      
      # ============================================================================
      # ATTACHMENTS & DOCUMENTS
      # ============================================================================
      # Will use ActiveStorage for: drawings, specifications, terms docs, etc.
      t.text :attachments_description # Brief description of attached files
      t.boolean :requires_technical_drawings, default: false
      t.boolean :requires_certifications, default: false
      t.boolean :requires_samples, default: false
      
      # ============================================================================
      # COLLABORATION
      # ============================================================================
      t.references :created_by, foreign_key: { to_table: :users }, null: false
      t.references :requester, foreign_key: { to_table: :users } # Who requested the RFQ
      t.references :buyer_assigned, foreign_key: { to_table: :users } # Buyer handling this RFQ
      t.references :approver, foreign_key: { to_table: :users } # Who needs to approve
      t.datetime :approved_at
      t.text :approval_notes
      
      # ============================================================================
      # RESPONSE TRACKING
      # ============================================================================
      t.integer :days_to_first_response
      t.integer :days_to_all_responses
      t.decimal :response_rate_percentage, precision: 5, scale: 2
      t.date :all_responses_received_date
      
      # ============================================================================
      # ANALYTICS
      # ============================================================================
      t.integer :total_items_count, default: 0
      t.decimal :total_quantity_requested, precision: 15, scale: 2, default: 0
      t.integer :comparison_views_count, default: 0 # How many times comparison was viewed
      t.datetime :last_compared_at
      
      # ============================================================================
      # INTERNAL NOTES
      # ============================================================================
      t.text :internal_notes
      t.text :buyer_notes
      t.text :evaluation_notes
      
      # ============================================================================
      # AUDIT & SOFT DELETE
      # ============================================================================
      t.boolean :is_deleted, default: false
      t.datetime :deleted_at
      t.references :deleted_by, foreign_key: { to_table: :users }
      
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    
    # ============================================================================
    # INDEXES
    # ============================================================================
    add_index :rfqs, :rfq_date
    add_index :rfqs, :due_date
    add_index :rfqs, :status
    add_index :rfqs, :is_urgent
    add_index :rfqs, :response_deadline
    add_index :rfqs, :is_deleted
    add_index :rfqs, [:status, :is_deleted]
    add_index :rfqs, :created_at
  end
end