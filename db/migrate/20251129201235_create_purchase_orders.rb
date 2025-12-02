# Generate this migration:
# rails g migration CreatePurchaseOrders
# Then replace content with below:

class CreatePurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    # ===================================
    # PURCHASE ORDER HEADER
    # ===================================
    create_table :purchase_orders do |t|
      # PO Number (unique identifier)
      t.string :po_number, null: false, limit: 50
      
      # Supplier reference
      t.references :supplier, null: false, foreign_key: true
      
      # Warehouse for receiving (optional - can be on line level too)
      t.references :warehouse, foreign_key: true, null: true
      
      # Dates
      t.date :order_date, null: false, default: -> { 'CURRENT_DATE' }
      t.date :expected_date  # Delivery date
      t.date :confirmed_at
      t.date :closed_at
      
      # Status workflow
      t.string :status, default: 'DRAFT', null: false, limit: 30
      # DRAFT → CONFIRMED → PARTIALLY_RECEIVED → RECEIVED → CLOSED
      # Can also be CANCELLED
      
      # Currency (US/Canada focus)
      t.string :currency, default: 'USD', null: false, limit: 3
      
      # Totals (computed from lines)
      t.decimal :subtotal, precision: 15, scale: 2, default: 0.0
      t.decimal :tax_amount, precision: 15, scale: 2, default: 0.0
      t.decimal :total_amount, precision: 15, scale: 2, default: 0.0
      
      # Payment terms
      t.string :payment_terms, limit: 50
      # e.g., "NET_30", "NET_45", "DUE_ON_RECEIPT"
      
      # Shipping
      t.string :shipping_method, limit: 100
      t.text :shipping_address
      t.decimal :shipping_cost, precision: 15, scale: 2, default: 0.0
      
      # Notes
      t.text :notes
      t.text :internal_notes
      
      # User tracking
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :confirmed_by, foreign_key: { to_table: :users }, null: true
      t.references :closed_by, foreign_key: { to_table: :users }, null: true
      
      # Soft delete
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :purchase_orders, :po_number, unique: true
    add_index :purchase_orders, :status
    add_index :purchase_orders, [:supplier_id, :status]
    add_index :purchase_orders, :order_date
    add_index :purchase_orders, :expected_date
    
    
    # ===================================
    # PURCHASE ORDER LINE
    # ===================================
    create_table :purchase_order_lines do |t|
      # Parent PO
      t.references :purchase_order, null: false, foreign_key: true
      
      # Product being ordered
      t.references :product, null: false, foreign_key: true
      
      # Unit of Measure
      t.references :uom, null: false, foreign_key: { to_table: :unit_of_measures }
      
      # Quantities
      t.decimal :ordered_qty, precision: 14, scale: 4, null: false, default: 0.0
      t.decimal :received_qty, precision: 14, scale: 4, default: 0.0
      
      # Pricing
      t.decimal :unit_price, precision: 15, scale: 4, null: false, default: 0.0
      t.decimal :line_total, precision: 15, scale: 2, default: 0.0
      
      # Tax (optional line-level tax)
      t.references :tax_code, foreign_key: true, null: true
      t.decimal :tax_rate, precision: 6, scale: 4, default: 0.0
      t.decimal :tax_amount, precision: 15, scale: 2, default: 0.0
      
      # Line status
      t.string :line_status, default: 'OPEN', limit: 30
      # OPEN → PARTIALLY_RECEIVED → FULLY_RECEIVED
      
      # Expected delivery date (can override PO level)
      t.date :expected_delivery_date
      
      # Line-level notes
      t.text :line_note
      
      # Soft delete
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes
    # add_index :purchase_order_lines, [:purchase_order_id, :product_id]
    add_index :purchase_order_lines, :line_status
    # add_index :purchase_order_lines, :product_id
  end
end
