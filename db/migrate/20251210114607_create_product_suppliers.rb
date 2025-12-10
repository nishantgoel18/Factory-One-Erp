# frozen_string_literal: true

class CreateProductSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :product_suppliers do |t|
      # ============================================================================
      # FOREIGN KEYS
      # ============================================================================
      t.references :product, null: false, foreign_key: true, index: true
      t.references :supplier, null: false, foreign_key: true, index: true
      
      # ============================================================================
      # SUPPLIER'S ITEM IDENTIFICATION
      # ============================================================================
      t.string :supplier_item_code # Vendor's SKU/Part Number
      t.string :supplier_item_description
      t.string :manufacturer_part_number # If supplier is distributor
      
      # ============================================================================
      # PRICING
      # ============================================================================
      t.decimal :current_unit_price, precision: 15, scale: 4, null: false
      t.string :price_uom # Unit of Measure for pricing
      t.date :price_effective_date
      t.date :price_expiry_date
      t.decimal :previous_unit_price, precision: 15, scale: 4
      t.decimal :price_change_percentage, precision: 5, scale: 2 # +/- percentage
      t.string :price_trend # INCREASING, DECREASING, STABLE
      
      # Volume/Quantity Break Pricing
      t.decimal :price_break_1_qty, precision: 15, scale: 2
      t.decimal :price_break_1_price, precision: 15, scale: 4
      t.decimal :price_break_2_qty, precision: 15, scale: 2
      t.decimal :price_break_2_price, precision: 15, scale: 4
      t.decimal :price_break_3_qty, precision: 15, scale: 2
      t.decimal :price_break_3_price, precision: 15, scale: 4
      
      # ============================================================================
      # ORDER PARAMETERS
      # ============================================================================
      t.integer :lead_time_days, null: false # Can override supplier default
      t.integer :minimum_order_quantity, default: 1
      t.integer :maximum_order_quantity
      t.integer :order_multiple # Lot size/multiple
      t.string :packaging_type # PALLET, BOX, DRUM, ROLL, etc.
      t.integer :units_per_package
      t.boolean :available_for_order, default: true
      
      # ============================================================================
      # QUALITY & PERFORMANCE
      # ============================================================================
      t.decimal :quality_rating, precision: 5, scale: 2, default: 100 # 0-100 scale
      t.integer :quality_issues_count, default: 0
      t.date :last_quality_issue_date
      t.decimal :delivery_performance_rating, precision: 5, scale: 2, default: 100
      t.integer :late_deliveries_count, default: 0
      
      # ============================================================================
      # PURCHASE HISTORY FOR THIS PRODUCT
      # ============================================================================
      t.date :first_purchase_date
      t.date :last_purchase_date
      t.decimal :last_purchase_price, precision: 15, scale: 4
      t.decimal :last_purchase_quantity, precision: 15, scale: 2
      t.integer :total_orders_count, default: 0
      t.decimal :total_quantity_purchased, precision: 15, scale: 2, default: 0
      t.decimal :total_value_purchased, precision: 15, scale: 2, default: 0
      t.decimal :average_purchase_price, precision: 15, scale: 4
      t.integer :days_since_last_order
      
      # ============================================================================
      # STRATEGIC FLAGS
      # ============================================================================
      t.boolean :is_preferred_supplier, default: false # Preferred for THIS product
      t.integer :supplier_rank # 1 = primary, 2 = secondary, etc.
      t.boolean :is_approved_supplier, default: true
      t.boolean :is_sole_source, default: false # Only supplier for this product
      t.boolean :is_strategic_item, default: false
      t.string :sourcing_strategy # SINGLE_SOURCE, DUAL_SOURCE, MULTI_SOURCE
      
      # ============================================================================
      # TECHNICAL SPECIFICATIONS
      # ============================================================================
      t.text :technical_specifications # JSON or text
      t.text :quality_requirements
      t.text :testing_requirements
      t.boolean :requires_quality_cert, default: false
      t.boolean :requires_coc, default: false # Certificate of Compliance
      t.boolean :requires_msds, default: false # Material Safety Data Sheet
      
      # ============================================================================
      # NOTES & REFERENCES
      # ============================================================================
      t.text :buyer_notes
      t.text :quality_notes
      t.text :engineering_notes
      t.string :contract_reference
      t.date :contract_expiry_date
      
      # ============================================================================
      # STATUS
      # ============================================================================
      t.boolean :is_active, default: true
      t.date :discontinued_date
      t.string :discontinuation_reason
      t.string :replacement_product_code
      
      # ============================================================================
      # AUDIT FIELDS
      # ============================================================================
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    
    # ============================================================================
    # INDEXES
    # ============================================================================
    add_index :product_suppliers, [:product_id, :supplier_id], unique: true
    add_index :product_suppliers, :supplier_item_code
    add_index :product_suppliers, :is_preferred_supplier
    add_index :product_suppliers, :is_approved_supplier
    add_index :product_suppliers, :is_active
    add_index :product_suppliers, :quality_rating
    add_index :product_suppliers, :supplier_rank
    add_index :product_suppliers, :current_unit_price
    add_index :product_suppliers, :lead_time_days
  end
end