class CreateVendorQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :vendor_quotes do |t|
      # ============================================================================
      # FOREIGN KEYS
      # ============================================================================
      t.references :rfq, null: false, foreign_key: true, index: true
      t.references :rfq_item, null: false, foreign_key: true, index: true
      t.references :supplier, null: false, foreign_key: true, index: true
      t.references :rfq_supplier, null: false, foreign_key: true # Link to invitation
      
      # ============================================================================
      # QUOTE DETAILS
      # ============================================================================
      t.string :quote_number # Supplier's quote reference number
      t.integer :quote_revision, default: 1
      t.date :quote_date, null: false
      t.date :quote_valid_until
      t.integer :validity_days # How many days quote is valid
      
      # ============================================================================
      # PRICING
      # ============================================================================
      t.decimal :unit_price, precision: 15, scale: 4, null: false
      t.decimal :total_price, precision: 15, scale: 2, null: false
      t.string :currency, default: 'USD'
      
      # Quantity Breaks (Volume Discounts)
      t.decimal :price_break_1_qty, precision: 15, scale: 2
      t.decimal :price_break_1_price, precision: 15, scale: 4
      t.decimal :price_break_2_qty, precision: 15, scale: 2
      t.decimal :price_break_2_price, precision: 15, scale: 4
      t.decimal :price_break_3_qty, precision: 15, scale: 2
      t.decimal :price_break_3_price, precision: 15, scale: 4
      
      # Additional Costs
      t.decimal :tooling_cost, precision: 15, scale: 2, default: 0
      t.decimal :setup_cost, precision: 15, scale: 2, default: 0
      t.decimal :shipping_cost, precision: 15, scale: 2, default: 0
      t.decimal :other_charges, precision: 15, scale: 2, default: 0
      t.text :other_charges_description
      t.decimal :total_cost, precision: 15, scale: 2 # Including all charges
      
      # ============================================================================
      # DELIVERY
      # ============================================================================
      t.integer :lead_time_days, null: false
      t.date :promised_delivery_date
      t.boolean :can_meet_required_date, default: true
      t.integer :days_after_required_date # If can't meet, how many days late
      t.boolean :partial_delivery_offered, default: false
      t.text :delivery_notes
      
      # ============================================================================
      # ORDER PARAMETERS
      # ============================================================================
      t.integer :minimum_order_quantity
      t.integer :order_multiple
      t.string :packaging_type
      t.integer :units_per_package
      
      # ============================================================================
      # TERMS & CONDITIONS
      # ============================================================================
      t.string :payment_terms # What supplier is offering
      t.text :payment_terms_details
      t.string :warranty_period
      t.text :warranty_details
      t.text :special_conditions
      t.text :exclusions
      
      # ============================================================================
      # QUALITY & COMPLIANCE
      # ============================================================================
      t.boolean :meets_specifications, default: true
      t.text :specification_deviations
      t.boolean :certifications_included, default: false
      t.text :certifications_list
      t.boolean :samples_available, default: false
      t.integer :sample_lead_time_days
      t.decimal :sample_cost, precision: 15, scale: 2
      
      # ============================================================================
      # COMPARISON METRICS (Auto-calculated)
      # ============================================================================
      t.decimal :price_rank, precision: 5, scale: 2 # 1 = lowest price
      t.decimal :delivery_rank, precision: 5, scale: 2 # 1 = fastest delivery
      t.decimal :total_cost_rank, precision: 5, scale: 2 # 1 = lowest total cost
      
      # Price comparison
      t.decimal :price_vs_lowest_percentage, precision: 5, scale: 2 # % higher than lowest
      t.decimal :price_vs_average_percentage, precision: 5, scale: 2
      t.decimal :price_vs_target_percentage, precision: 5, scale: 2
      t.decimal :price_vs_last_purchase_percentage, precision: 5, scale: 2
      
      # ============================================================================
      # SCORING (For automatic vendor selection)
      # ============================================================================
      t.decimal :price_score, precision: 5, scale: 2, default: 0 # 0-100
      t.decimal :delivery_score, precision: 5, scale: 2, default: 0 # 0-100
      t.decimal :quality_score, precision: 5, scale: 2, default: 0 # From supplier rating
      t.decimal :service_score, precision: 5, scale: 2, default: 0 # From supplier rating
      t.decimal :overall_score, precision: 5, scale: 2, default: 0 # Weighted total
      t.integer :overall_rank # 1 = best overall score
      
      # ============================================================================
      # HIGHLIGHTS (For visual comparison)
      # ============================================================================
      t.boolean :is_lowest_price, default: false
      t.boolean :is_fastest_delivery, default: false
      t.boolean :is_best_value, default: false # Best overall score
      t.boolean :is_recommended, default: false # Algorithm recommendation
      
      # ============================================================================
      # SELECTION
      # ============================================================================
      t.boolean :is_selected, default: false
      t.date :selected_date
      t.references :selected_by, foreign_key: { to_table: :users }
      t.text :selection_reason
      
      # ============================================================================
      # ALTERNATE/SUBSTITUTE
      # ============================================================================
      t.boolean :is_alternate_offered, default: false
      t.text :alternate_description
      t.decimal :alternate_unit_price, precision: 15, scale: 4
      t.text :alternate_notes
      
      # ============================================================================
      # ATTACHMENTS & DOCUMENTS
      # ============================================================================
      # Will use ActiveStorage for: quote PDFs, data sheets, certs, etc.
      t.text :attachments_description
      
      # ============================================================================
      # STATUS
      # ============================================================================
      t.string :quote_status, default: 'SUBMITTED' # SUBMITTED, UNDER_REVIEW, ACCEPTED, REJECTED, EXPIRED
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.text :review_notes
      
      # ============================================================================
      # REVISION TRACKING
      # ============================================================================
      t.references :superseded_by, foreign_key: { to_table: :vendor_quotes }
      t.boolean :is_latest_revision, default: true
      t.text :revision_notes
      
      # ============================================================================
      # NOTES
      # ============================================================================
      t.text :supplier_notes # Notes from supplier
      t.text :buyer_notes # Internal notes
      t.text :technical_notes
      
      # ============================================================================
      # AUDIT
      # ============================================================================
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :vendor_quotes, [:rfq_id, :rfq_item_id, :supplier_id]
    add_index :vendor_quotes, :quote_date
    add_index :vendor_quotes, :quote_valid_until
    add_index :vendor_quotes, :is_selected
    add_index :vendor_quotes, :is_lowest_price
    add_index :vendor_quotes, :is_fastest_delivery
    add_index :vendor_quotes, :is_best_value
    add_index :vendor_quotes, :overall_rank
    add_index :vendor_quotes, :quote_status
    add_index :vendor_quotes, :is_latest_revision
  end
end
