# frozen_string_literal: true

class CreateRfqItems < ActiveRecord::Migration[8.1]
  def change
    create_table :rfq_items do |t|
      # ============================================================================
      # FOREIGN KEYS
      # ============================================================================
      t.references :rfq, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      
      # ============================================================================
      # LINE ITEM DETAILS
      # ============================================================================
      t.integer :line_number, null: false # Sequential line number
      t.string :item_description # Can override product name
      t.decimal :quantity_requested, precision: 15, scale: 2, null: false
      t.string :unit_of_measure # UOM
      
      # ============================================================================
      # SPECIFICATIONS & REQUIREMENTS
      # ============================================================================
      t.text :technical_specifications
      t.text :quality_requirements
      t.string :material_grade # e.g., "304 Stainless Steel"
      t.string :finish_requirement # e.g., "Polished", "Powder Coated"
      t.text :dimensional_requirements
      t.string :color_specification
      t.text :packaging_requirements
      t.boolean :requires_testing, default: false
      t.string :testing_standards # e.g., "ASTM D638"
      
      # ============================================================================
      # DELIVERY REQUIREMENTS
      # ============================================================================
      t.date :required_delivery_date
      t.boolean :partial_delivery_acceptable, default: false
      t.string :delivery_location
      t.text :shipping_instructions
      
      # ============================================================================
      # REFERENCE INFORMATION
      # ============================================================================
      t.string :customer_part_number # If making for customer
      t.string :drawing_number
      t.integer :drawing_revision
      t.text :reference_notes
      
      # ============================================================================
      # BUDGET & TARGET
      # ============================================================================
      t.decimal :target_unit_price, precision: 15, scale: 4 # Target/budget price
      t.decimal :target_total_price, precision: 15, scale: 2
      t.decimal :last_purchase_price, precision: 15, scale: 4 # Historical reference
      t.date :last_purchase_date
      t.references :last_purchased_from, foreign_key: { to_table: :suppliers }
      
      # ============================================================================
      # QUOTE ANALYSIS (Auto-calculated)
      # ============================================================================
      t.integer :quotes_received_count, default: 0
      t.decimal :lowest_quoted_price, precision: 15, scale: 4
      t.decimal :highest_quoted_price, precision: 15, scale: 4
      t.decimal :average_quoted_price, precision: 15, scale: 4
      t.integer :best_delivery_days # Shortest lead time quoted
      
      # Selected quote details
      t.references :selected_supplier, foreign_key: { to_table: :suppliers }
      t.decimal :selected_unit_price, precision: 15, scale: 4
      t.decimal :selected_total_price, precision: 15, scale: 2
      t.integer :selected_lead_time_days
      t.text :selection_reason
      
      # ============================================================================
      # VARIANCE ANALYSIS
      # ============================================================================
      t.decimal :price_variance_vs_target, precision: 15, scale: 2 # Selected vs target
      t.decimal :price_variance_percentage, precision: 5, scale: 2
      t.decimal :price_variance_vs_last, precision: 15, scale: 2 # Selected vs last purchase
      t.decimal :savings_vs_highest_quote, precision: 15, scale: 2
      
      # ============================================================================
      # ADDITIONAL FLAGS
      # ============================================================================
      t.boolean :is_critical_item, default: false
      t.boolean :is_long_lead_item, default: false
      t.boolean :requires_approval, default: false
      t.boolean :is_custom_fabrication, default: false
      t.string :criticality_reason
      
      # ============================================================================
      # NOTES
      # ============================================================================
      t.text :buyer_notes
      t.text :engineering_notes
      t.text :quality_notes
      
      # ============================================================================
      # AUDIT
      # ============================================================================
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    
    # ============================================================================
    # INDEXES
    # ============================================================================
    add_index :rfq_items, [:rfq_id, :line_number], unique: true
    add_index :rfq_items, :required_delivery_date
    add_index :rfq_items, :is_critical_item
  end
end